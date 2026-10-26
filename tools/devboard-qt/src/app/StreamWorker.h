#pragma once

#include <QThread>
#include <QTcpSocket>
#include <QtEndian>

#include "../core/ControlSocket.h"
#include "../core/ScrcpyServer.h"
#include "../core/VideoSocket.h"
#include "../media/FfmpegDecoder.h"

/// IO 线程 worker：阻塞读 video socket → 解码 → 产出 QImage。
/// 任何环节不缓冲（背压策略见 PLAN §3.3）。
class StreamWorker : public QObject {
    Q_OBJECT

public:
    explicit StreamWorker(QObject *parent = nullptr) : QObject(parent) {}

public slots:
    /// 在 QThread 中执行（阻塞直到停止/失败）
    void run(const QString &serial, int port) {
        emit statusChanged(QStringLiteral("连接 video socket…"));

        VideoSocket video;
        if (!video.connectToHost(QStringLiteral("127.0.0.1"),
                                 static_cast<quint16>(port))) {
            emit failed(QStringLiteral("video socket 连接失败（forward 未生效？）"));
            return;
        }
        // 关键（PLAN A.2）：必须紧接着建 control 连接，否则 server 不发数据
        m_control = new ControlSocket(this);
        if (!m_control->connectToHost(QStringLiteral("127.0.0.1"),
                                      static_cast<quint16>(port))) {
            emit failed(QStringLiteral("control socket 连接失败"));
            return;
        }
        emit statusChanged(QStringLiteral("读取握手…"));

        char dummy = 0;
        QByteArray name(64, 0);
        char codecBuf[4] = {0};
        char whBuf[8] = {0};
        if (!video.readExact(&dummy, 1) || !video.readExact(name.data(), 64)
            || !video.readExact(codecBuf, 4) || !video.readExact(whBuf, 8)) {
            emit failed(QStringLiteral("video 握手读取失败"));
            return;
        }
        const QString deviceName =
            QString::fromUtf8(name).trimmed();
        quint32 codec = 0, w = 0, h = 0;
        memcpy(&codec, codecBuf, 4);
        memcpy(&w, whBuf, 4);
        memcpy(&h, whBuf + 4, 4);
        codec = qFromBigEndian(codec);
        w = qFromBigEndian(w);
        h = qFromBigEndian(h);
        emit videoSizeChanged(static_cast<int>(w), static_cast<int>(h));
        emit statusChanged(QStringLiteral("%1 · %2x%3")
                               .arg(deviceName)
                               .arg(w)
                               .arg(h));

        FfmpegDecoder decoder;
        QByteArray extradata; // CONFIG 包（SPS/PPS）
        bool decoderOpen = false;
        m_stop = false;

        while (!m_stop) {
            char header[12] = {0};
            if (!video.readExact(header, 12)) break;
            const quint64 ptsFlags = qFromBigEndian<quint64>(
                reinterpret_cast<const uchar *>(header));
            const quint32 size = qFromBigEndian<quint32>(
                reinterpret_cast<const uchar *>(header + 8));
            if (size == 0 || size > 32 * 1024 * 1024) {
                emit failed(QStringLiteral("异常帧大小 %1").arg(size));
                break;
            }
            QByteArray payload(size, 0);
            if (!video.readExact(payload.data(), size)) break;

            const bool isConfig = (ptsFlags >> 63) & 1;
            if (isConfig) {
                if (!decoderOpen) {
                    extradata = payload;
                    decoderOpen = decoder.open(extradata);
                    if (!decoderOpen) {
                        emit failed(QStringLiteral("解码器初始化失败"));
                        break;
                    }
                    emit statusChanged(QStringLiteral("解码器就绪"));
                }
                continue; // CONFIG 不是画面帧
            }
            if (!decoderOpen) continue; // 等到 CONFIG 再开解码器
            if (decoder.feed(payload)) {
                const QImage img = decoder.takeFrame();
                if (!img.isNull()) {
                    // 主线程渲染：由 MirrorController 转为信号排队
                    emit frameReady(img);
                }
            }
        }
        emit statusChanged(QStringLiteral("视频流已结束"));
        m_control->deleteLater();
        m_control = nullptr;
    }

    void requestStop() { m_stop = true; }

signals:
    void frameReady(const QImage &image);
    void statusChanged(const QString &text);
    void failed(const QString &reason);
    void videoSizeChanged(int width, int height);

public slots:
    void sendControl(const QByteArray &msg) {
        if (m_control) m_control->send(msg);
    }

private:
    QAtomicInt m_stop{0};
    ControlSocket *m_control = nullptr;
};
