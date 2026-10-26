#include "MirrorController.h"

#include <QCoreApplication>

#include "../core/AdbClient.h"
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
}

void MirrorController::connectTo(const QString &serial) {
    if (m_running || serial.isEmpty()) return;
    m_serial = serial;

    m_server = new ScrcpyServer(this);
    m_server->setAdbPath(m_adbPath.isEmpty() ? AdbClient::locateAdb()
                                             : m_adbPath);
    m_server->setJarPath(m_jarPath);
    QString err;
    const int port = 27183; // 冲突时 forward 覆盖；见 PLAN 补充建议 1
    if (!m_server->start(serial, port, &err)) {
        m_status = err.isEmpty() ? QStringLiteral("server 启动失败") : err;
        emit statusChanged(m_status);
        m_server->deleteLater();
        m_server = nullptr;
        return;
    }
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
    emit frameSeqChanged();
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
