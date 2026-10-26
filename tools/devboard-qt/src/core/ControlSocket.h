#pragma once

#include <QByteArray>
#include <QTcpSocket>

/// control socket：独立于 video socket 的控制通道。
/// 线程约定：本对象归属 control 线程（send 仅在该线程调用）。
/// 视频读循环每帧间不会阻塞本通道的写入。
class ControlSocket : public QObject {
    Q_OBJECT

public:
    explicit ControlSocket(QObject *parent = nullptr) : QObject(parent) {
        m_sock = new QTcpSocket(this);
    }

    /// 连接（在 control 线程内调用，阻塞至连上/超时）
    bool connectToHost(const QString &host, quint16 port,
                       int timeoutMs = 5000) {
        m_sock->connectToHost(host, port);
        return m_sock->waitForConnected(timeoutMs);
    }

    bool isConnected() const {
        return m_sock->state() == QAbstractSocket::ConnectedState;
    }

public slots:
    void send(const QByteArray &msg) {
        if (m_sock->state() == QAbstractSocket::ConnectedState)
            m_sock->write(msg);
    }

private:
    QTcpSocket *m_sock = nullptr;
};
