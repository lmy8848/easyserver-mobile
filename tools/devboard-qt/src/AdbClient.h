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

    // 刷新设备列表（异步）
    void refreshDevices();

    // 在指定设备上执行 shell 命令（异步）
    void shell(const QString &serial, const QString &command);

signals:
    void devicesChanged(const QList<AdbClient::Device> &devices);
    void commandOutput(const QString &text);
    void errorOccurred(const QString &text);

private:
    static QString locateAdb();
    void parseDevices(const QString &out);

    QString m_adbPath;
    bool m_refreshInFlight = false;
};
