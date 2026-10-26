#pragma once

#include <QTcpSocket>

/// video socket：阻塞式精确读（在 IO 线程使用，配合 waitFor*）。
/// 协议（scrcpy 2.7，tunnel_forward，PLAN 附录 A.3/A.4）：
/// 握手 = 1B dummy + 64B 设备名 + 4B codec + 4B 宽 + 4B 高；
/// 每帧 = 8B pts|flags + 4B size + payload。
class VideoSocket : public QObject {
    Q_OBJECT

public:
    explicit VideoSocket(QObject *parent = nullptr) : QObject(parent) {
        m_sock = new QTcpSocket(this);
    }

    QTcpSocket *socket() const { return m_sock; }

    bool connectToHost(const QString &host, quint16 port,
                       int timeoutMs = 5000) {
        m_sock->connectToHost(host, port);
        return m_sock->waitForConnected(timeoutMs);
    }

    bool readExact(char *buf, qint64 n) {
        qint64 got = 0;
        while (got < n) {
            if (m_sock->state() != QAbstractSocket::ConnectedState) return false;
            if (!m_sock->waitForReadyRead(10000)) {
                if (m_sock->error() == QAbstractSocket::SocketTimeoutError)
                    continue;
                return false;
            }
            const qint64 r = m_sock->read(buf + got, n - got);
            if (r <= 0) {
                if (m_sock->error() == QAbstractSocket::SocketTimeoutError)
                    continue;
                return false;
            }
            got += r;
        }
        return true;
    }

    void abort() { m_sock->abort(); }

private:
    QTcpSocket *m_sock = nullptr;
};
