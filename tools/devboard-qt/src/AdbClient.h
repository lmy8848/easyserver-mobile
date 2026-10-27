#pragma once

#include <QObject>
#include <QList>
#include <QString>
#include <QStringList>

class QProcess;

// adb 薄封装：设备列表、命令执行。全部异步（QProcess），不阻塞 UI 线程。
class AdbClient : public QObject {
    Q_OBJECT
public:
    struct Device {
        QString serial;
        QString state;   // device / offline / unauthorized
        QString model;
    };

    explicit AdbClient(QObject *parent = nullptr);

    // adb 可执行文件路径（首次探测后缓存）
    QString adbPath() const;

    // 设置里改了 adb.exe 路径后调用，重新探测
    void reloadPath();

    // 刷新设备列表（异步）
    void refreshDevices();

    // 在指定设备上执行 shell 命令（异步）
    void shell(const QString &serial, const QString &command);

    // 无线配对：adb pair <hostPort> <code>，成功后通常还需 adb connect
    void pair(const QString &hostPort, const QString &code);

    // 连接无线设备：adb connect <hostPort>
    void connectDevice(const QString &hostPort);

    // 扫描局域网无线调试服务（adb mdns services）
    void scanMdns();

signals:
    void devicesChanged(const QList<AdbClient::Device> &devices);
    void commandOutput(const QString &text);
    void errorOccurred(const QString &text);
    void pairFinished(bool ok, const QString &message);
    // 每项形如 "pairing|adb-xxx|192.168.1.10:37891" 或 "connect|adb-xxx|192.168.1.10:38177"
    void mdnsServices(const QStringList &services);

private:
    static QString locateAdb();
    void parseDevices(const QString &out);

    QString m_adbPath;
    bool m_refreshInFlight = false;
};
