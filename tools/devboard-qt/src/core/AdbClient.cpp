#include "AdbClient.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>

namespace {

QStringList adbRoots() {
    QStringList roots;
    // 1) 可执行文件所在目录向上找 tools/devboard/bin/scrcpy27
    QDir dir(QCoreApplication::applicationDirPath());
    for (int i = 0; i < 8; ++i) {
        roots << dir.absolutePath();
        if (!dir.cdUp()) break;
        dir = dir;
    }
    return roots;
}

} // namespace

AdbClient::AdbClient(QObject *parent) : QObject(parent) {
    resolveAdb();
    refreshDevices();
}

QString AdbClient::locateAdb() {
    static QString cached; // 进程内缓存（adb 路径运行期不变）
    if (!cached.isEmpty()) return cached;
    const auto env = qEnvironmentVariable("DEVBOARD_ADB");
    QStringList candidates;
    // 随包 adb（tools/devboard/bin/scrcpy27/adb.exe）
    for (const auto &root : adbRoots()) {
        candidates << root + "/tools/devboard/bin/scrcpy27/adb.exe";
        candidates << root + "/bin/scrcpy27/adb.exe";
    }
    candidates << env;
    candidates << QStringLiteral("adb.exe");

    for (const auto &c : candidates) {
        if (c.isEmpty()) continue;
        QProcess p;
        p.start(c, {QStringLiteral("version")});
        if (p.waitForFinished(5000) && p.exitCode() == 0) {
            cached = c;
            return cached;
        }
    }
    return {};
}

void AdbClient::ensureAwake(const QString &serial) {
    const QString adb = locateAdb();
    if (adb.isEmpty()) return;
    auto *p = new QProcess();
    p->setProgram(adb);
    p->setArguments({
        QStringLiteral("-s"), serial, QStringLiteral("shell"),
        QStringLiteral("dumpsys power | grep mWakefulness= | grep -q Awake || "
                       "input keyevent KEYCODE_WAKEUP"),
    });
    connect(p, &QProcess::finished, p, &QProcess::deleteLater);
    p->start();
}

QString AdbClient::resolveAdb() {
    if (!m_adbPath.isEmpty()) return m_adbPath;
    const QString found = locateAdb();
    if (found.isEmpty()) {
        emit error(QStringLiteral("未找到 adb.exe，请设置环境变量 DEVBOARD_ADB"));
        return {};
    }
    m_adbPath = found;
    m_ready = true;
    emit readyChanged();
    return m_adbPath;
}

void AdbClient::runAdb(const QStringList &args) {
    if (m_busy) return;
    const QString adb = resolveAdb();
    if (adb.isEmpty()) return;

    m_busy = true;
    emit busyChanged();

    auto *proc = new QProcess(this);
    proc->setProgram(adb);
    QStringList full = args;
    if (!m_currentSerial.isEmpty() && args.first() != QLatin1String("devices")
        && args.first() != QLatin1String("pair")) {
        full.prepend(m_currentSerial);
        full.prepend(QStringLiteral("-s"));
    }
    proc->setArguments(full);
    connect(proc, &QProcess::finished, this,
            [this, proc](int code, QProcess::ExitStatus) {
                const QString out =
                    QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
                const QString err =
                    QString::fromUtf8(proc->readAllStandardError()).trimmed();
                if (!out.isEmpty()) emit commandOutput(out);
                if (!err.isEmpty()) emit commandOutput(QStringLiteral("ERR: ") + err);
                proc->deleteLater();
                m_busy = false;
                emit busyChanged();
                if (code != 0 && err.isEmpty() && out.isEmpty())
                    emit commandOutput(QStringLiteral("(无输出)"));
            });
    proc->start();
}

void AdbClient::refreshDevices() {
    if (m_busy) return;
    const QString adb = resolveAdb();
    if (adb.isEmpty()) return;

    m_busy = true;
    emit busyChanged();

    auto *proc = new QProcess(this);
    proc->setProgram(adb);
    proc->setArguments({QStringLiteral("devices"), QStringLiteral("-l")});
    connect(proc, &QProcess::finished, this, [this, proc](int, QProcess::ExitStatus) {
        const QString out =
            QString::fromUtf8(proc->readAllStandardOutput());
        proc->deleteLater();

        QVariantList list;
        static const QRegularExpression lineRe(
            QStringLiteral("^(\\S+)\\s+(device|offline|unauthorized)\\b"));
        const auto uaRe = QRegularExpression(QStringLiteral("model:(\\S+)"));
        for (const QString &line : out.split(QRegularExpression(QStringLiteral("\r?\n")))) {
            const auto m = lineRe.match(line.trimmed());
            if (!m.hasMatch()) continue;
            const QString serial = m.captured(1);
            const QString state = m.captured(2);
            const QString model = uaRe.match(line).hasMatch()
                                      ? uaRe.match(line).captured(1)
                                      : serial;
            QVariantMap e;
            e.insert(QStringLiteral("serial"), serial);
            e.insert(QStringLiteral("state"), state);
            e.insert(QStringLiteral("model"), state == QLatin1String("device") ? model : serial);
            e.insert(QStringLiteral("online"), state == QLatin1String("device"));
            list.append(e);
        }
        m_devices = list;
        emit devicesChanged();

        // 自动选择：优先在线的 IP 型串口（无线），否则第一个在线设备
        if (m_currentSerial.isEmpty()
            || !std::any_of(m_devices.cbegin(), m_devices.cend(),
                            [this](const QVariant &v) {
                                return v.toMap().value(QStringLiteral("serial"))
                                       == m_currentSerial;
                            })) {
            QString pick;
            for (const auto &v : m_devices) {
                const auto map = v.toMap();
                if (map.value(QStringLiteral("online")).toBool()) {
                    if (pick.isEmpty()) pick = map.value(QStringLiteral("serial")).toString();
                    if (map.value(QStringLiteral("serial")).toString().contains(
                            QLatin1Char(':'))) {
                        pick = map.value(QStringLiteral("serial")).toString();
                        break;
                    }
                }
            }
            if (!pick.isEmpty()) setCurrentSerial(pick);
        }

        m_busy = false;
        emit busyChanged();
    });
    proc->start();
}

void AdbClient::connectWireless(const QString &hostPort) {
    if (m_busy || hostPort.isEmpty()) return;
    m_busy = true;
    emit busyChanged();

    auto *proc = new QProcess(this);
    proc->setProgram(resolveAdb());
    proc->setArguments({QStringLiteral("connect"), hostPort});
    connect(proc, &QProcess::finished, this, [this, proc, hostPort](int,
                                                           QProcess::ExitStatus) {
        const QString out = QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
        proc->deleteLater();
        m_busy = false;
        emit busyChanged();
        if (out.contains(QLatin1String("connected"))) {
            m_currentSerial = hostPort;
            emit currentSerialChanged();
        }
        emit commandOutput(out.isEmpty() ? QStringLiteral("已发起连接 ") + hostPort : out);
        refreshDevices();
    });
    proc->start();
}

void AdbClient::pairWireless(const QString &hostPort, const QString &code) {
    if (m_busy || hostPort.isEmpty() || code.isEmpty()) return;
    m_busy = true;
    emit busyChanged();

    auto *proc = new QProcess(this);
    proc->setProgram(resolveAdb());
    proc->setArguments({QStringLiteral("pair"), hostPort, code});
    connect(proc, &QProcess::finished, this,
            [this, proc, hostPort](int, QProcess::ExitStatus) {
                const QString out =
                    QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
                const QString err =
                    QString::fromUtf8(proc->readAllStandardError()).trimmed();
                proc->deleteLater();
                m_busy = false;
                emit busyChanged();
                const bool ok = out.contains(QLatin1String("Success"));
                emit pairFinished(ok, ok ? QStringLiteral("配对成功 ") + hostPort
                                         : (out.isEmpty() ? err : out));
            });
    proc->start();
}

void AdbClient::mdnsScan() {
    if (m_busy) return;
    m_busy = true;
    emit busyChanged();

    auto *proc = new QProcess(this);
    proc->setProgram(resolveAdb());
    proc->setArguments({QStringLiteral("mdns"), QStringLiteral("services")});
    connect(proc, &QProcess::finished, this, [this, proc](int, QProcess::ExitStatus) {
        const QString out = QString::fromUtf8(proc->readAllStandardOutput());
        const QString err = QString::fromUtf8(proc->readAllStandardError());
        proc->deleteLater();
        m_busy = false;
        emit busyChanged();

        QStringList entries;
        static const QRegularExpression re(
            QStringLiteral("(\\S+\\._adb-tls-(?:pairing|connect)\\._tcp)"
                           "\\s+(\\d+\\.\\d+\\.\\d+\\.\\d+:\\d+)"));
        auto it = re.globalMatch(out);
        while (it.hasNext()) {
            const auto m = it.next();
            const QString name = m.captured(1);
            const QString addr = m.captured(2);
            const QString kind = name.contains(QLatin1String("pairing"))
                                     ? QStringLiteral("pairing")
                                     : QStringLiteral("connect");
            entries << kind + QLatin1Char('|') + name + QLatin1Char('|') + addr;
        }
        emit mdnsServices(entries);
        if (entries.isEmpty()) {
            const QString raw = out.trimmed().isEmpty() ? err.trimmed() : out.trimmed();
            emit commandOutput(QStringLiteral("mDNS 未发现配对/连接服务") +
                               (raw.isEmpty() ? QString() : QStringLiteral("：") + raw));
        }
    });
    proc->start();
}

void AdbClient::runCommand(const QString &args) {
    const QString trimmed = args.trimmed();
    if (trimmed.isEmpty()) return;
    runAdb(trimmed.split(QRegularExpression(QStringLiteral("\\s+"))));
}

void AdbClient::setCurrentSerial(const QString &serial) {
    if (m_currentSerial == serial) return;
    m_currentSerial = serial;
    emit currentSerialChanged();
}
