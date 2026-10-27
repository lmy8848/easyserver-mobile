#include "MainWindow.h"

#include <QApplication>
#include <QCloseEvent>
#include <QComboBox>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QSettings>
#include <QSharedPointer>
#include <QStandardPaths>
#include <QUrl>
#include <QFrame>
#include <QHBoxLayout>
#include <QKeyEvent>
#include <QLabel>
#include <QMessageBox>
#include <QProcess>
#include <QProcessEnvironment>
#include <QPushButton>
#include <QShortcut>
#include <QSplitter>
#include <QStatusBar>
#include <QHash>
#include <QInputDialog>
#include <QTimer>
#include <QToolBar>
#include <QVBoxLayout>
#include <QWheelEvent>

#include "AppLog.h"
#include "Panels.h"
#include "PairDialog.h"
#include "ScrcpyProcess.h"
#include "Settings.h"
#include "SettingsDialog.h"

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    m_adb = new AdbClient(this);
    m_scrcpy = new ScrcpyProcess(this);

    buildUi();
    applyDarkTheme();

    // 应用层全局日志实时进「应用日志」面板（同时落盘到 AppData）
    if (AppLog::instance())
        connect(AppLog::instance(), &AppLog::lineWritten, m_panels, &Panels::appendAppLog);

    connect(m_adb, &AdbClient::devicesChanged, this, &MainWindow::onDevicesChanged);
    connect(m_adb, &AdbClient::errorOccurred, this, [this](const QString &e) {
        m_status->setText(e);
        m_panels->appendShell(QStringLiteral("[adb] ") + e);
    });
    connect(m_adb, &AdbClient::commandOutput, this, [this](const QString &out) {
        m_panels->appendShell(out);
    });

    connect(m_scrcpy, &ScrcpyProcess::runningChanged, this, [this](bool running) {
        m_connectBtn->setEnabled(!running);
        m_disconnectBtn->setEnabled(running);
        m_status->setText(running ? QStringLiteral("镜像运行中") : QStringLiteral("镜像已停止"));
        if (running)
            m_mirrorHost->setFocus(Qt::OtherFocusReason);
    });
    connect(m_scrcpy, &ScrcpyProcess::statusText, this, [this](const QString &t) {
        m_status->setText(t);
        // 真正嵌入成功才算连上，此前不消耗重试预算
        if (t == QStringLiteral("镜像已嵌入"))
            m_retries = 0;
    });

    // 非主动停止（无线 adb 掉线、scrcpy 崩溃）时自动重连，次数/间隔由设置决定
    m_autoReconnect = new QTimer(this);
    m_autoReconnect->setSingleShot(true);
    m_autoReconnect->setInterval(Settings::instance().conn().reconnectDelaySec * 1000);
    connect(m_autoReconnect, &QTimer::timeout, this, [this]() {
        if (m_serial.isEmpty())
            return;
        const ConnOptions c = Settings::instance().conn();
        if (c.reconnectMax <= 0) {
            m_status->setText(QStringLiteral("镜像已断开（自动重连已关闭）"));
            return;
        }
        // 设备不在线时反复启动 scrcpy 只会白白耗掉重试预算，改为等它恢复
        if (!isSerialOnline(m_serial)) {
            m_status->setText(QStringLiteral("设备离线，等待恢复…"));
            qInfo() << "[reconnect] wait offline" << m_serial;
            m_autoReconnect->start();
            return;
        }
        if (m_retries >= c.reconnectMax) {
            m_status->setText(QStringLiteral("自动重连已暂停（%1 次失败）· 检查手机后点「连接镜像」")
                                  .arg(c.reconnectMax));
            return;
        }
        ++m_retries;
        m_status->setText(QStringLiteral("重连中…（第 %1 次）").arg(m_retries));
        qInfo() << "[reconnect] attempt" << m_retries << m_serial;
        m_adb->refreshDevices();
        m_scrcpy->start(m_serial);
    });
    connect(m_scrcpy, &ScrcpyProcess::exitedUnexpectedly, this, [this](int code) {
        if (m_serial.isEmpty())
            return;
        const ConnOptions c = Settings::instance().conn();
        if (c.reconnectMax <= 0) {
            m_panels->appendShell(
                QStringLiteral("[scrcpy] 意外退出 code=%1（自动重连已关闭）").arg(code));
            m_status->setText(QStringLiteral("镜像断开（code=%1）").arg(code));
            return;
        }
        m_panels->appendShell(QStringLiteral("[scrcpy] 意外退出 code=%1，将自动重连").arg(code));
        m_status->setText(QStringLiteral("镜像断开（code=%1），%2 秒后重连")
                              .arg(code)
                              .arg(c.reconnectDelaySec));
        m_autoReconnect->start();
    });
    connect(m_scrcpy, &ScrcpyProcess::errorOccurred, this, [this](const QString &e) {
        m_panels->appendShell(QStringLiteral("[scrcpy] ") + e);
        m_status->setText(e);
    });

    // 3s 轮询设备，兼顾无线 adb 掉线后自动恢复
    auto *poll = new QTimer(this);
    poll->setInterval(3000);
    connect(poll, &QTimer::timeout, this, &MainWindow::onRefreshClicked);
    poll->start();
    onRefreshClicked();

    // 恢复上次窗口几何：此前每次启动位置都漂移，自动化点击和多屏切换都受影响。
    // 只恢复几何，不恢复工具条状态——工具条布局是固定的（设备栏 + 按键栏两行），
    // restoreState 会把按键栏拉回同一行并盖住右侧面板。
    const QByteArray geo = Settings::instance().windowGeometry();
    if (!geo.isEmpty())
        restoreGeometry(geo);

    // 自动连上次设备：先记下来，等设备列表确认在线后再连（直接启动会撞上 adb 未就绪）
    const ConnOptions connOpt = Settings::instance().conn();
    if (connOpt.autoConnectLast && !connOpt.lastSerial.isEmpty())
        m_pendingSerial = connOpt.lastSerial;

    qInfo() << "[main] MainWindow built";
}

MainWindow::~MainWindow() {
    if (m_scrcpy)
        m_scrcpy->stop();
}

void MainWindow::closeEvent(QCloseEvent *event) {
    Settings::instance().setWindowGeometry(saveGeometry());
    if (m_recordTick->isActive()) {
        // 关闭时别把设备端 screenrecord 留成孤儿进程
        QProcess::startDetached(m_adb->adbPath(),
                                {QStringLiteral("-s"), m_recordSerial, QStringLiteral("shell"),
                                 QStringLiteral("kill -INT $(cat %1) 2>/dev/null; rm -f %2")
                                     .arg(m_recordPidFile, m_recordRemote)});
        qInfo() << "[record] cancelled on app close";
    }
    QMainWindow::closeEvent(event);
}

void MainWindow::buildUi() {
    setWindowTitle(QStringLiteral("DevBoard"));
    resize(1440, 900);

    // ---- 顶部工具条 ----
    auto *bar = addToolBar(QStringLiteral("设备"));
    bar->setObjectName(QStringLiteral("deviceBar")); // saveState/restoreState 需要
    bar->setMovable(false);
    bar->setIconSize(QSize(16, 16));

    bar->addWidget(new QLabel(QStringLiteral("设备：")));
    m_deviceBox = new QComboBox(this);
    m_deviceBox->setMinimumWidth(240);
    m_deviceBox->setSizeAdjustPolicy(QComboBox::AdjustToContents);
    bar->addWidget(m_deviceBox);

    auto *refreshBtn = new QPushButton(QStringLiteral("刷新"), this);
    connect(refreshBtn, &QPushButton::clicked, this, &MainWindow::onRefreshClicked);
    bar->addWidget(refreshBtn);

    // mDNS 在部分 Windows 环境发现不到服务（需要 Bonjour），保留手动 adb connect 入口
    auto *connectDevBtn = new QPushButton(QStringLiteral("连接设备"), this);
    connect(connectDevBtn, &QPushButton::clicked, this, [this]() {
        bool ok = false;
        const QString addr =
            QInputDialog::getText(this, QStringLiteral("连接无线设备"),
                                  QStringLiteral("adb connect 地址（手机「无线调试」页面显示的 IP:端口）"),
                                  QLineEdit::Normal, m_serial, &ok)
                .trimmed();
        if (!ok || addr.isEmpty())
            return;
        m_status->setText(QStringLiteral("正在连接 %1…").arg(addr));
        m_adb->connectDevice(addr);
    });
    bar->addWidget(connectDevBtn);

    bar->addSeparator();
    m_deviceState = new QLabel(QStringLiteral("未连接"), this);
    m_deviceState->setMinimumWidth(120);
    bar->addWidget(m_deviceState);

    bar->addSeparator();
    m_connectBtn = new QPushButton(QStringLiteral("连接镜像"), this);
    m_connectBtn->setDefault(true);
    connect(m_connectBtn, &QPushButton::clicked, this, &MainWindow::onConnectClicked);
    bar->addWidget(m_connectBtn);

    m_disconnectBtn = new QPushButton(QStringLiteral("断开"), this);
    m_disconnectBtn->setEnabled(false);
    connect(m_disconnectBtn, &QPushButton::clicked, this, &MainWindow::onDisconnectClicked);
    bar->addWidget(m_disconnectBtn);

    bar->addSeparator();
    auto *pairBtn = new QPushButton(QStringLiteral("无线配对"), this);
    connect(pairBtn, &QPushButton::clicked, this, [this]() {
        auto *dlg = new PairDialog(m_adb, this);
        connect(dlg, &PairDialog::deviceConnected, this, [this](const QString &serial) {
            if (!serial.isEmpty()) {
                m_serial = serial;
                m_status->setText(QStringLiteral("已配对并连接 %1").arg(serial));
            }
            // connect 是异步的，稍等再刷一次设备列表
            QTimer::singleShot(1500, this, [this]() { m_adb->refreshDevices(); });
        });
        dlg->exec();
        dlg->deleteLater();
    });
    bar->addWidget(pairBtn);

    bar->addSeparator();
    auto *settingsBtn = new QPushButton(QStringLiteral("设置"), this);
    settingsBtn->setToolTip(QStringLiteral("镜像参数、连接、路径与界面（Ctrl+,）"));
    connect(settingsBtn, &QPushButton::clicked, this, &MainWindow::onSettings);
    bar->addWidget(settingsBtn);

    // ---- 按键栏：镜像区被 scrcpy 子窗口占据，导航键在这里补 ----
    // 另起一行，避免和上面的设备栏挤在一起被窗口边缘裁掉
    addToolBarBreak();
    auto *keyBar = addToolBar(QStringLiteral("按键"));
    keyBar->setObjectName(QStringLiteral("keyBar"));
    keyBar->setMovable(false);
    auto addKey = [this, keyBar](const QString &label, int keycode) {
        auto *b = new QPushButton(label, this);
        b->setFixedWidth(64);
        b->setToolTip(QStringLiteral("input keyevent %1").arg(keycode));
        connect(b, &QPushButton::clicked, this, [this, keycode]() { sendKey(keycode); });
        keyBar->addWidget(b);
    };
    addKey(QStringLiteral("返回"), 4);
    addKey(QStringLiteral("主页"), 3);
    addKey(QStringLiteral("多任务"), 187);
    addKey(QStringLiteral("音量-"), 25);
    addKey(QStringLiteral("音量+"), 24);
    addKey(QStringLiteral("电源"), 26);
    auto *rotBtn = new QPushButton(QStringLiteral("旋转"), this);
    rotBtn->setFixedWidth(64);
    rotBtn->setToolTip(QStringLiteral("切换屏幕方向 0°/90°/180°/270°"));
    connect(rotBtn, &QPushButton::clicked, this, &MainWindow::rotateScreen);
    keyBar->addWidget(rotBtn);

    // ---- 中央：左镜像 + 右面板 ----
    auto *split = new QSplitter(Qt::Horizontal, this);

    m_mirrorHost = new QWidget(split);
    m_mirrorHost->setMinimumSize(360, 480);
    m_mirrorHost->setFocusPolicy(Qt::StrongFocus);
    m_mirrorHost->setAutoFillBackground(true);
    m_mirrorHost->setStyleSheet(QStringLiteral("background:#0f1116;"));
    m_mirrorHost->setLayout(new QVBoxLayout());
    m_mirrorHost->layout()->setContentsMargins(0, 0, 0, 0);
    auto *placeholder = new QLabel(QStringLiteral("选择设备后点「连接镜像」"), m_mirrorHost);
    placeholder->setAlignment(Qt::AlignCenter);
    placeholder->setStyleSheet(QStringLiteral("color:#6b7280;font-size:15px;"));
    m_mirrorHost->layout()->addWidget(placeholder);

    m_panels = new Panels(split);
    split->addWidget(m_mirrorHost);
    split->addWidget(m_panels);
    // 镜像区默认窄一些：手机竖直画面是 9:20，宽了只会多两侧黑边；
    // 多余宽度留给右侧功能面板，用户仍可拖动分隔条。
    split->setStretchFactor(0, 0);
    split->setStretchFactor(1, 1);
    split->setSizes({440, 860});
    setCentralWidget(split);

    m_scrcpy->setHost(m_mirrorHost);
    qApp->installEventFilter(this);

    // ---- 状态栏 ----
    m_status = new QLabel(QStringLiteral("就绪"), this);
    statusBar()->addWidget(m_status, 1);

    // ---- 面板信号 ----
    connect(m_panels, &Panels::shellCommandEntered, this, &MainWindow::onShellCommand);
    connect(m_panels, &Panels::refreshInfoRequested, this, &MainWindow::onRefreshInfo);
    connect(m_panels, &Panels::screenshotRequested, this, &MainWindow::onScreenshot);
    connect(m_panels, &Panels::recordRequested, this, &MainWindow::onRecord);
    connect(m_panels, &Panels::cancelRecordRequested, this, &MainWindow::onCancelRecord);
    connect(m_panels, &Panels::chooseCaptureDirRequested, this, &MainWindow::onChooseCaptureDir);
    connect(m_panels, &Panels::openCaptureDirRequested, this, &MainWindow::onOpenCaptureDir);
    connect(m_panels, &Panels::openCaptureFileRequested, this, &MainWindow::onOpenCaptureFile);
    connect(m_panels, &Panels::openLogDirRequested, this, [this]() {
        QDir().mkpath(AppLog::logDir());
        QDesktopServices::openUrl(QUrl::fromLocalFile(AppLog::logDir()));
    });

    // 截图/录屏保存目录：统一由 Settings 管理（默认 图片/DevBoard，可在设置或操作页改）
    m_captureDirPath = Settings::instance().captureDir();
    m_panels->setCaptureDir(m_captureDirPath);

    m_recordTick = new QTimer(this);
    m_recordTick->setInterval(1000);
    connect(m_recordTick, &QTimer::timeout, this, [this]() {
        ++m_recordTicks;
        if (m_recordRemain > 0)
            --m_recordRemain;
        if (m_recordStopping) {
            m_status->setText(QStringLiteral("正在停止录屏…"));
        } else if (m_recordRemain > 0) {
            m_status->setText(QStringLiteral("录制中… 剩余 %1 秒（再点「停止录屏」提前结束）")
                                  .arg(m_recordRemain));
        } else {
            m_status->setText(QStringLiteral("录制已达时长上限，正在收尾…"));
        }
        // 设备端 screenrecord 退出即录制结束（自然到点或被 SIGINT 停止）
        probeRecord();
        // 兜底：远超时长仍在跑，强制收尾，避免按钮卡在「停止录屏」
        if (m_recordTicks > m_recordSeconds + 15) {
            qWarning() << "[record] watchdog timeout, forcing stop";
            m_recordCancelled = true;
            finishRecord();
        }
    });
    connect(m_panels, &Panels::listPackagesRequested, this, [this]() {
        const QString serial = activeSerial();
        if (serial.isEmpty())
            return;
        auto *p = new QProcess(this);
        connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
                [this, p](int, QProcess::ExitStatus) {
                    const QString out = QString::fromUtf8(p->readAllStandardOutput());
                    m_panels->clearPackages();
                    int count = 0;
                    for (const QString &line : out.split(QLatin1Char('\n'))) {
                        const QString l = line.trimmed();
                        if (l.startsWith(QStringLiteral("package:"))) {
                            m_panels->appendPackage(l.mid(8));
                            ++count;
                        }
                    }
                    m_status->setText(QStringLiteral("已列出 %1 个第三方应用").arg(count));
                    p->deleteLater();
                });
        p->start(m_adb->adbPath(),
                 {QStringLiteral("-s"), serial, QStringLiteral("shell"), QStringLiteral("pm"),
                  QStringLiteral("list"), QStringLiteral("packages"), QStringLiteral("-3")});
    });
    connect(m_panels, &Panels::installApkRequested, this, [this]() {
        const QString serial = activeSerial();
        if (serial.isEmpty())
            return;
        const QString path = QFileDialog::getOpenFileName(
            this, QStringLiteral("选择 APK"), QString(), QStringLiteral("APK (*.apk)"));
        if (path.isEmpty())
            return;
        m_status->setText(QStringLiteral("安装中：%1").arg(path));
        QProcess p;
        p.start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("install"),
                                   QStringLiteral("-r"), path});
        p.waitForFinished(60000);
        m_panels->appendShell(QString::fromUtf8(p.readAllStandardOutput()));
        m_panels->appendShell(QString::fromUtf8(p.readAllStandardError()));
    });
    connect(m_panels, &Panels::logcatStartRequested, this, &MainWindow::onLogcatStart);
    connect(m_panels, &Panels::logcatStopRequested, this, &MainWindow::onLogcatStop);

    auto addShortcut = [this](const char *key, auto fn) {
        auto *sc = new QShortcut(QKeySequence(QString::fromLatin1(key)), this);
        sc->setContext(Qt::WindowShortcut);
        connect(sc, &QShortcut::activated, this, fn);
    };
    addShortcut("F5", [this]() { m_panels->setCurrentIndex(4); });
    addShortcut("F6", [this]() {
        if (m_logcat)
            onLogcatStop();
        else
            onLogcatStart();
    });
    addShortcut("F7", [this]() { m_panels->clearLog(); });
    addShortcut("F8", [this]() { m_panels->refreshInfoRequested(); });
    addShortcut("F9", [this]() { m_panels->listPackagesRequested(); });
    addShortcut("F1", [this]() { m_panels->setCurrentIndex(0); });
    addShortcut("F2", [this]() { m_panels->setCurrentIndex(1); });
    addShortcut("F3", [this]() { m_panels->setCurrentIndex(2); });
    addShortcut("F4", [this]() { m_panels->setCurrentIndex(3); });
    addShortcut("F10", [this]() { onScreenshot(); });
    addShortcut("F11", [this]() {
        if (m_recordTick->isActive())
            onCancelRecord();
        else
            onRecord(30);
    });
    addShortcut("F12", [this]() { onOpenCaptureDir(); });
    addShortcut("Ctrl+,", [this]() { onSettings(); });
    connect(m_panels, &Panels::uninstallPackageRequested, this, [this](const QString &pkg) {
        const QString serial = activeSerial();
        if (!serial.isEmpty())
            m_adb->shell(serial, QStringLiteral("pm uninstall --user 0 %1").arg(pkg));
    });
}

void MainWindow::applyDarkTheme() {
    const int fontPx = Settings::instance().ui().fontSize;
    qApp->setStyleSheet(QStringLiteral(R"(
        QMainWindow, QWidget { background: #14161c; color: #e5e7eb; font-size: %1px; }
        QToolBar { background: #1b1e26; border-bottom: 1px solid #2a2f3a; spacing: 6px; padding: 4px; }
        QLabel { background: transparent; }
        QPushButton { background: #232833; border: 1px solid #333a47; border-radius: 6px; padding: 5px 12px; }
        QPushButton:hover { background: #2c3342; }
        QPushButton:disabled { color: #5b6270; background: #1a1d24; }
        QPushButton:default { background: #2563eb; border-color: #3b82f6; }
        QComboBox { background: #232833; border: 1px solid #333a47; border-radius: 6px; padding: 4px 8px; }
        QComboBox QAbstractItemView { background: #1b1e26; border: 1px solid #333a47; selection-background-color: #2563eb; }
        QPlainTextEdit, QTextEdit, QListWidget, QLineEdit {
            background: #101218; border: 1px solid #2a2f3a; border-radius: 6px;
            color: #d1d5db; selection-background-color: #2563eb;
        }
        QTabWidget::pane { border: 1px solid #2a2f3a; border-radius: 6px; }
        QTabBar::tab { background: #1b1e26; color: #9ca3af; padding: 6px 14px; border: 1px solid #2a2f3a; border-bottom: none; }
        QTabBar::tab:selected { background: #232833; color: #e5e7eb; }
        QStatusBar { background: #1b1e26; border-top: 1px solid #2a2f3a; color: #9ca3af; }
        QSplitter::handle { background: #2a2f3a; width: 3px; }
        QCheckBox { background: transparent; }
    )").arg(fontPx));
}

void MainWindow::onSettings() {
    SettingsDialog dlg(this);
    if (dlg.exec() != QDialog::Accepted)
        return;
    applySettings();
    m_status->setText(QStringLiteral("设置已保存（镜像参数在下次连接时生效）"));
}

void MainWindow::applySettings() {
    applyDarkTheme();
    m_adb->reloadPath();
    m_scrcpy->reloadExePath();
    const ConnOptions c = Settings::instance().conn();
    if (m_autoReconnect)
        m_autoReconnect->setInterval(c.reconnectDelaySec * 1000);
    m_captureDirPath = Settings::instance().captureDir();
    m_panels->setCaptureDir(m_captureDirPath);
    qInfo() << "[settings] applied"
            << "font=" << Settings::instance().ui().fontSize
            << "followResize=" << Settings::instance().ui().followResize
            << "captureDir=" << m_captureDirPath << "reconnect=" << c.reconnectMax << "x"
            << c.reconnectDelaySec << "s";
}

void MainWindow::onDevicesChanged(const QList<AdbClient::Device> &devices) {
    static int lastCount = -1;
    static bool lastOnline = false;
    m_devices = devices;
    const QString prev = m_deviceBox->currentData().toString();
    m_deviceBox->clear();
    int prevIndex = -1;
    for (int i = 0; i < devices.size(); ++i) {
        const auto &d = devices[i];
        const QString label = QStringLiteral("%1  ·  %2  %3")
                                  .arg(d.serial, d.state, d.model);
        m_deviceBox->addItem(label, d.serial);
        if (!prev.isEmpty() && d.serial == prev)
            prevIndex = i;
    }
    if (prevIndex >= 0)
        m_deviceBox->setCurrentIndex(prevIndex);

    const bool online = currentOnline();
    if (devices.size() != lastCount || online != lastOnline) {
        qInfo() << "[adb] devices:" << devices.size() << "online serial:" << currentSerial();
        lastCount = devices.size();
        lastOnline = online;
    }
    m_deviceState->setText(devices.isEmpty() ? QStringLiteral("无设备")
                                             : (online ? QStringLiteral("● 在线") : QStringLiteral("○ 离线")));
    m_connectBtn->setEnabled(online && !m_scrcpy->isRunning());
    if (m_status->text().isEmpty())
        m_status->setText(QStringLiteral("在线设备 %1 台").arg(devices.size()));

    // 启动时恢复了「上次设备」，等它真的在线再连
    if (!m_pendingSerial.isEmpty()) {
        if (m_scrcpy->isRunning()) {
            m_pendingSerial.clear();
        } else if (isSerialOnline(m_pendingSerial)) {
            const QString target = m_pendingSerial;
            m_pendingSerial.clear();
            qInfo() << "[mirror] auto connect last device" << target;
            connectSerial(target);
        }
    }
}

QString MainWindow::currentSerial() const {
    return m_deviceBox->currentData().toString();
}

QString MainWindow::activeSerial() const {
    // 镜像中的设备优先：终端/logcat/截图/录屏应与正在看的画面一致，
    // 而不是跟着下拉框走（切换下拉框不会断开镜像）。
    if (!m_serial.isEmpty())
        return m_serial;
    return currentSerial();
}

bool MainWindow::isSerialOnline(const QString &serial) const {
    for (const auto &d : m_devices) {
        if (d.serial == serial)
            return d.state == QStringLiteral("device");
    }
    return false;
}

bool MainWindow::currentOnline() const {
    return isSerialOnline(currentSerial());
}

void MainWindow::onRefreshClicked() { m_adb->refreshDevices(); }

void MainWindow::sendKey(int keycode) {
    const QString serial = activeSerial();
    if (serial.isEmpty() || !isSerialOnline(serial)) {
        m_status->setText(QStringLiteral("没有在线设备"));
        return;
    }
    qInfo() << "[key] keyevent" << keycode << serial;
    m_adb->shell(serial, QStringLiteral("input keyevent %1").arg(keycode));
}

void MainWindow::rotateScreen() {
    const QString serial = activeSerial();
    if (serial.isEmpty() || !isSerialOnline(serial)) {
        m_status->setText(QStringLiteral("没有在线设备"));
        return;
    }
    // 关掉自动旋转再指定方向，否则系统会立刻转回去
    m_rotation = (m_rotation + 1) % 4;
    qInfo() << "[key] rotate" << m_rotation << serial;
    m_adb->shell(serial,
                 QStringLiteral("settings put system accelerometer_rotation 0; "
                                "settings put system user_rotation %1")
                     .arg(m_rotation));
    m_status->setText(QStringLiteral("屏幕方向已切换为 %1°").arg(m_rotation * 90));
}

void MainWindow::onConnectClicked() {
    const QString serial = currentSerial();
    if (serial.isEmpty()) {
        m_status->setText(QStringLiteral("没有可用设备"));
        qWarning() << "[mirror] connect ignored: no device";
        return;
    }
    if (!currentOnline()) {
        m_status->setText(QStringLiteral("设备离线：%1").arg(serial));
        qWarning() << "[mirror] connect ignored: offline" << serial;
        return;
    }
    connectSerial(serial);
}

void MainWindow::connectSerial(const QString &serial) {
    if (serial.isEmpty())
        return;
    qInfo() << "[mirror] connect requested" << serial;
    m_serial = serial;
    m_retries = 0;
    m_pendingSerial.clear();
    // 记住上次连接的设备，下次启动可自动连
    ConnOptions c = Settings::instance().conn();
    c.lastSerial = serial;
    Settings::instance().setConn(c);
    m_panels->appendShell(QStringLiteral("[连接] ") + serial);
    m_scrcpy->start(serial);
}

void MainWindow::onDisconnectClicked() {
    // 手动断开：停重连，避免刚断开又被拉起来
    qInfo() << "[mirror] disconnect by user" << m_serial;
    m_serial.clear();
    m_retries = 0;
    m_pendingSerial.clear();
    if (m_autoReconnect)
        m_autoReconnect->stop();
    m_scrcpy->stop();
}

void MainWindow::onShellCommand(const QString &cmd) {
    const QString serial = activeSerial();
    if (serial.isEmpty()) {
        m_panels->appendShell(QStringLiteral("[错误] 未选择设备"));
        return;
    }
    qInfo() << "[adb] shell" << cmd;
    m_adb->shell(serial, cmd);
}

void MainWindow::onRefreshInfo() {
    const QString serial = activeSerial();
    if (serial.isEmpty()) {
        m_status->setText(QStringLiteral("未选择设备"));
        return;
    }
    m_panels->setInfo(QStringLiteral("读取设备信息…"));

    // 标签一律用 ASCII：设备端 shell 的 locale 不保证是 UTF-8，中文只在本地拼接显示。
    // 输出用 fromUtf8 解码（adb 的 stdout 就是 UTF-8，原来的 fromLocal8Bit 在 GBK 系统会乱码）。
    const QString cmd = QStringLiteral(
        "echo brand=$(getprop ro.product.brand); "
        "echo model=$(getprop ro.product.model); "
        "echo device=$(getprop ro.product.device); "
        "echo release=$(getprop ro.build.version.release); "
        "echo sdk=$(getprop ro.build.version.sdk); "
        "echo abi=$(getprop ro.product.cpu.abi); "
        "echo serialno=$(getprop ro.serialno); "
        "echo size=$(wm size | tail -1); "
        "echo density=$(wm density | tail -1); "
        "echo level=$(dumpsys battery | awk -F: '/level/{print $2; exit}'); "
        "echo status=$(dumpsys battery | awk -F: '/status/{print $2; exit}'); "
        "echo uptime=$(uptime)");

    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc](int rc, QProcess::ExitStatus) {
                const QString raw = QString::fromUtf8(proc->readAllStandardOutput());
                if (rc != 0) {
                    qWarning() << "[info] read failed rc=" << rc << raw;
                    m_panels->setInfo(QStringLiteral("读取失败（rc=%1）\n%2").arg(rc).arg(raw));
                    m_status->setText(QStringLiteral("设备信息读取失败"));
                    proc->deleteLater();
                    return;
                }
                QHash<QString, QString> kv;
                for (const QString &line : raw.split(QLatin1Char('\n'))) {
                    const int eq = line.indexOf(QLatin1Char('='));
                    if (eq <= 0)
                        continue;
                    kv.insert(line.left(eq).trimmed(), line.mid(eq + 1).trimmed());
                }

                const QString status = kv.value(QStringLiteral("status"));
                QString batteryState;
                if (status == QStringLiteral("2"))
                    batteryState = QStringLiteral("充电中");
                else if (status == QStringLiteral("3"))
                    batteryState = QStringLiteral("放电中");
                else if (!status.isEmpty())
                    batteryState = QStringLiteral("状态 %1").arg(status);

                const QString level = kv.value(QStringLiteral("level"));
                const QString battery =
                    batteryState.isEmpty() ? level + QStringLiteral("%")
                                           : level + QStringLiteral("% · ") + batteryState;

                QStringList rows{
                    QStringLiteral("品牌        %1").arg(kv.value(QStringLiteral("brand"))),
                    QStringLiteral("型号        %1").arg(kv.value(QStringLiteral("model"))),
                    QStringLiteral("设备代号    %1").arg(kv.value(QStringLiteral("device"))),
                    QStringLiteral("系统        Android %1 (SDK %2)")
                        .arg(kv.value(QStringLiteral("release")), kv.value(QStringLiteral("sdk"))),
                    QStringLiteral("ABI         %1").arg(kv.value(QStringLiteral("abi"))),
                    QStringLiteral("分辨率      %1").arg(kv.value(QStringLiteral("size"))),
                    QStringLiteral("密度        %1").arg(kv.value(QStringLiteral("density"))),
                    QStringLiteral("电量        %1").arg(battery),
                    QStringLiteral("序列号      %1").arg(kv.value(QStringLiteral("serialno"))),
                    QStringLiteral("运行时长    %1").arg(kv.value(QStringLiteral("uptime"))),
                    QStringLiteral("连接        %1").arg(activeSerial()),
                };
                m_panels->setInfo(rows.join(QLatin1Char('\n')));
                m_status->setText(QStringLiteral("设备信息已刷新：%1 %2 · 电量 %3")
                                      .arg(kv.value(QStringLiteral("brand")),
                                           kv.value(QStringLiteral("model")), battery));
                qInfo() << "[info] refreshed" << kv.value(QStringLiteral("brand"))
                        << kv.value(QStringLiteral("model")) << "battery" << battery;
                proc->deleteLater();
            });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) {
            m_panels->setInfo(QStringLiteral("adb 启动失败：%1").arg(m_adb->adbPath()));
            m_status->setText(QStringLiteral("设备信息读取失败"));
        }
        proc->deleteLater();
    });
    proc->start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("shell"), cmd});
}

bool MainWindow::eventFilter(QObject *watched, QEvent *event) {
    // 宿主尺寸变化时同步内嵌的 scrcpy 子窗口（否则拖分隔条/最大化会裁切或留黑）。
    // 防抖 150ms：拖动过程中会连续触发 Resize。
    if (watched == m_mirrorHost && event->type() == QEvent::Resize && m_scrcpy->isRunning()
        && Settings::instance().ui().followResize) {
        if (!m_resizeDebounce) {
            m_resizeDebounce = new QTimer(this);
            m_resizeDebounce->setSingleShot(true);
            m_resizeDebounce->setInterval(150);
            connect(m_resizeDebounce, &QTimer::timeout, this, [this]() {
                if (m_mirrorHost && m_scrcpy) {
                    qInfo() << "[mirror] resize follow" << m_mirrorHost->size();
                    m_scrcpy->resizeEmbedded(m_mirrorHost->width(), m_mirrorHost->height());
                }
            });
        }
        m_resizeDebounce->start();
    }

    if (!m_scrcpy || !m_scrcpy->isRunning())
        return QMainWindow::eventFilter(watched, event);
    HWND child = m_scrcpy->childHandle();
    if (!child)
        return QMainWindow::eventFilter(watched, event);

    const QEvent::Type type = event->type();

    // 键盘：右侧面板控件持有焦点时让它自己处理，其余转发给 scrcpy。
    if (type == QEvent::KeyPress || type == QEvent::KeyRelease) {
        QWidget *fw = QApplication::focusWidget();
        if (fw && m_panels->isAncestorOf(fw))
            return QMainWindow::eventFilter(watched, event);
        auto *ke = static_cast<QKeyEvent *>(event);
        const UINT vk = static_cast<UINT>(ke->nativeVirtualKey());
        if (vk == 0 || ke->isAutoRepeat())
            return QMainWindow::eventFilter(watched, event);
        const bool down = (type == QEvent::KeyPress);
        const LPARAM lp = 1 | (static_cast<LPARAM>(MapVirtualKeyW(vk, MAPVK_VK_TO_VSC)) << 16);
        PostMessageW(child, down ? WM_KEYDOWN : WM_KEYUP, vk, lp);
        return true;
    }

    // 滚轮：鼠标不在右侧面板内时转发，手势滚动由 scrcpy 注入手机。
    if (type == QEvent::Wheel) {
        auto *we = static_cast<QWheelEvent *>(event);
        QWidget *under = QApplication::widgetAt(we->globalPosition().toPoint());
        if (under && m_panels->isAncestorOf(under))
            return QMainWindow::eventFilter(watched, event);
        const int delta = we->angleDelta().y();
        if (delta == 0)
            return QMainWindow::eventFilter(watched, event);
        const QPoint gp = we->globalPosition().toPoint();
        PostMessageW(child, WM_MOUSEWHEEL, MAKEWPARAM(0, delta), MAKELPARAM(gp.x(), gp.y()));
        return true;
    }

    return QMainWindow::eventFilter(watched, event);
}

void MainWindow::onLogcatStart() {
    const QString serial = activeSerial();
    if (serial.isEmpty() || !currentOnline()) {
        m_panels->appendLog(QStringLiteral("[错误] 没有在线设备"));
        return;
    }
    if (m_logcat) {
        QProcess *old = m_logcat;
        m_logcat = nullptr;
        old->disconnect(this);
        old->kill();
        old->waitForFinished(1000);
        old->deleteLater();
    }
    m_logcatTail.clear();
    m_logDropped = 0;
    if (!m_logFlush) {
        m_logFlush = new QTimer(this);
        m_logFlush->setInterval(120);
        connect(m_logFlush, &QTimer::timeout, this, &MainWindow::flushLogcat);
    }
    QProcess *proc = new QProcess(this);
    m_logcat = proc;
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::readyReadStandardOutput, this, [this, proc]() {
        // 用捕获的 proc 而非成员 m_logcat：切换实例时成员可能已被替换
        m_logcatTail.append(proc->readAllStandardOutput());
        // 背压：UI 写入跟不上时丢弃最旧的一半，避免缓冲无限增长
        if (m_logcatTail.size() > (1 << 20)) {
            m_logcatTail = m_logcatTail.right(512 * 1024);
            ++m_logDropped;
        }
        if (!m_logFlush->isActive())
            m_logFlush->start();
    });
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc](int, QProcess::ExitStatus) {
                flushLogcat();
                m_panels->setLogcatRunning(false);
                if (m_logcat == proc)
                    m_logcat = nullptr;
                proc->deleteLater();
            });
    proc->start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("logcat"),
                                   QStringLiteral("-v"), QStringLiteral("time")});
    m_panels->setLogcatRunning(true);
    m_panels->appendLog(QStringLiteral("[logcat] 开始抓取 ") + serial);
    qInfo() << "[logcat] started" << serial;
}

void MainWindow::flushLogcat() {
    if (m_logFlush)
        m_logFlush->stop();
    if (m_logcatTail.isEmpty())
        return;
    // logcat 每秒可以刷几十行，逐行 insertPlainText 会让 QPlainTextEdit 重排到卡死，
    // 这里每 120ms 批量插一次。
    const QList<QByteArray> lines = m_logcatTail.split('\n');
    m_logcatTail = lines.last();
    QStringList ready;
    ready.reserve(lines.size());
    for (int i = 0; i < lines.size() - 1; ++i)
        ready << QString::fromUtf8(lines[i]);
    if (m_logDropped > 0) {
        ready.prepend(QStringLiteral("[logcat] 忽略 %1 段（刷新跟不上）").arg(m_logDropped));
        m_logDropped = 0;
    }
    m_panels->appendLogLines(ready);
}

void MainWindow::onLogcatStop() {
    QProcess *proc = m_logcat;
    m_logcat = nullptr;
    if (proc) {
        proc->disconnect(this);
        proc->kill();
        proc->waitForFinished(1000);
        proc->deleteLater();
    }
    if (m_logFlush)
        m_logFlush->stop();
    flushLogcat();
    m_panels->setLogcatRunning(false);
    m_panels->appendLog(QStringLiteral("[logcat] 已停止"));
    qInfo() << "[logcat] stopped";
}

// ---- 截图 / 录屏 ----

QString MainWindow::ensureCaptureDir() {
    if (!QDir().mkpath(m_captureDirPath)) {
        const QString native = QDir::toNativeSeparators(m_captureDirPath);
        m_panels->appendCapture(QStringLiteral("无法创建保存目录：") + native, QString(), false);
        m_status->setText(QStringLiteral("✗ 无法创建保存目录：%1").arg(native));
        return QString();
    }
    return m_captureDirPath;
}

void MainWindow::reportCapture(const QString &label, const QString &path, bool ok,
                               const QString &detail) {
    m_panels->appendCapture(label, path, ok);
    if (ok) {
        const QString dir = QDir::toNativeSeparators(m_captureDirPath);
        QString extra;
        if (!detail.isEmpty())
            extra = QStringLiteral("（") + detail + QLatin1Char(')');
        m_status->setText(
            QStringLiteral("✓ %1 已保存到 %2%3").arg(QFileInfo(path).fileName(), dir, extra));
        qInfo() << "[capture] saved" << path;
    } else {
        m_status->setText(QStringLiteral("✗ %1").arg(label));
        qWarning() << "[capture] failed" << label << detail;
    }
}

void MainWindow::onScreenshot() {
    const QString serial = activeSerial();
    if (serial.isEmpty()) {
        reportCapture(QStringLiteral("截图失败：未选择设备"), QString(), false);
        return;
    }
    if (!currentOnline()) {
        reportCapture(QStringLiteral("截图失败：设备离线"), QString(), false);
        return;
    }
    const QString dir = ensureCaptureDir();
    if (dir.isEmpty())
        return;

    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    const QString path = dir + QStringLiteral("/devboard-shot-") + stamp + QStringLiteral(".png");

    // exec-out 直接把 PNG 送到 stdout，省一次设备端落盘与 pull
    auto *proc = new QProcess(this);
    auto buf = QSharedPointer<QByteArray>::create();
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::readyReadStandardOutput, this,
            [proc, buf]() { buf->append(proc->readAllStandardOutput()); });
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc, buf, path, serial](int rc, QProcess::ExitStatus st) {
                const QByteArray pngMagic = QByteArray::fromHex("89504e47");
                const bool ok = st == QProcess::NormalExit && rc == 0 && buf->size() > 1024
                                && buf->startsWith(pngMagic);
                QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
                proc->deleteLater();
                if (ok) {
                    QFile f(path);
                    if (f.open(QIODevice::WriteOnly) && f.write(*buf) == buf->size()) {
                        f.close();
                        reportCapture(QStringLiteral("截图 %1").arg(QFileInfo(path).fileName()),
                                      path, true);
                    } else {
                        reportCapture(QStringLiteral("截图失败：写入本地文件失败"), QString(), false);
                    }
                    return;
                }
                if (err.isEmpty())
                    err = QStringLiteral("exec-out 返回 %1 字节、rc=%2").arg(buf->size()).arg(rc);
                // 旧 adb 不支持 exec-out 时回退到设备文件 + pull
                captureViaDeviceFile(serial, path, err);
            });
    proc->start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("exec-out"),
                                   QStringLiteral("screencap"), QStringLiteral("-p")});
    m_status->setText(QStringLiteral("正在截图…"));
}

void MainWindow::captureViaDeviceFile(const QString &serial, const QString &localPath,
                                      const QString &prevErr) {
    // 临时文件名带时间戳：并发/连续截图不会互相覆盖
    const QString remote = QStringLiteral("/sdcard/devboard-shot-%1.png")
                               .arg(QDateTime::currentDateTime().toString(
                                   QStringLiteral("yyyyMMddHHmmsszzz")));
    auto *shot = new QProcess(this);
    connect(shot, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, shot, serial, remote, localPath, prevErr](int rc, QProcess::ExitStatus) {
                shot->deleteLater();
                if (rc != 0) {
                    reportCapture(QStringLiteral("截图失败：%1").arg(prevErr), QString(), false);
                    return;
                }
                auto *pull = new QProcess(this);
                connect(pull, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
                        [this, pull, serial, remote, localPath](int, QProcess::ExitStatus) {
                            pull->deleteLater();
                            QProcess::startDetached(m_adb->adbPath(),
                                                    {QStringLiteral("-s"), serial,
                                                     QStringLiteral("shell"), QStringLiteral("rm"),
                                                     QStringLiteral("-f"), remote});
                            if (QFileInfo(localPath).size() > 1024) {
                                reportCapture(
                                    QStringLiteral("截图 %1").arg(QFileInfo(localPath).fileName()),
                                    localPath, true);
                            } else {
                                reportCapture(QStringLiteral("截图失败：未能取回图片"), QString(),
                                              false);
                            }
                        });
                pull->start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("pull"),
                                               remote, localPath});
            });
    shot->start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("shell"),
                                   QStringLiteral("screencap"), QStringLiteral("-p"), remote});
}

void MainWindow::onRecord(int seconds) {
    if (m_recordTick->isActive()) {
        onCancelRecord();
        return;
    }
    const QString serial = activeSerial();
    if (serial.isEmpty()) {
        reportCapture(QStringLiteral("录屏失败：未选择设备"), QString(), false);
        return;
    }
    if (!currentOnline()) {
        reportCapture(QStringLiteral("录屏失败：设备离线"), QString(), false);
        return;
    }
    const QString dir = ensureCaptureDir();
    if (dir.isEmpty())
        return;

    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    const QString remote = QStringLiteral("/sdcard/devboard-rec-") + stamp + QStringLiteral(".mp4");
    const QString local = dir + QStringLiteral("/devboard-rec-") + stamp + QStringLiteral(".mp4");
    const QString pidFile = QStringLiteral("/data/local/tmp/devboard_rec.pid");

    m_recordSerial = serial;
    m_recordRemote = remote;
    m_recordLocal = local;
    m_recordPidFile = pidFile;
    m_recordSeconds = seconds;
    m_recordRemain = seconds;
    m_recordTicks = 0;
    m_recordStopping = false;
    m_recordCancelled = false;

    // 设备端后台运行：nohup 保证 adb shell 退出后 screenrecord 存活；
    // 记录 pid 供「停止录屏」发 SIGINT，让 screenrecord 正常写完 moov 索引，
    // 否则直接 kill 会得到无法播放的 MP4。
    const QString cmd =
        QStringLiteral("rm -f %1; nohup screenrecord --time-limit %2 --bit-rate 8000000 %3 "
                       ">/dev/null 2>&1 & P=$!; echo $P > %1; echo started:$P")
            .arg(pidFile, QString::number(seconds), remote);

    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc](int rc, QProcess::ExitStatus) {
                const QString out = QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
                const QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
                proc->deleteLater();
                if (!out.contains(QStringLiteral("started:"))) {
                    qWarning() << "[record] start failed rc=" << rc << out << err;
                    m_recordTick->stop();
                    m_panels->setRecording(false);
                    m_recordSerial.clear();
                    m_recordRemote.clear();
                    m_recordLocal.clear();
                    m_recordPidFile.clear();
                    m_recordStopping = false;
                    reportCapture(QStringLiteral("录屏失败：设备端 screenrecord 未能启动"), QString(),
                                  false, err.isEmpty() ? out : err);
                    return;
                }
                qInfo() << "[record] started" << out << "->" << m_recordRemote;
                m_status->setText(QStringLiteral("录制中… 剩余 %1 秒（再点「停止录屏」提前结束）")
                                      .arg(m_recordRemain));
            });
    proc->start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("shell"), cmd});

    m_panels->setRecording(true);
    m_recordTick->start();
    m_status->setText(QStringLiteral("正在启动录屏…"));
}

void MainWindow::onCancelRecord() {
    if (!m_recordTick->isActive() || m_recordPidFile.isEmpty())
        return;
    if (m_recordStopping)
        return;
    m_recordStopping = true;
    m_recordCancelled = true;
    qInfo() << "[record] stopping via SIGINT";
    auto *p = new QProcess(this);
    connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [p](int, QProcess::ExitStatus) { p->deleteLater(); });
    p->start(m_adb->adbPath(),
             {QStringLiteral("-s"), m_recordSerial, QStringLiteral("shell"),
              QStringLiteral("kill -INT $(cat %1) 2>/dev/null; echo done").arg(m_recordPidFile)});
    m_status->setText(QStringLiteral("正在停止录屏…"));
}

void MainWindow::probeRecord() {
    if (m_recordProbe || m_recordPidFile.isEmpty())
        return;
    auto *p = new QProcess(this);
    m_recordProbe = p;
    const QString cmd =
        QStringLiteral("[ -r %1 ] && { kill -0 $(cat %1) 2>/dev/null && echo alive || echo gone; } "
                       "|| echo gone")
            .arg(m_recordPidFile);
    connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, p](int, QProcess::ExitStatus) {
                const QString out = QString::fromUtf8(p->readAllStandardOutput()).trimmed();
                p->deleteLater();
                if (m_recordProbe == p)
                    m_recordProbe = nullptr;
                if (out.contains(QStringLiteral("gone")))
                    finishRecord();
            });
    p->start(m_adb->adbPath(),
             {QStringLiteral("-s"), m_recordSerial, QStringLiteral("shell"), cmd});
}

void MainWindow::finishRecord() {
    if (!m_recordTick->isActive())
        return;
    m_recordTick->stop();
    m_panels->setRecording(false);
    m_status->setText(QStringLiteral("录屏已结束，正在取回文件…"));

    const QString serial = m_recordSerial;
    const QString remote = m_recordRemote;
    const QString local = m_recordLocal;
    const bool cancelled = m_recordCancelled;
    m_recordSerial.clear();
    m_recordRemote.clear();
    m_recordLocal.clear();
    m_recordPidFile.clear();
    m_recordStopping = false;
    m_recordCancelled = false;
    m_recordSeconds = 0;
    m_recordTicks = 0;
    m_recordRemain = 0;

    // screenrecord 收到 SIGINT 后还要写索引，稍等再 pull
    QTimer::singleShot(350, this, [this, serial, remote, local, cancelled]() {
        pullRecord(serial, remote, local, cancelled);
    });
}

void MainWindow::pullRecord(const QString &serial, const QString &remote, const QString &local,
                            bool cancelled) {
    auto *pull = new QProcess(this);
    connect(pull, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, pull, serial, remote, local, cancelled](int rc, QProcess::ExitStatus) {
                const QString err = QString::fromUtf8(pull->readAllStandardError()).trimmed();
                pull->deleteLater();
                QProcess::startDetached(m_adb->adbPath(),
                                        {QStringLiteral("-s"), serial, QStringLiteral("shell"),
                                         QStringLiteral("rm"), QStringLiteral("-f"), remote});
                const qint64 size = QFileInfo(local).size();
                if (rc == 0 && size > 1024) {
                    const QString detail =
                        cancelled ? QStringLiteral("提前停止，已正常收尾")
                                  : QStringLiteral("%1 MB").arg(size / 1024.0 / 1024.0, 0, 'f', 1);
                    qInfo() << "[record] saved" << local << size << "bytes";
                    reportCapture(QStringLiteral("录屏 %1").arg(QFileInfo(local).fileName()), local,
                                  true, detail);
                } else {
                    qWarning() << "[record] pull failed rc=" << rc << size << err;
                    reportCapture(QStringLiteral("录屏失败：未能取回视频"), QString(), false, err);
                }
            });
    pull->start(m_adb->adbPath(),
                {QStringLiteral("-s"), serial, QStringLiteral("pull"), remote, local});
}

void MainWindow::onChooseCaptureDir() {
    const QString dir = QFileDialog::getExistingDirectory(
        this, QStringLiteral("选择截图与录屏的保存目录"), m_captureDirPath);
    if (dir.isEmpty())
        return;
    m_captureDirPath = dir;
    // 统一走 Settings，操作页与设置对话框共用同一个值
    Settings::instance().setCaptureDir(dir);
    m_panels->setCaptureDir(dir);
    m_status->setText(QStringLiteral("保存目录已改为 %1").arg(QDir::toNativeSeparators(dir)));
}

void MainWindow::onOpenCaptureDir() {
    if (ensureCaptureDir().isEmpty())
        return;
    QDesktopServices::openUrl(QUrl::fromLocalFile(m_captureDirPath));
}

void MainWindow::onOpenCaptureFile(const QString &path) {
    if (!QFileInfo::exists(path)) {
        m_status->setText(QStringLiteral("✗ 文件已不存在：%1").arg(QDir::toNativeSeparators(path)));
        return;
    }
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

