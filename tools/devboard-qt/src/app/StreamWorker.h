#pragma once

#include <QElapsedTimer>
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

        // adb forward 会先本地 accept 再向设备端建流：app_process 冷启动（约 1-2s）
        // 期间连接会被立即关闭，表现为握手秒断。5s 内重试直到设备端 scrcpy 就绪。
        QElapsedTimer deadline;
        deadline.start();
        VideoSocket video;
        char dummy = 0;
        QByteArray name(64, 0);
        char codecBuf[4] = {0};
        char whBuf[8] = {0};
        bool handshakeOk = false;
        while (!m_stop && deadline.elapsed() < 5000) {
            video.abort(); // 复位旧连接状态（首次为 no-op）
            if (!video.connectToHost(QStringLiteral("127.0.0.1"),
                                     static_cast<quint16>(port))) {
                QThread::msleep(200);
                continue;
            }
            if (m_control) {
                m_control->deleteLater();
                m_control = nullptr;
            }
            // 关键（PLAN A.2）：必须紧接着建 control 连接，否则 server 不发数据
            m_control = new ControlSocket(this);
            if (!m_control->connectToHost(QStringLiteral("127.0.0.1"),
                                          static_cast<quint16>(port))) {
                QThread::msleep(200);
                continue;
            }
            if (video.readExact(&dummy, 1, 2000) && video.readExact(name.data(), 64, 2000)
                && video.readExact(codecBuf, 4, 2000)
                && video.readExact(whBuf, 8, 2000)) {
                handshakeOk = true;
                qDebug() << "[worker] handshake ok, device="
                         << QString::fromUtf8(name).trimmed();
                break;
            }
            QThread::msleep(200); // server 未就绪（握手 EOF），重来
        }
        if (!handshakeOk) {
            emit failed(m_stop ? QStringLiteral("已停止")
                               : QStringLiteral("video 握手失败（5s 内设备端未就绪）"));
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

        // 性能测量：定位 fps 瓶颈（网络等待 / 解码 / 转换）
        QElapsedTimer frameClock;      // 帧头首字节 → 解码完成
        QElapsedTimer perfWindow;      // 3s 汇总窗口
        perfWindow.start();
        int perfFrames = 0;
        qint64 perfBytes = 0;
        qint64 perfWaitMs = 0;  // readExact 阻塞等数据的耗时（网络/编码器侧）
        qint64 perfDecodeMs = 0; // 解码+格式转换耗时
        qint64 perfPtsDeltaMs = 0; // 相邻帧 pts 间隔（编码器输出节奏）
        quint64 lastPtsUs = 0;
        perfWindow.start();

        while (!m_stop) {
            char header[12] = {0};
            frameClock.start();
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
            const qint64 waitMs = frameClock.elapsed();

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
            const quint64 ptsUs = ptsFlags & ((quint64(1) << 62) - 1);
            if (lastPtsUs && ptsUs > lastPtsUs)
                perfPtsDeltaMs += qint64((ptsUs - lastPtsUs) / 1000);
            lastPtsUs = ptsUs;
            if (decoder.feed(payload)) {
                const QImage img = decoder.takeFrame();
                const qint64 latencyMs = frameClock.elapsed(); // 取流→解码完成
                perfFrames++;
                perfBytes += qint64(size) + 12;
                perfWaitMs += waitMs;
                perfDecodeMs += latencyMs - waitMs;
                if (!img.isNull()) {
                    emit bytesReceived(qint64(size) + 12);
                    // 主线程渲染：由 MirrorController 转为信号排队
                    emit frameReady(img, latencyMs);
                }
            }
            if (perfWindow.elapsed() >= 3000) {
                qDebug() << QString::fromUtf8(
                                "[perf] stream fps=%1 kbps=%2 wait=%3ms decode=%4ms ptsΔ=%5ms")
                                .arg(perfFrames * 1000.0 / perfWindow.elapsed(), 0, 'f', 1)
                                .arg(perfBytes * 8 / perfWindow.elapsed())
                                .arg(perfFrames ? perfWaitMs / perfFrames : 0)
                                .arg(perfFrames ? perfDecodeMs / perfFrames : 0)
                                .arg(perfFrames ? perfPtsDeltaMs / perfFrames : 0);
                perfFrames = 0;
                perfBytes = 0;
                perfWaitMs = 0;
                perfDecodeMs = 0;
                perfPtsDeltaMs = 0;
                perfWindow.restart();
            }
        }
        emit statusChanged(QStringLiteral("视频流已结束"));
        m_control->deleteLater();
        m_control = nullptr;
    }

    void requestStop() { m_stop = true; }

signals:
    void frameReady(const QImage &image, qint64 latencyMs);
    void statusChanged(const QString &text);
    void failed(const QString &reason);
    void videoSizeChanged(int width, int height);
    void bytesReceived(qint64 delta);

public slots:
    void sendControl(const QByteArray &msg) {
        if (m_control) m_control->send(msg);
    }

private:
    QAtomicInt m_stop{0};
    ControlSocket *m_control = nullptr;
};
