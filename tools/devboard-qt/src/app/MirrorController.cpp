#include "MirrorController.h"

#include <QCoreApplication>

#include "../core/AdbClient.h"
#include <QDateTime>

#include "../core/ControlMsg.h"
#include <QDir>

MirrorController::MirrorController(QObject *parent) : QObject(parent) {
    // jar 与 adb 路径由 main 装配；这里兜底一次回溯
    QDir dir(QCoreApplication::applicationDirPath());
    for (int i = 0; i < 8 && m_jarPath.isEmpty(); ++i) {
        const QString candidate =
            dir.absolutePath() + QStringLiteral(
                                     "/tools/devboard-qt/third_party/"
                                     "scrcpy-server");
        if (QFileInfo::exists(candidate)) m_jarPath = candidate;
        if (!dir.cdUp()) break;
    }
    m_provider = new MirrorImageProvider();
    // 保持亮屏：独立于视频流的定时唤醒（息屏时镜像只会得到黑帧）
    m_wakeTimer = new QTimer(this);
    m_wakeTimer->setInterval(3000);
    connect(m_wakeTimer, &QTimer::timeout, this, [this]() {
        if (m_stopping || m_serial.isEmpty()) return;
        AdbClient::ensureAwake(m_serial);
    });
    m_wakeTimer->start();
}

void MirrorController::setAdbClient(QObject *adb) {
    m_adb = adb;
    // adb 串口选出后自动连接镜像；设备列表变化兜底（3s 轮询 → 掉线重连）
    connect(m_adb, SIGNAL(currentSerialChanged()), this,
            SLOT(onAdbSerialChanged()), Qt::QueuedConnection);
    connect(m_adb, SIGNAL(devicesChanged()), this,
            SLOT(onAdbDevicesChanged()), Qt::QueuedConnection);
}

bool MirrorController::isSerialOnline(const QString &serial) const {
    const QVariantList devices = m_adb->property("devices").toList();
    for (const auto &v : devices) {
        const auto map = v.toMap();
        if (map.value(QStringLiteral("serial")).toString() == serial
            && map.value(QStringLiteral("online")).toBool())
            return true;
    }
    return false;
}

void MirrorController::onAdbSerialChanged() {
    if (!m_autoConnect || m_running) return;
    const QString serial = m_adb->property("currentSerial").toString();
    if (serial.isEmpty()) return;
    // 换目标 = 新意图，重试预算清零
    m_retries = 0;
    // 设备必须真实在线才连接（恢复持久化串口时设备可能尚未上线，交给 devicesChanged 兜底）
    if (!isSerialOnline(serial)) {
        qDebug() << "[mirror] serial selected but offline yet:" << serial;
        return;
    }
    qDebug() << "[mirror] auto-connect to" << serial;
    connectTo(serial);
}

void MirrorController::onAdbDevicesChanged() {
    if (!m_autoConnect || m_running || m_userStopped) return;
    const QString serial = m_adb->property("currentSerial").toString();
    if (serial.isEmpty()) return;
    if (!isSerialOnline(serial)) {
        if (m_retries != 0) {
            m_retries = 0; // 设备离线；重新上线时给满额重试预算
            qDebug() << "[mirror] device offline, retry budget reset:" << serial;
        }
        return;
    }
    if (m_retries >= 6) {
        const QString paused =
            QStringLiteral("自动重连暂停（重试预算用尽）· 检查手机后点「连接镜像」");
        if (m_status != paused) {
            m_status = paused;
            emit statusChanged(m_status);
        }
        return;
    }
    qDebug() << "[mirror] auto-connect attempt" << (m_retries + 1) << "/6 to" << serial;
    connectTo(serial);
}

void MirrorController::connectTo(const QString &serial) {
    qDebug() << "[connect] begin serial=" << serial
             << "retries=" << m_retries << "userStopped=" << m_userStopped;
    if (m_running || serial.isEmpty()) return;
    m_serial = serial;
    m_userStopped = false;
    qDebug() << "[connect] server create, jar=" << m_jarPath;

    m_server = new ScrcpyServer(this);
    // 设备端 scrcpy 异常退出时给出诊断（编码器参数错误等 Java 侧报错都在 stderr）
    connect(m_server, &ScrcpyServer::serverError, this,
            [this](const QString &msg) {
                qDebug() << "[connect] server error:" << msg;
                m_status = msg;
                emit statusChanged(m_status);
            });
    m_server->setAdbPath(m_adbPath.isEmpty() ? AdbClient::locateAdb()
                                             : m_adbPath);
    m_server->setJarPath(m_jarPath);
    QString err;
    const int port = 27183; // 冲突时 forward 覆盖；见 PLAN 补充建议 1
    qDebug() << "[connect] server.start...";
    if (!m_server->start(serial, port, &err)) {
        qDebug() << "[connect] server failed:" << err;
        ++m_retries;
        m_status = err.isEmpty() ? QStringLiteral("server 启动失败") : err;
        emit statusChanged(m_status);
        m_server->deleteLater();
        m_server = nullptr;
        return;
    }
    qDebug() << "[connect] server ok, creating worker...";
    // 注意：server 启动成功≠流可用，重试预算在 onFrameReady（真正出帧）时清零
    m_firstFrameLogged = false;
    m_running = true;
    emit runningChanged(true);
    m_status = QStringLiteral("连接 video/control socket…");
    emit statusChanged(m_status);

    m_worker = new StreamWorker();
    m_ioThread = new QThread(this);
    m_worker->moveToThread(m_ioThread);
    connect(m_ioThread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_worker, &StreamWorker::frameReady, this,
            &MirrorController::onFrameReady, Qt::QueuedConnection);    connect(m_worker, &StreamWorker::statusChanged, this,
            &MirrorController::onWorkerStatus, Qt::QueuedConnection);
    connect(m_worker, &StreamWorker::failed, this,
            &MirrorController::onWorkerFailed, Qt::QueuedConnection);
    connect(m_worker, &StreamWorker::bytesReceived, this,
            [this](qint64 delta) { m_statBytes += delta; },
            Qt::QueuedConnection);
    connect(m_worker, &StreamWorker::videoSizeChanged, this,
            [this](int w, int h) {
                m_videoW = w;
                m_videoH = h;
                emit videoSizeChanged();
            },
            Qt::QueuedConnection);
    connect(this, &MirrorController::controlMessage, m_worker,
            &StreamWorker::sendControl, Qt::QueuedConnection);
    m_ioThread->start();
    qDebug() << "[connect] io thread started, invoking run...";
    // 阻塞读循环在 IO 线程运行
    QMetaObject::invokeMethod(m_worker, "run", Qt::QueuedConnection,
                              Q_ARG(QString, serial), Q_ARG(int, port));
}

void MirrorController::disconnect() {
    if (!m_running) return;
    m_userStopped = true; // 手动断开：停止自动重连，直至下一次连接意图
    stopAll(QStringLiteral("已断开"));
}

void MirrorController::stopAll(const QString &finalStatus) {
    m_worker->requestStop();
    m_server->stop(); // 杀 shell → video socket EOF → 读循环自然退出
    m_ioThread->quit();
    m_ioThread->wait(5000);
    m_server->deleteLater();
    m_server = nullptr;
    m_worker = nullptr;
    m_running = false;
    emit runningChanged(false);
    m_status = finalStatus;
    emit statusChanged(m_status);
}

void MirrorController::onFrameReady(const QImage &img, qint64 latencyMs) {
    m_retries = 0; // 有真帧流入 = 会话健康，重试预算清零
    if (!m_firstFrameLogged) {
        m_firstFrameLogged = true;
        qDebug() << "[mirror] first frame decoded" << img.size();
    }
    m_provider->setLast(img);
    // UI 节流（40fps 上限，须小于流帧间隔，否则会把显示帧率砍半）：
    // 帧照常解码（provider 永远持有最新），每次重绘直接取最新帧。
    const QDateTime uiNow = QDateTime::currentDateTime();
    if (!m_lastUiEmit.isValid() || m_lastUiEmit.msecsTo(uiNow) >= 25) {
        m_lastUiEmit = uiNow;
        ++m_frameSeq;
        emit frameSeqChanged(); // 驱动 QML Image 重新请求 provider（缺失即黑屏）
    } else {
        ++m_uiDropped;
    }
    m_statLatencyMs += int(latencyMs);

    // fps / 码率统计（1s 滑动窗口）
    ++m_statFrames;
    const QDateTime now = QDateTime::currentDateTime();
    if (m_statStart.isNull()) m_statStart = now;
    const qint64 ms = m_statStart.msecsTo(now);
    if (ms >= 1000) {
        m_fps = qRound(m_statFrames * 1000.0 / ms);
        m_bitrateKbps = qRound(m_statBytes * 8.0 / ms);
        m_latencyMs = m_statFrames ? m_statLatencyMs / m_statFrames : 0;
        qDebug() << QString::fromUtf8("[perf] ui fps=%1 kbps=%2 latency=%3ms dropped=%4")
                        .arg(m_fps)
                        .arg(m_bitrateKbps)
                        .arg(m_latencyMs)
                        .arg(m_uiDropped);
        m_statFrames = 0;
        m_statBytes = 0;
        m_statLatencyMs = 0;
        m_uiDropped = 0;
        m_statStart = now;
        emit statsChanged();
    }
}

void MirrorController::onWorkerStatus(const QString &text) {
    m_status = text;
    emit statusChanged(m_status);
}

void MirrorController::onWorkerFailed(const QString &reason) {
    qDebug() << "[mirror] worker failed:" << reason << "retries so far:" << m_retries;
    ++m_retries; // 由 devicesChanged 轮询按预算重试（不算用户主动断开）
    if (m_running) stopAll(reason);
}

void MirrorController::injectTouchDown(double xNorm, double yNorm) {
    emit controlMessage(ControlMsg::buildInjectTouchEvent(
        ControlMsg::ACTION_DOWN, ControlMsg::POINTER_ID_MOUSE, xNorm, yNorm));
}

void MirrorController::injectTouchMove(double xNorm, double yNorm) {
    emit controlMessage(ControlMsg::buildInjectTouchEvent(
        ControlMsg::ACTION_MOVE, ControlMsg::POINTER_ID_MOUSE, xNorm, yNorm));
}

void MirrorController::injectTouchUp(double xNorm, double yNorm) {
    emit controlMessage(ControlMsg::buildInjectTouchEvent(
        ControlMsg::ACTION_UP, ControlMsg::POINTER_ID_MOUSE, xNorm, yNorm));
}

void MirrorController::injectKeycode(int keycode) {
    emit controlMessage(ControlMsg::buildInjectKeycode(
        ControlMsg::ACTION_DOWN, keycode));
    emit controlMessage(ControlMsg::buildInjectKeycode(
        ControlMsg::ACTION_UP, keycode));
}

void MirrorController::injectText(const QString &text) {
    emit controlMessage(ControlMsg::buildInjectText(text));
}

void MirrorController::injectScroll(double xNorm, double yNorm, int steps) {
    emit controlMessage(ControlMsg::buildInjectScroll(xNorm, yNorm, steps));
}
