#pragma once

#include <QObject>
#include <QThread>

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

public:
    explicit MirrorController(QObject *parent = nullptr);

    void setAdbPath(const QString &path) { m_adbPath = path; }
    void setJarPath(const QString &path) { m_jarPath = path; }

    Q_INVOKABLE void connectTo(const QString &serial);
    Q_INVOKABLE void disconnect();

    int frameSeq() const { return m_frameSeq; }
    QString status() const { return m_status; }
    bool running() const { return m_running; }

    MirrorImageProvider *imageProvider() const { return m_provider; }

signals:
    void frameSeqChanged();
    void statusChanged(const QString &text);
    void runningChanged(bool running);

private slots:
    void onFrameReady(const QImage &img);
    void onWorkerStatus(const QString &text);
    void onWorkerFailed(const QString &reason);

private:
    void stopAll(const QString &finalStatus);

    ScrcpyServer *m_server = nullptr;
    MirrorImageProvider *m_provider = nullptr;
    QThread *m_ioThread = nullptr;
    StreamWorker *m_worker = nullptr;
    QString m_adbPath;
    QString m_jarPath;
    QString m_serial;
    QString m_status = QStringLiteral("未连接");
    int m_frameSeq = 0;
    bool m_running = false;
};
