#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

/// scrcpy-server 生命周期管理：push jar → app_process 启动 → adb forward。
/// server 进程常驻（隧道模式），stop 时结束并清理 forward。
class ScrcpyServer : public QObject {
    Q_OBJECT

public:
    explicit ScrcpyServer(QObject *parent = nullptr);
    ~ScrcpyServer() override;

    /// jar 路径（third_party/scrcpy-server，随包分发）
    void setJarPath(const QString &path) { m_jarPath = path; }
    void setAdbPath(const QString &path) { m_adbPath = path; }

    /// push jar → 启动 app_process → 建立 forward。
    /// 成功后客户端可对 127.0.0.1:port 发起 video/control 两条连接。
    bool start(const QString &serial, int port, QString *error = nullptr);
    void stop();

    static constexpr int kBasePort = 27183;
    static constexpr int kPortSpan = 32; // 27183..27214 冲突时顺延

signals:
    void serverStarted(int port);
    void serverError(const QString &message);

private:
    bool ensureJarPushed(QString *error);

    QProcess m_shell; // 设备端 app_process（常驻）
    QString m_serial;
    QString m_jarPath;
    QString m_adbPath;
    int m_port = 0;
};
