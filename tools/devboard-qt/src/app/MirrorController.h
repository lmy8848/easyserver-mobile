#pragma once

#include <QObject>
#include <QThread>
#include <QTimer>

#include "MirrorImageProvider.h"
#include "StreamWorker.h"
#include "../core/ScrcpyServer.h"

/// 编排：scrcpy-server → sockets → IO 线程解码 → 帧回传 UI。
/// QML 接口：connectTo(serial) / disconnect() / status / frameSeq。
class MirrorController : public QObject {
    Q_OBJECT
    Q_PROPERTY(int frameSeq READ frameSeq NOTIFY frameSeqChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool autoConnect READ autoConnect WRITE setAutoConnect NOTIFY autoConnectChanged)
    Q_PROPERTY(int videoWidth READ videoWidth NOTIFY videoSizeChanged)
    Q_PROPERTY(int videoHeight READ videoHeight NOTIFY videoSizeChanged)
    Q_PROPERTY(int fps READ fps NOTIFY statsChanged)
    Q_PROPERTY(int bitrateKbps READ bitrateKbps NOTIFY statsChanged)

public:
    explicit MirrorController(QObject *parent = nullptr);

    void setAdbPath(const QString &path) { m_adbPath = path; }
    void setJarPath(const QString &path) { m_jarPath = path; }

    Q_INVOKABLE void connectTo(const QString &serial);
    Q_INVOKABLE void disconnect();

    void setAdbClient(QObject *adb);

    // 输入注入（QML 以归一化坐标调用，控制 socket 直达设备，<5ms）
    Q_INVOKABLE void injectTouchDown(double xNorm, double yNorm);
    Q_INVOKABLE void injectTouchMove(double xNorm, double yNorm);
    Q_INVOKABLE void injectTouchUp(double xNorm, double yNorm);
    Q_INVOKABLE void injectKeycode(int keycode);
    Q_INVOKABLE void injectText(const QString &text);
    Q_INVOKABLE void injectScroll(double xNorm, double yNorm, int steps);

    bool autoConnect() const { return m_autoConnect; }
    void setAutoConnect(bool on) { m_autoConnect = on; }
    int videoWidth() const { return m_videoW; }
    int videoHeight() const { return m_videoH; }
    int fps() const { return m_fps; }
    int bitrateKbps() const { return m_bitrateKbps; }

    int frameSeq() const { return m_frameSeq; }
    QString status() const { return m_status; }
    bool running() const { return m_running; }

    MirrorImageProvider *imageProvider() const { return m_provider; }

signals:
    void frameSeqChanged();
    void statusChanged(const QString &text);
    void runningChanged(bool running);
    void videoSizeChanged();
    void autoConnectChanged();
    void controlMessage(const QByteArray &msg);
    void statsChanged();

private slots:
    void onFrameReady(const QImage &img);
    void onAdbSerialChanged();
    void onAdbDevicesChanged();
    void onWorkerStatus(const QString &text);
    void onWorkerFailed(const QString &reason);

private:
    void stopAll(const QString &finalStatus);
    bool isSerialOnline(const QString &serial) const;

    QObject *m_adb = nullptr;
    ScrcpyServer *m_server = nullptr;
    MirrorImageProvider *m_provider = nullptr;
    QThread *m_ioThread = nullptr;
    StreamWorker *m_worker = nullptr;
    QTimer *m_wakeTimer = nullptr;
    bool m_stopping = false;
    bool m_autoConnect = true;
    bool m_userStopped = false; // 手动断开后不再自动重连，直至新的连接意图
    int m_retries = 0;          // 自动重试预算：设备每次重新上线时清零
    QString m_adbPath;
    QString m_jarPath;
    QString m_serial;
    QString m_status = QStringLiteral("未连接");
    int m_frameSeq = 0;
    int m_videoW = 0;
    int m_videoH = 0;
    int m_fps = 0;
    int m_bitrateKbps = 0;
    int m_statFrames = 0;
    bool m_firstFrameLogged = false;
    qint64 m_statBytes = 0;
    QDateTime m_statStart;
    bool m_running = false;
};
