#pragma once

#include <QObject>
#include <QVariantList>
#include <QStringList>

/// adb 访问层（M0：路径解析 + 设备列表）。
/// adb 探测优先级：随包 bin/scrcpy27/adb.exe → DEVBOARD_ADB 环境变量 → PATH。
class AdbClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QString adbPath READ adbPath CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(QString currentSerial READ currentSerial WRITE setCurrentSerial
                   NOTIFY currentSerialChanged)

public:
    explicit AdbClient(QObject *parent = nullptr);

    bool ready() const { return m_ready; }
    QString adbPath() const { return m_adbPath; }
    bool busy() const { return m_busy; }
    QVariantList devices() const { return m_devices; }
    QString currentSerial() const { return m_currentSerial; }
    void setCurrentSerial(const QString &serial);

    // QML 可直接调用的设备命令
    Q_INVOKABLE void refreshDevices();
    Q_INVOKABLE void connectWireless(const QString &hostPort);
    Q_INVOKABLE void runCommand(const QString &args);

    /// 静态定位（供非 QML 模块复用，如 MirrorController）
    static QString locateAdb();

signals:
    void readyChanged();
    void busyChanged();
    void devicesChanged();
    void currentSerialChanged();
    void commandOutput(const QString &text);
    void error(const QString &message);

private:
    QString resolveAdb();
    void runAdb(const QStringList &args);

    QString m_adbPath;
    bool m_ready = false;
    bool m_busy = false;
    QVariantList m_devices;
    QString m_currentSerial;
};
