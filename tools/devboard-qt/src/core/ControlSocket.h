#pragma once

#include <QTcpSocket>

/// control socket（M1：仅保持连接——server 必须两条连接都接入才会发数据）。
/// M3 扩展：INJECT_TOUCH/KEYCODE/TEXT/SCROLL 消息序列化（PLAN 附录 A.5）。
class ControlSocket : public QObject {
    Q_OBJECT

public:
    explicit ControlSocket(QObject *parent = nullptr) : QObject(parent) {
        m_sock = new QTcpSocket(this);
    }

    QTcpSocket *socket() const { return m_sock; }

    bool connectToHost(const QString &host, quint16 port,
                       int timeoutMs = 5000) {
        m_sock->connectToHost(host, port);
        return m_sock->waitForConnected(timeoutMs);
    }

    void abort() { m_sock->abort(); }

private:
    QTcpSocket *m_sock = nullptr;
};
