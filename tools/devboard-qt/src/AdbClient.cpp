#include "AdbClient.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QStandardPaths>

AdbClient::AdbClient(QObject *parent) : QObject(parent) {
    m_adbPath = locateAdb();
    qInfo() << "[adb] path=" << m_adbPath;
}

// 探测顺序：环境变量 DEVBOARD_ADB → 仓库内 third_party/scrcpy-win64 下的 adb → PATH
QString AdbClient::locateAdb() {
    const QString env = QProcessEnvironment::systemEnvironment().value(QStringLiteral("DEVBOARD_ADB"));
    if (!env.isEmpty() && QFileInfo(env).isExecutable())
        return env;

    // 从可执行文件向上回溯，找 third_party/scrcpy-win64/*/adb.exe
    QDir dir(QCoreApplication::applicationDirPath());
    for (int i = 0; i < 8; ++i) {
        QDir candidates = dir.absoluteFilePath(QStringLiteral("third_party/scrcpy-win64"));
        if (candidates.exists()) {
            for (const QFileInfo &sub : candidates.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot)) {
                const QString exe = sub.absoluteFilePath() + QStringLiteral("/adb.exe");
                if (QFileInfo::exists(exe))
                    return exe;
            }
        }
        if (!dir.cdUp())
            break;
    }

    // 仓库根也可能持有 scrcpy-win64（开发机摆放差异）
    for (int i = 0; i < 8; ++i) {
        const QString exe = dir.absoluteFilePath(QStringLiteral("adb.exe"));
        if (QFileInfo::exists(exe))
            return exe;
        if (!dir.cdUp())
            break;
    }

    return QStringLiteral("adb"); // 交给 PATH
}

QString AdbClient::adbPath() const { return m_adbPath; }

void AdbClient::refreshDevices() {
    if (m_refreshInFlight)
        return;
    m_refreshInFlight = true;

    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::finished, this, [this, proc](int code, QProcess::ExitStatus) {
        const QString out = QString::fromUtf8(proc->readAllStandardOutput());
        const QString err = QString::fromUtf8(proc->readAllStandardError());
        m_refreshInFlight = false;
        if (code != 0 && !err.trimmed().isEmpty())
            emit errorOccurred(err.trimmed());
        parseDevices(out);
        proc->deleteLater();
    });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError e) {
        m_refreshInFlight = false;
        if (e == QProcess::FailedToStart)
            emit errorOccurred(QStringLiteral("adb 启动失败：%1").arg(m_adbPath));
        proc->deleteLater();
    });
    proc->start(m_adbPath, {QStringLiteral("devices"), QStringLiteral("-l")});
}

// 输出形如：
//   List of devices attached
//   192.168.1.10:39423  device product:... model:M2012K11C device:haydn
// 注意长格式空格对齐 + Windows 换行，按状态关键字定位再取串口
void AdbClient::parseDevices(const QString &out) {
    QList<Device> list;
    static const QRegularExpression re(
        QStringLiteral(R"(^\s*(\S+)\s+(device|offline|unauthorized|no permissions)\s*(.*)$)"));
    const QStringList lines = out.split(QRegularExpression(QStringLiteral("\r?\n")), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        const auto m = re.match(line);
        if (!m.hasMatch())
            continue;
        Device d;
        d.serial = m.captured(1);
        d.state = m.captured(2);
        const QString tail = m.captured(3);
        static const QRegularExpression modelRe(QStringLiteral(R"(model:(\S+))"));
        const auto mm = modelRe.match(tail);
        d.model = mm.hasMatch() ? mm.captured(1) : QString();
        list.append(d);
    }
    emit devicesChanged(list);
}

void AdbClient::shell(const QString &serial, const QString &command) {
    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::finished, this, [this, proc](int, QProcess::ExitStatus) {
        // adb 的输出是 UTF-8；Windows 本地编码是 GBK，用 fromLocal8Bit 会把中文打乱
        const QString out = QString::fromUtf8(proc->readAllStandardOutput());
        const QString err = QString::fromUtf8(proc->readAllStandardError());
        if (!out.isEmpty())
            emit commandOutput(out);
        if (!err.isEmpty())
            emit commandOutput(err);
        proc->deleteLater();
    });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart)
            emit errorOccurred(QStringLiteral("adb 启动失败：%1").arg(m_adbPath));
        proc->deleteLater();
    });
    proc->start(m_adbPath, {QStringLiteral("-s"), serial, QStringLiteral("shell"), command});
}

void AdbClient::pair(const QString &hostPort, const QString &code) {
    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::finished, this, [this, proc, hostPort](int rc, QProcess::ExitStatus) {
        const QString out = QString::fromLocal8Bit(proc->readAllStandardOutput()).trimmed();
        QString err = QString::fromLocal8Bit(proc->readAllStandardError()).trimmed();
        const bool ok = rc == 0 && out.contains(QStringLiteral("Successfully paired"), Qt::CaseInsensitive);
        QString msg = ok ? QStringLiteral("配对成功") : (err.isEmpty() ? out : err);
        if (msg.isEmpty())
            msg = QStringLiteral("配对失败（rc=%1）").arg(rc);
        qInfo() << "[adb] pair" << hostPort << "rc=" << rc << "msg=" << msg;
        emit pairFinished(ok, msg);
        proc->deleteLater();
    });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart)
            emit pairFinished(false, QStringLiteral("adb 启动失败：%1").arg(m_adbPath));
        proc->deleteLater();
    });
    proc->start(m_adbPath, {QStringLiteral("pair"), hostPort, code});
}

void AdbClient::connectDevice(const QString &hostPort) {
    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::finished, this, [this, proc](int rc, QProcess::ExitStatus) {
        const QString out = QString::fromLocal8Bit(proc->readAllStandardOutput()).trimmed();
        const QString err = QString::fromLocal8Bit(proc->readAllStandardError()).trimmed();
        qInfo() << "[adb] connect" << "rc=" << rc << "out=" << out << "err=" << err;
        if (rc == 0 && out.contains(QStringLiteral("connected"), Qt::CaseInsensitive)) {
            refreshDevices();
            emit commandOutput(QStringLiteral("已连接 %1").arg(out));
        } else {
            emit errorOccurred(err.isEmpty() ? out : err);
        }
        proc->deleteLater();
    });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart)
            emit errorOccurred(QStringLiteral("adb 启动失败：%1").arg(m_adbPath));
        proc->deleteLater();
    });
    proc->start(m_adbPath, {QStringLiteral("connect"), hostPort});
}

// adb mdns services 输出形如：
//   List of discovered mdns services
//   adb-XXXXXX-YYYYYY	_adb-tls-connect._tcp.	192.168.1.10:38177
//   adb-XXXXXX-ZZZZZZ	_adb-tls-pairing._tcp.	192.168.1.10:37891
// 正常连接中的设备可能只暴露 connect 服务，配对弹窗打开期间才出现 pairing 服务。
void AdbClient::scanMdns() {
    auto *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    proc->setProcessEnvironment(env);
    connect(proc, &QProcess::finished, this, [this, proc](int rc, QProcess::ExitStatus) {
        QString out = QString::fromLocal8Bit(proc->readAllStandardOutput());
        QString err = QString::fromLocal8Bit(proc->readAllStandardError());
        if (out.trimmed().isEmpty())
            out = err;
        QStringList services;
        for (const QString &raw : out.split(QLatin1Char('\n'))) {
            const QString line = raw.trimmed();
            if (line.isEmpty() || line.startsWith(QStringLiteral("List of")))
                continue;
            // 名字与类型之间是制表符或空格
            static const QRegularExpression re(
                QStringLiteral(R"(^(\S+)\s+(_adb-tls-(pairing|connect)\._tcp\.)\s+(\S+)$)"));
            const auto m = re.match(line);
            if (!m.hasMatch())
                continue;
            const QString kind = m.captured(2);       // pairing / connect
            const QString name = m.captured(1);
            const QString addr = m.captured(3);
            services.append(kind + QLatin1Char('|') + name + QLatin1Char('|') + addr);
        }
        qInfo() << "[adb] mdns services:" << services;
        emit mdnsServices(services);
        proc->deleteLater();
    });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) {
            emit mdnsServices({});
            emit errorOccurred(QStringLiteral("adb 启动失败：%1").arg(m_adbPath));
        }
        proc->deleteLater();
    });
    proc->start(m_adbPath, {QStringLiteral("mdns"), QStringLiteral("services")});
}
