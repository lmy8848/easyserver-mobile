#include "SettingsDialog.h"

#include <QCheckBox>
#include <QComboBox>
#include <QDesktopServices>
#include <QDialogButtonBox>
#include <QDir>
#include <QFileDialog>
#include <QFileInfo>
#include <QFormLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QScrollArea>
#include <QSpinBox>
#include <QUrl>
#include <QVBoxLayout>

#include "AppLog.h"
#include "Settings.h"

SettingsDialog::SettingsDialog(QWidget *parent) : QDialog(parent) {
    setWindowTitle(QStringLiteral("设置"));
    setMinimumSize(560, 620);

    auto *root = new QVBoxLayout(this);
    auto *scroll = new QScrollArea(this);
    scroll->setWidgetResizable(true);
    auto *body = new QWidget(scroll);
    auto *lay = new QVBoxLayout(body);
    lay->setSpacing(10);

    // ---- 镜像 ----
    auto *mirrorBox = new QGroupBox(QStringLiteral("镜像（下次连接生效）"), body);
    auto *mirrorForm = new QFormLayout(mirrorBox);
    m_maxSize = new QComboBox(mirrorBox);
    m_maxSize->addItem(QStringLiteral("原始分辨率"), 0);
    m_maxSize->addItem(QStringLiteral("1080"), 1080);
    m_maxSize->addItem(QStringLiteral("720（推荐，省带宽）"), 720);
    m_maxSize->addItem(QStringLiteral("480"), 480);
    m_maxFps = new QComboBox(mirrorBox);
    m_maxFps->addItem(QStringLiteral("不限"), 0);
    m_maxFps->addItem(QStringLiteral("30"), 30);
    m_maxFps->addItem(QStringLiteral("60（推荐）"), 60);
    m_maxFps->addItem(QStringLiteral("90（多数设备编码器跟不上，反而掉帧）"), 90);
    m_bitRate = new QSpinBox(mirrorBox);
    m_bitRate->setRange(0, 50);
    m_bitRate->setSuffix(QStringLiteral(" Mbps"));
    m_bitRate->setSpecialValueText(QStringLiteral("默认"));
    m_displayBuffer = new QComboBox(mirrorBox);
    m_displayBuffer->addItem(QStringLiteral("关（最低延迟）"), 0);
    m_displayBuffer->addItem(QStringLiteral("30 ms"), 30);
    m_displayBuffer->addItem(QStringLiteral("60 ms（无线抖动大时更顺滑）"), 60);
    m_displayBuffer->addItem(QStringLiteral("100 ms"), 100);
    m_stayAwake = new QCheckBox(QStringLiteral("连接期间保持设备唤醒"), mirrorBox);
    m_turnScreenOff = new QCheckBox(QStringLiteral("连接后关闭手机屏幕（视频仍继续传输）"), mirrorBox);
    mirrorForm->addRow(QStringLiteral("分辨率上限"), m_maxSize);
    mirrorForm->addRow(QStringLiteral("帧率上限"), m_maxFps);
    mirrorForm->addRow(QStringLiteral("码率"), m_bitRate);
    mirrorForm->addRow(QStringLiteral("视频缓冲"), m_displayBuffer);
    mirrorForm->addRow(QString(), m_stayAwake);
    mirrorForm->addRow(QString(), m_turnScreenOff);
    lay->addWidget(mirrorBox);

    // ---- 连接 ----
    auto *connBox = new QGroupBox(QStringLiteral("连接"), body);
    auto *connForm = new QFormLayout(connBox);
    m_autoConnectLast = new QCheckBox(QStringLiteral("启动时自动连接上次使用的设备"), connBox);
    m_reconnectMax = new QSpinBox(connBox);
    m_reconnectMax->setRange(0, 50);
    m_reconnectMax->setSpecialValueText(QStringLiteral("不自动重连"));
    m_reconnectDelay = new QSpinBox(connBox);
    m_reconnectDelay->setRange(1, 60);
    m_reconnectDelay->setSuffix(QStringLiteral(" 秒"));
    connForm->addRow(QString(), m_autoConnectLast);
    connForm->addRow(QStringLiteral("重连次数上限"), m_reconnectMax);
    connForm->addRow(QStringLiteral("重连间隔"), m_reconnectDelay);
    lay->addWidget(connBox);

    // ---- 路径 ----
    auto *pathBox = new QGroupBox(QStringLiteral("工具与文件"), body);
    auto *pathForm = new QFormLayout(pathBox);
    auto makePathRow = [pathBox](QLineEdit **edit, QPushButton **btn) {
        auto *row = new QWidget(pathBox);
        auto *h = new QHBoxLayout(row);
        h->setContentsMargins(0, 0, 0, 0);
        h->setSpacing(6);
        *edit = new QLineEdit(row);
        *btn = new QPushButton(QStringLiteral("浏览…"), row);
        h->addWidget(*edit, 1);
        h->addWidget(*btn);
        return row;
    };
    QPushButton *adbBtn = nullptr;
    QPushButton *scrcpyBtn = nullptr;
    QPushButton *dirBtn = nullptr;
    pathForm->addRow(QStringLiteral("adb.exe"), makePathRow(&m_adbPath, &adbBtn));
    pathForm->addRow(QStringLiteral("scrcpy.exe"), makePathRow(&m_scrcpyPath, &scrcpyBtn));
    pathForm->addRow(QStringLiteral("截图/录屏目录"), makePathRow(&m_captureDir, &dirBtn));
    m_adbPath->setPlaceholderText(QStringLiteral("留空自动探测"));
    m_scrcpyPath->setPlaceholderText(QStringLiteral("留空自动探测"));

    auto *logRow = new QWidget(pathBox);
    auto *logLay = new QHBoxLayout(logRow);
    logLay->setContentsMargins(0, 0, 0, 0);
    auto *logPath = new QLineEdit(QDir::toNativeSeparators(AppLog::logDir()), logRow);
    logPath->setReadOnly(true);
    auto *openLogBtn = new QPushButton(QStringLiteral("打开"), logRow);
    logLay->addWidget(logPath, 1);
    logLay->addWidget(openLogBtn);
    pathForm->addRow(QStringLiteral("应用日志"), logRow);
    connect(openLogBtn, &QPushButton::clicked, this, []() {
        const QString dir = AppLog::logDir();
        QDir().mkpath(dir);
        QDesktopServices::openUrl(QUrl::fromLocalFile(dir));
    });
    lay->addWidget(pathBox);

    // ---- 界面 ----
    auto *uiBox = new QGroupBox(QStringLiteral("界面"), body);
    auto *uiForm = new QFormLayout(uiBox);
    m_fontSize = new QSpinBox(uiBox);
    m_fontSize->setRange(10, 18);
    m_fontSize->setSuffix(QStringLiteral(" px"));
    m_followResize = new QCheckBox(
        QStringLiteral("镜像跟随窗口大小（关闭后拖动分隔条可能裁切画面）"), uiBox);
    uiForm->addRow(QStringLiteral("字号"), m_fontSize);
    uiForm->addRow(QString(), m_followResize);
    lay->addWidget(uiBox);

    lay->addStretch(1);
    scroll->setWidget(body);
    root->addWidget(scroll, 1);

    auto *buttons = new QDialogButtonBox(
        QDialogButtonBox::Save | QDialogButtonBox::Cancel | QDialogButtonBox::RestoreDefaults, this);
    root->addWidget(buttons);
    connect(buttons, &QDialogButtonBox::accepted, this, [this]() {
        saveValues();
        accept();
    });
    connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
    connect(buttons->button(QDialogButtonBox::RestoreDefaults), &QPushButton::clicked, this,
            [this]() { applyDefaultsToUi(); });

    connect(adbBtn, &QPushButton::clicked, this, &SettingsDialog::browseAdb);
    connect(scrcpyBtn, &QPushButton::clicked, this, &SettingsDialog::browseScrcpy);
    connect(dirBtn, &QPushButton::clicked, this, &SettingsDialog::browseCaptureDir);

    loadValues();
}

void SettingsDialog::loadValues() {
    const Settings &s = Settings::instance();
    const MirrorOptions m = s.mirror();
    const int sizeIdx = m_maxSize->findData(m.maxSize);
    m_maxSize->setCurrentIndex(sizeIdx >= 0 ? sizeIdx : 2);
    const int fpsIdx = m_maxFps->findData(m.maxFps);
    m_maxFps->setCurrentIndex(fpsIdx >= 0 ? fpsIdx : 2);
    m_bitRate->setValue(m.bitRateMbps);
    const int bufIdx = m_displayBuffer->findData(m.displayBufferMs);
    m_displayBuffer->setCurrentIndex(bufIdx >= 0 ? bufIdx : 0);
    m_stayAwake->setChecked(m.stayAwake);
    m_turnScreenOff->setChecked(m.turnScreenOff);

    const ConnOptions c = s.conn();
    m_autoConnectLast->setChecked(c.autoConnectLast);
    m_reconnectMax->setValue(c.reconnectMax);
    m_reconnectDelay->setValue(c.reconnectDelaySec);

    m_adbPath->setText(s.adbPath());
    m_scrcpyPath->setText(s.scrcpyPath());
    m_captureDir->setText(QDir::toNativeSeparators(s.captureDir()));

    const UiOptions u = s.ui();
    m_fontSize->setValue(u.fontSize);
    m_followResize->setChecked(u.followResize);
}

void SettingsDialog::saveValues() {
    Settings &s = Settings::instance();

    MirrorOptions m;
    m.maxSize = m_maxSize->currentData().toInt();
    m.maxFps = m_maxFps->currentData().toInt();
    m.bitRateMbps = m_bitRate->value();
    m.displayBufferMs = m_displayBuffer->currentData().toInt();
    m.stayAwake = m_stayAwake->isChecked();
    m.turnScreenOff = m_turnScreenOff->isChecked();
    s.setMirror(m);

    ConnOptions c = s.conn();
    c.autoConnectLast = m_autoConnectLast->isChecked();
    c.reconnectMax = m_reconnectMax->value();
    c.reconnectDelaySec = m_reconnectDelay->value();
    s.setConn(c);

    s.setAdbPath(m_adbPath->text().trimmed());
    s.setScrcpyPath(m_scrcpyPath->text().trimmed());
    s.setCaptureDir(m_captureDir->text().trimmed());

    UiOptions u;
    u.fontSize = m_fontSize->value();
    u.followResize = m_followResize->isChecked();
    s.setUi(u);
}

void SettingsDialog::applyDefaultsToUi() {
    const int sizeIdx = m_maxSize->findData(720);
    m_maxSize->setCurrentIndex(sizeIdx);
    m_maxFps->setCurrentIndex(m_maxFps->findData(60));
    m_bitRate->setValue(8);
    m_displayBuffer->setCurrentIndex(0);
    m_stayAwake->setChecked(true);
    m_turnScreenOff->setChecked(false);
    m_autoConnectLast->setChecked(true);
    m_reconnectMax->setValue(6);
    m_reconnectDelay->setValue(3);
    m_adbPath->clear();
    m_scrcpyPath->clear();
    m_captureDir->setText(QDir::toNativeSeparators(Settings::defaultCaptureDir()));
    m_fontSize->setValue(13);
    m_followResize->setChecked(true);
}

void SettingsDialog::browseAdb() {
    const QString p = QFileDialog::getOpenFileName(this, QStringLiteral("选择 adb.exe"),
                                                   m_adbPath->text(),
                                                   QStringLiteral("adb (adb.exe);;可执行文件 (*.exe)"));
    if (!p.isEmpty())
        m_adbPath->setText(QDir::toNativeSeparators(p));
}

void SettingsDialog::browseScrcpy() {
    const QString p = QFileDialog::getOpenFileName(
        this, QStringLiteral("选择 scrcpy.exe"), m_scrcpyPath->text(),
        QStringLiteral("scrcpy (scrcpy.exe);;可执行文件 (*.exe)"));
    if (!p.isEmpty())
        m_scrcpyPath->setText(QDir::toNativeSeparators(p));
}

void SettingsDialog::browseCaptureDir() {
    const QString p = QFileDialog::getExistingDirectory(
        this, QStringLiteral("选择截图与录屏的保存目录"), m_captureDir->text());
    if (!p.isEmpty())
        m_captureDir->setText(QDir::toNativeSeparators(p));
}
