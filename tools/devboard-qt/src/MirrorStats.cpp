#include "MirrorStats.h"

#include "AdbClient.h"

#include <QHostAddress>
#include <QProcess>
#include <QRegularExpression>
#include <QTimer>
#include <QUdpSocket>

namespace {
// 在设备上找到 scrcpy server 进程并打印它的 io 计数。
// ps 的 NAME 列只给出 app_process，需要再对比 /proc/<pid>/cmdline 才认出是 scrcpy。
const char *kIoScript =
    "for p in $(ps -A -o PID,NAME | awk '$2==\"app_process\"{print $1}'); do "
    "grep -qa scrcpy /proc/$p/cmdline && { cat /proc/$p/io; break; }; done";
} // namespace

MirrorStats::MirrorStats(AdbClient *adb, QObject *parent)
    : QObject(parent), m_adb(adb) {
    m_ioTimer = new QTimer(this);
    m_ioTimer->setInterval(1000);
    connect(m_ioTimer, &QTimer::timeout, this, &MirrorStats::sampleIo);

    m_rttTimer = new QTimer(this);
    m_rttTimer->setInterval(5000);
    connect(m_rttTimer, &QTimer::timeout, this, &MirrorStats::sampleRtt);
}

void MirrorStats::setSerial(const QString &serial) {
    if (serial == m_serial && m_ioTimer->isActive())
        return;
    clear();
    m_serial = serial;
    if (m_serial.isEmpty())
        return;
    m_ioTimer->start();
    m_rttTimer->start();
    QTimer::singleShot(1500, this, &MirrorStats::sampleRtt);
}

void MirrorStats::clear() {
    m_ioTimer->stop();
    m_rttTimer->stop();
    if (m_ioProc) {
        m_ioProc->disconnect(this);
        m_ioProc->kill();
        m_ioProc->deleteLater();
        m_ioProc = nullptr;
    }
    if (m_rttProc) {
        m_rttProc->disconnect(this);
        m_rttProc->kill();
        m_rttProc->deleteLater();
        m_rttProc = nullptr;
    }
    m_serial.clear();
    m_lastWchar = -1;
    m_firstWchar = -1;
    m_totalBytes = 0;
    m_kbps = 0;
    m_rttMs = -1;
    m_valid = false;
    emit changed();
}

QString MirrorStats::pcAddress() const {
    // UDP connect 只做路由查询，不发包；拿到的本机地址就是手机看到的那一侧地址。
    const QString host = m_serial.section(QLatin1Char(':'), 0, 0);
    if (host.isEmpty())
        return QString();
    QUdpSocket sock;
    sock.connectToHost(host, 9);
    if (!sock.waitForConnected(100))
        return QString();
    const QHostAddress addr = sock.localAddress();
    return addr.isNull() ? QString() : addr.toString();
}

void MirrorStats::sampleIo() {
    if (m_serial.isEmpty() || m_ioProc || !m_adb)
        return;

    auto *p = new QProcess(this);
    m_ioProc = p;
    connect(p, &QProcess::finished, this, [this, p](int rc, QProcess::ExitStatus st) {
        const QByteArray out = p->readAllStandardOutput();
        p->deleteLater();
        if (m_ioProc == p)
            m_ioProc = nullptr;
        if (st != QProcess::NormalExit || rc != 0 || out.isEmpty()) {
            m_valid = false;
            emit changed();
            return;
        }
        static const QRegularExpression wcharRe(QStringLiteral("^wchar:\\s*(\\d+)"),
                                                QRegularExpression::MultilineOption);
        const auto m = wcharRe.match(QString::fromLatin1(out));
        if (!m.hasMatch()) {
            m_valid = false;
            emit changed();
            return;
        }
        const qint64 wchar = m.captured(1).toLongLong();
        if (m_firstWchar < 0)
            m_firstWchar = wchar;
        if (m_lastWchar >= 0 && wchar >= m_lastWchar) {
            // 采样间隔约 1s，固定按 1000ms 折算，避免调度抖动把数字放大缩小。
            m_kbps = static_cast<int>((wchar - m_lastWchar) * 8 / 1000);
        }
        m_lastWchar = wchar;
        m_totalBytes = wchar - m_firstWchar;
        m_valid = true;
        emit changed();
    });
    p->start(m_adb->adbPath(),
             {QStringLiteral("-s"), m_serial, QStringLiteral("shell"),
              QString::fromLatin1(kIoScript)});
    QTimer::singleShot(3000, p, [p]() {
        if (p->state() != QProcess::NotRunning)
            p->kill();
    });
}

void MirrorStats::sampleRtt() {
    if (m_serial.isEmpty() || m_rttProc || !m_adb)
        return;
    const QString pc = pcAddress();
    if (pc.isEmpty())
        return;

    auto *p = new QProcess(this);
    m_rttProc = p;
    connect(p, &QProcess::finished, this, [this, p](int, QProcess::ExitStatus) {
        const QString out = QString::fromUtf8(p->readAllStandardOutput());
        p->deleteLater();
        if (m_rttProc == p)
            m_rttProc = nullptr;
        const QRegularExpression re(
            QStringLiteral("rtt min/avg/max/mdev = [\\d.]+/([\\d.]+)/"));
        const auto m = re.match(out);
        if (m.hasMatch()) {
            m_rttMs = qRound(m.captured(1).toDouble());
            emit changed();
        }
    });
    p->start(m_adb->adbPath(),
             {QStringLiteral("-s"), m_serial, QStringLiteral("shell"),
              QStringLiteral("ping -c 1 -W 1 %1").arg(pc)});
    QTimer::singleShot(4000, p, [p]() {
        if (p->state() != QProcess::NotRunning)
            p->kill();
    });
}
