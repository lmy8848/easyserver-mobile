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
    // adb 串口选出后自动连接镜像
    connect(m_adb, SIGNAL(currentSerialChanged()), this,
            SLOT(onAdbSerialChanged()), Qt::QueuedConnection);
}

void MirrorController::onAdbSerialChanged() {
    if (!m_autoConnect || m_running) return;
    const QString serial = m_adb->property("currentSerial").toString();
    if (serial.isEmpty()) return;
    qDebug() << "[mirror] auto-connect to" << serial;
    connectTo(serial);
}

void MirrorController::connectTo(const QString &serial) {
    qDebug() << "[connect] begin serial=" << serial;
    if (m_running || serial.isEmpty()) return;
    m_serial = serial;
    qDebug() << "[connect] server create, jar=" << m_jarPath;

    m_server = new ScrcpyServer(this);
    m_server->setAdbPath(m_adbPath.isEmpty() ? AdbClient::locateAdb()
                                             : m_adbPath);
    m_server->setJarPath(m_jarPath);
    QString err;
    const int port = 27183; // 冲突时 forward 覆盖；见 PLAN 补充建议 1
    qDebug() << "[connect] server.start...";
    if (!m_server->start(serial, port, &err)) {
        qDebug() << "[connect] server failed:" << err;
        m_status = err.isEmpty() ? QStringLiteral("server 启动失败") : err;
        emit statusChanged(m_status);
        m_server->deleteLater();
        m_server = nullptr;
        return;
    }
    qDebug() << "[connect] server ok, creating worker...";
    m_running = true;
    emit runningChanged(true);
    m_status = QStringLiteral("连接 video/control socket…");
    emit statusChanged(m_status);

    m_worker = new StreamWorker();
    m_ioThread = new QThread(this);
    m_worker->moveToThread(m_ioThread);
    connect(m_ioThread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_worker, &StreamWorker::frameReady, this,
            &MirrorController::onFrameReady, Qt::QueuedConnection);
    connect(m_worker, &StreamWorker::statusChanged, this,
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
    m_worker->requestStop();
    m_server->stop(); // 杀 shell → video socket EOF → 读循环自然退出
    m_ioThread->quit();
    m_ioThread->wait(5000);
    m_server->deleteLater();
    m_server = nullptr;
    m_worker = nullptr;
    m_running = false;
    emit runningChanged(false);
    m_status = QStringLiteral("已断开");
    emit statusChanged(m_status);
}

void MirrorController::onFrameReady(const QImage &img) {
    m_provider->setLast(img);
    ++m_frameSeq;

    // fps / 码率统计（1s 滑动窗口）
    ++m_statFrames;
    const QDateTime now = QDateTime::currentDateTime();
    if (m_statStart.isNull()) m_statStart = now;
    const qint64 ms = m_statStart.msecsTo(now);
    if (ms >= 1000) {
        m_fps = qRound(m_statFrames * 1000.0 / ms);
        m_bitrateKbps = qRound(m_statBytes * 8.0 / ms);
        m_statFrames = 0;
        m_statBytes = 0;
        m_statStart = now;
        emit statsChanged();
    }
}

void MirrorController::onWorkerStatus(const QString &text) {
    m_status = text;
    emit statusChanged(m_status);
}

void MirrorController::onWorkerFailed(const QString &reason) {
    m_status = reason;
    emit statusChanged(m_status);
    disconnect();
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
