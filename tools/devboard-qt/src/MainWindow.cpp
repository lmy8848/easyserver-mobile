#include "MainWindow.h"

#include <QApplication>
#include <QComboBox>
#include <QFileDialog>
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
#include <QInputDialog>
#include <QTimer>
#include <QToolBar>
#include <QVBoxLayout>
#include <QWheelEvent>

#include "Panels.h"
#include "PairDialog.h"
#include "ScrcpyProcess.h"

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    m_adb = new AdbClient(this);
    m_scrcpy = new ScrcpyProcess(this);

    buildUi();
    applyDarkTheme();

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

    // 非主动停止（无线 adb 掉线、scrcpy 崩溃）时自动重连，3s 一次、最多 6 次
    m_autoReconnect = new QTimer(this);
    m_autoReconnect->setSingleShot(true);
    m_autoReconnect->setInterval(3000);
    connect(m_autoReconnect, &QTimer::timeout, this, [this]() {
        if (m_serial.isEmpty())
            return;
        if (m_retries >= 6) {
            m_status->setText(QStringLiteral("自动重连已暂停（6 次失败）· 检查手机后点「连接镜像」"));
            return;
        }
        ++m_retries;
        m_status->setText(QStringLiteral("重连中…（第 %1 次）").arg(m_retries));
        qInfo() << "[reconnect] attempt" << m_retries << m_serial;
        m_adb->refreshDevices();
        m_scrcpy->start(m_serial, 720, 60);
    });
    connect(m_scrcpy, &ScrcpyProcess::exitedUnexpectedly, this, [this](int code) {
        if (m_serial.isEmpty())
            return;
        m_panels->appendShell(QStringLiteral("[scrcpy] 意外退出 code=%1，将自动重连").arg(code));
        m_status->setText(QStringLiteral("镜像断开（code=%1），3 秒后重连").arg(code));
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

    qInfo() << "[main] MainWindow built";
}

MainWindow::~MainWindow() {
    if (m_scrcpy)
        m_scrcpy->stop();
}

void MainWindow::buildUi() {
    setWindowTitle(QStringLiteral("DevBoard"));
    resize(1440, 900);

    // ---- 顶部工具条 ----
    auto *bar = addToolBar(QStringLiteral("设备"));
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
    split->setStretchFactor(0, 3);
    split->setStretchFactor(1, 2);
    setCentralWidget(split);

    m_scrcpy->setHost(m_mirrorHost);
    qApp->installEventFilter(this);

    // ---- 状态栏 ----
    m_status = new QLabel(QStringLiteral("就绪"), this);
    statusBar()->addWidget(m_status, 1);

    // ---- 面板信号 ----
    connect(m_panels, &Panels::shellCommandEntered, this, &MainWindow::onShellCommand);
    connect(m_panels, &Panels::refreshInfoRequested, this, &MainWindow::onRefreshInfo);
    connect(m_panels, &Panels::screenshotRequested, this, [this]() {
        const QString serial = currentSerial();
        if (!serial.isEmpty())
            m_adb->shell(serial, QStringLiteral(
                "screencap -p /sdcard/devboard_shot.png && echo '已保存 /sdcard/devboard_shot.png'"));
    });
    connect(m_panels, &Panels::recordRequested, this, [this]() {
        const QString serial = currentSerial();
        if (!serial.isEmpty())
            m_adb->shell(serial, QStringLiteral(
                "screenrecord --time-limit 30 /sdcard/devboard_record.mp4 & echo '录屏开始（30s）'"));
    });
    connect(m_panels, &Panels::listPackagesRequested, this, [this]() {
        const QString serial = currentSerial();
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
        const QString serial = currentSerial();
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
        m_panels->appendShell(QString::fromLocal8Bit(p.readAllStandardOutput()));
        m_panels->appendShell(QString::fromLocal8Bit(p.readAllStandardError()));
    });
    connect(m_panels, &Panels::logcatStartRequested, this, &MainWindow::onLogcatStart);
    connect(m_panels, &Panels::logcatStopRequested, this, &MainWindow::onLogcatStop);

    auto addShortcut = [this](const char *key, auto fn) {
        auto *sc = new QShortcut(QKeySequence(QString::fromLatin1(key)), this);
        sc->setContext(Qt::WindowShortcut);
        connect(sc, &QShortcut::activated, this, fn);
    };
    addShortcut("F5", [this]() {
        if (m_logcat)
            onLogcatStop();
        else
            onLogcatStart();
    });
    addShortcut("F6", [this]() { m_panels->clearLog(); });
    addShortcut("F7", [this]() { m_panels->refreshInfoRequested(); });
    addShortcut("F8", [this]() { m_panels->listPackagesRequested(); });
    connect(m_panels, &Panels::uninstallPackageRequested, this, [this](const QString &pkg) {
        const QString serial = currentSerial();
        if (!serial.isEmpty())
            m_adb->shell(serial, QStringLiteral("pm uninstall --user 0 %1").arg(pkg));
    });
}

void MainWindow::applyDarkTheme() {
    qApp->setStyleSheet(QStringLiteral(R"(
        QMainWindow, QWidget { background: #14161c; color: #e5e7eb; font-size: 13px; }
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
    )"));
}

void MainWindow::onDevicesChanged(const QList<AdbClient::Device> &devices) {
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
    m_deviceState->setText(devices.isEmpty() ? QStringLiteral("无设备")
                                             : (online ? QStringLiteral("● 在线") : QStringLiteral("○ 离线")));
    m_connectBtn->setEnabled(online && !m_scrcpy->isRunning());
    if (m_status->text().isEmpty())
        m_status->setText(QStringLiteral("在线设备 %1 台").arg(devices.size()));
}

QString MainWindow::currentSerial() const {
    return m_deviceBox->currentData().toString();
}

bool MainWindow::currentOnline() const {
    const QString serial = currentSerial();
    for (const auto &d : m_devices) {
        if (d.serial == serial)
            return d.state == QStringLiteral("device");
    }
    return false;
}

void MainWindow::onRefreshClicked() { m_adb->refreshDevices(); }

void MainWindow::onConnectClicked() {
    const QString serial = currentSerial();
    if (serial.isEmpty()) {
        m_status->setText(QStringLiteral("没有可用设备"));
        return;
    }
    if (!currentOnline()) {
        m_status->setText(QStringLiteral("设备离线：%1").arg(serial));
        return;
    }
    connectSerial(serial);
}

void MainWindow::connectSerial(const QString &serial) {
    if (serial.isEmpty())
        return;
    m_serial = serial;
    m_retries = 0;
    m_panels->appendShell(QStringLiteral("[连接] ") + serial);
    m_scrcpy->start(serial, 720, 60);
}

void MainWindow::onDisconnectClicked() {
    // 手动断开：停重连，避免刚断开又被拉起来
    m_serial.clear();
    m_retries = 0;
    if (m_autoReconnect)
        m_autoReconnect->stop();
    m_scrcpy->stop();
}

void MainWindow::onShellCommand(const QString &cmd) {
    const QString serial = currentSerial();
    if (serial.isEmpty()) {
        m_panels->appendShell(QStringLiteral("[错误] 未选择设备"));
        return;
    }
    m_adb->shell(serial, cmd);
}

void MainWindow::onRefreshInfo() {
    const QString serial = currentSerial();
    if (serial.isEmpty()) {
        m_panels->appendShell(QStringLiteral("[错误] 未选择设备"));
        return;
    }
    m_panels->setInfo(QStringLiteral("读取设备信息…"));
    const QString cmd = QStringLiteral(
        "echo 品牌: $(getprop ro.product.brand); "
        "echo 型号: $(getprop ro.product.model); "
        "echo Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk)); "
        "echo ABI: $(getprop ro.product.cpu.abi); "
        "echo 分辨率: $(wm size | tr -d '\\r'); "
        "echo 密度: $(wm density | tr -d '\\r'); "
        "echo 电量: $(dumpsys battery | grep -E 'level|status' | tr -d '\\r')");
    QProcess p;
    p.start(m_adb->adbPath(), {QStringLiteral("-s"), serial, QStringLiteral("shell"), cmd});
    if (p.waitForFinished(15000)) {
        m_panels->setInfo(QString::fromLocal8Bit(p.readAllStandardOutput()));
    } else {
        m_panels->setInfo(QStringLiteral("读取超时"));
    }
}

bool MainWindow::eventFilter(QObject *watched, QEvent *event) {
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
    const QString serial = currentSerial();
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
    connect(proc, &QProcess::readyReadStandardOutput, this, [this]() {
        m_logcatTail.append(m_logcat->readAllStandardOutput());
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

