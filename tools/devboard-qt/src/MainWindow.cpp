#include "MainWindow.h"

#include <QApplication>
#include <QComboBox>
#include <QFileDialog>
#include <QFrame>
#include <QHBoxLayout>
#include <QLabel>
#include <QMessageBox>
#include <QProcess>
#include <QPushButton>
#include <QSplitter>
#include <QStatusBar>
#include <QTimer>
#include <QToolBar>
#include <QVBoxLayout>

#include "Panels.h"
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
    });
    connect(m_scrcpy, &ScrcpyProcess::statusText, this, [this](const QString &t) {
        m_status->setText(t);
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

    // ---- 中央：左镜像 + 右面板 ----
    auto *split = new QSplitter(Qt::Horizontal, this);

    m_mirrorHost = new QWidget(split);
    m_mirrorHost->setMinimumSize(360, 480);
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
        if (!serial.isEmpty())
            m_adb->shell(serial, QStringLiteral("pm list packages -3"));
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
    m_panels->appendShell(QStringLiteral("[连接] ") + serial);
    m_scrcpy->start(serial, 720, 60);
}

void MainWindow::onDisconnectClicked() { m_scrcpy->stop(); }

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
