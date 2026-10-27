#include "Settings.h"

#include <QDir>
#include <QSettings>
#include <QStandardPaths>

QString Settings::defaultCaptureDir() {
    QString base = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (base.isEmpty())
        base = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (base.isEmpty())
        base = QDir::homePath();
    return base + QStringLiteral("/DevBoard");
}

Settings &Settings::instance() {
    static Settings s;
    return s;
}

Settings::Settings() : m_s(new QSettings(QStringLiteral("DevBoard"), QStringLiteral("DevBoard"))) {}

MirrorOptions Settings::mirror() const {
    MirrorOptions o;
    o.maxSize = m_s->value(QStringLiteral("mirror/maxSize"), 720).toInt();
    o.maxFps = m_s->value(QStringLiteral("mirror/maxFps"), 60).toInt();
    o.bitRateMbps = m_s->value(QStringLiteral("mirror/bitRateMbps"), 8).toInt();
    o.stayAwake = m_s->value(QStringLiteral("mirror/stayAwake"), true).toBool();
    o.turnScreenOff = m_s->value(QStringLiteral("mirror/turnScreenOff"), false).toBool();
    return o;
}

ConnOptions Settings::conn() const {
    ConnOptions o;
    o.autoConnectLast = m_s->value(QStringLiteral("conn/autoConnectLast"), true).toBool();
    o.reconnectMax = m_s->value(QStringLiteral("conn/reconnectMax"), 6).toInt();
    o.reconnectDelaySec = m_s->value(QStringLiteral("conn/reconnectDelaySec"), 3).toInt();
    o.lastSerial = m_s->value(QStringLiteral("conn/lastSerial")).toString();
    return o;
}

UiOptions Settings::ui() const {
    UiOptions o;
    o.fontSize = m_s->value(QStringLiteral("ui/fontSize"), 13).toInt();
    o.followResize = m_s->value(QStringLiteral("ui/followResize"), true).toBool();
    return o;
}

QString Settings::adbPath() const {
    return m_s->value(QStringLiteral("paths/adbPath")).toString();
}

QString Settings::scrcpyPath() const {
    return m_s->value(QStringLiteral("paths/scrcpyPath")).toString();
}

QString Settings::captureDir() const {
    const QString v = m_s->value(QStringLiteral("paths/captureDir")).toString();
    return v.isEmpty() ? defaultCaptureDir() : v;
}

QByteArray Settings::windowGeometry() const {
    return m_s->value(QStringLiteral("ui/geometry")).toByteArray();
}

void Settings::setMirror(const MirrorOptions &o) {
    m_s->setValue(QStringLiteral("mirror/maxSize"), o.maxSize);
    m_s->setValue(QStringLiteral("mirror/maxFps"), o.maxFps);
    m_s->setValue(QStringLiteral("mirror/bitRateMbps"), o.bitRateMbps);
    m_s->setValue(QStringLiteral("mirror/stayAwake"), o.stayAwake);
    m_s->setValue(QStringLiteral("mirror/turnScreenOff"), o.turnScreenOff);
}

void Settings::setConn(const ConnOptions &o) {
    m_s->setValue(QStringLiteral("conn/autoConnectLast"), o.autoConnectLast);
    m_s->setValue(QStringLiteral("conn/reconnectMax"), o.reconnectMax);
    m_s->setValue(QStringLiteral("conn/reconnectDelaySec"), o.reconnectDelaySec);
    m_s->setValue(QStringLiteral("conn/lastSerial"), o.lastSerial);
}

void Settings::setUi(const UiOptions &o) {
    m_s->setValue(QStringLiteral("ui/fontSize"), o.fontSize);
    m_s->setValue(QStringLiteral("ui/followResize"), o.followResize);
}

void Settings::setAdbPath(const QString &path) {
    m_s->setValue(QStringLiteral("paths/adbPath"), path);
}

void Settings::setScrcpyPath(const QString &path) {
    m_s->setValue(QStringLiteral("paths/scrcpyPath"), path);
}

void Settings::setCaptureDir(const QString &dir) {
    if (dir.trimmed().isEmpty())
        m_s->remove(QStringLiteral("paths/captureDir")); // 清空 = 回到默认目录
    else
        m_s->setValue(QStringLiteral("paths/captureDir"), dir);
}

void Settings::setWindowGeometry(const QByteArray &geometry) {
    m_s->setValue(QStringLiteral("ui/geometry"), geometry);
}

void Settings::resetAll() {
    m_s->clear();
    m_s->sync();
}
