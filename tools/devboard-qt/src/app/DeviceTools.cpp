#include "DeviceTools.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QStandardPaths>

namespace {
constexpr int kLogMaxLines = 4000; // logcat 原始行缓冲上限
} // namespace

DeviceTools::DeviceTools(QObject *parent) : QObject(parent) {}

QStringList DeviceTools::baseArgs(const QString &serial) const {
    return {QStringLiteral("-s"), serial};
}

void DeviceTools::setActionStatus(const QString &text) {
    if (m_actionStatus == text) return;
    m_actionStatus = text;
    emit actionStatusChanged();
}

// ───────────── 终端（交互式 adb shell） ─────────────

void DeviceTools::shellStart(const QString &serial) {
    if (m_adb.isEmpty() || serial.isEmpty()) return;
    shellStop();
    m_shell = new QProcess(this);
    m_shell->setProgram(m_adb);
    m_shell->setArguments(baseArgs(serial) << QStringLiteral("shell"));
    m_shell->setProcessChannelMode(QProcess::MergedChannels);
    connect(m_shell, &QProcess::readyRead, this,
            [this] { appendShell(m_shell->readAll()); });
    connect(m_shell, &QProcess::finished, this, [this](int code, QProcess::ExitStatus) {
        appendShell(QStringLiteral("\n[shell 退出 code=%1]\n").arg(code).toUtf8());
        sender()->deleteLater();
        if (m_shell == sender()) {
            m_shell = nullptr;
            emit shellRunningChanged();
        }
    });
    m_shell->start();
    emit shellRunningChanged();
}

void DeviceTools::shellStop() {
    if (!m_shell) return;
    m_shell->kill();
    m_shell->waitForFinished(500);
    if (m_shell) {
        m_shell->deleteLater();
        m_shell = nullptr;
        emit shellRunningChanged();
    }
}

void DeviceTools::shellSend(const QString &line) {
    if (!m_shell) return;
    m_shell->write((line + QLatin1Char('\n')).toUtf8());
}

void DeviceTools::shellClear() { emit shellViewReset(); }

void DeviceTools::appendShell(const QByteArray &chunk) {
    QString s = QString::fromUtf8(chunk);
    s.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    s.replace(QLatin1Char('\r'), QLatin1Char('\n'));
    emit shellAppended(s);
}

// ───────────── 日志（logcat 流式） ─────────────

void DeviceTools::logcatStart(const QString &serial) {
    if (m_adb.isEmpty() || serial.isEmpty()) return;
    logcatStop();
    m_logcat = new QProcess(this);
    m_logcat->setProgram(m_adb);
    m_logcat->setArguments(baseArgs(serial) << QStringLiteral("logcat")
                                            << QStringLiteral("-v")
                                            << QStringLiteral("time"));
    m_logcat->setProcessChannelMode(QProcess::MergedChannels);
    connect(m_logcat, &QProcess::readyRead, this,
            [this] { feedLogLines(m_logcat->readAll()); });
    connect(m_logcat, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        sender()->deleteLater();
        if (m_logcat == sender()) {
            m_logcat = nullptr;
            emit logcatRunningChanged();
        }
    });
    m_logcat->start();
    emit logcatRunningChanged();
}

void DeviceTools::logcatStop() {
    if (!m_logcat) return;
    m_logcat->kill();
    m_logcat->waitForFinished(500);
    if (m_logcat) {
        m_logcat->deleteLater();
        m_logcat = nullptr;
        emit logcatRunningChanged();
    }
}

void DeviceTools::logcatClear() {
    m_logRaw.clear();
    emit logViewReset();
}

void DeviceTools::setLogPaused(bool paused) {
    if (m_logPaused == paused) return;
    m_logPaused = paused;
    emit logPausedChanged();
}

void DeviceTools::setLogFilter(const QString &filter) {
    if (m_logFilter == filter) return;
    m_logFilter = filter;
    emit logViewReset(); // QML 侧用 logText() 重建视图
}

QString DeviceTools::logText() const {
    QString out;
    for (const QString &l : m_logRaw) {
        if (!m_logFilter.isEmpty() && !l.contains(m_logFilter, Qt::CaseInsensitive))
            continue;
        out += l + QLatin1Char('\n');
    }
    return out;
}

void DeviceTools::feedLogLines(const QByteArray &chunk) {
    m_logPending += chunk;
    QString newLines;
    int idx;
    while ((idx = m_logPending.indexOf('\n')) >= 0) {
        QByteArray line = m_logPending.left(idx);
        m_logPending.remove(0, idx + 1);
        if (line.endsWith('\r')) line.chop(1);
        const QString s = QString::fromUtf8(line);
        m_logRaw << s;
        if (m_logRaw.size() > kLogMaxLines) m_logRaw.removeFirst();
        if (m_logPaused) continue;
        if (!m_logFilter.isEmpty() && !s.contains(m_logFilter, Qt::CaseInsensitive))
            continue;
        newLines += s + QLatin1Char('\n');
    }
    if (!newLines.isEmpty()) emit logAppended(newLines);
}

// ───────────── 一次性动作（info / 截图 / 录制 / 安装…） ─────────────

void DeviceTools::refreshInfo(const QString &serial) {
    if (m_action) return; // 后台刷新不抢占显式操作
    startAction(QStringLiteral("info"),
                baseArgs(serial) << QStringLiteral("shell")
                                 << QStringLiteral(
                                        "getprop ro.product.brand; getprop "
                                        "ro.product.model; getprop ro.product.device; "
                                        "getprop ro.build.version.release; getprop "
                                        "ro.build.version.sdk; getprop "
                                        "ro.build.version.incremental; getprop "
                                        "ro.product.cpu.abi; echo ---; wm size; wm "
                                        "density; echo ---; dumpsys battery"),
                QStringLiteral("读取设备信息…"));
}

void DeviceTools::screenshot(const QString &serial) {
    startAction(QStringLiteral("shot"),
                baseArgs(serial) << QStringLiteral("exec-out")
                                 << QStringLiteral("screencap")
                                 << QStringLiteral("-p"),
                QStringLiteral("截图…"));
}

void DeviceTools::recordScreen(const QString &serial) {
    m_recordRemote = QStringLiteral("/sdcard/devboard_rec.mp4");
    startAction(QStringLiteral("record"),
                baseArgs(serial) << QStringLiteral("shell")
                                 << QStringLiteral(
                                        "screenrecord --time-limit 30 "
                                        "/sdcard/devboard_rec.mp4"),
                QStringLiteral("录制中（30 秒，完成后自动回传）…"));
}

void DeviceTools::installApk(const QString &serial, const QUrl &file) {
    const QString path = file.toLocalFile();
    if (path.isEmpty()) return;
    startAction(QStringLiteral("install"),
                baseArgs(serial) << QStringLiteral("install")
                                 << QStringLiteral("-r") << path,
                QStringLiteral("安装中（大包可能需要数十秒）…"));
}

void DeviceTools::uninstallApk(const QString &serial, const QString &packageName) {
    const QString pkg = packageName.trimmed();
    if (pkg.isEmpty()) return;
    startAction(QStringLiteral("uninstall"),
                baseArgs(serial) << QStringLiteral("uninstall") << pkg,
                QStringLiteral("卸载 ") + pkg + QStringLiteral(" …"));
}

void DeviceTools::listPackages(const QString &serial) {
    startAction(QStringLiteral("packages"),
                baseArgs(serial) << QStringLiteral("shell")
                                 << QStringLiteral("pm list packages -3"),
                QStringLiteral("列出第三方应用…"));
}

void DeviceTools::startAction(const QString &kind, const QStringList &args,
                              const QString &runningText) {
    if (m_action) {
        setActionStatus(QStringLiteral("有任务进行中，请稍候"));
        return;
    }
    m_actionKind = kind;
    m_actionSerial = args.value(1);
    setActionStatus(runningText);
    m_action = new QProcess(this);
    m_action->setProgram(m_adb);
    m_action->setArguments(args);
    connect(m_action, &QProcess::finished, this,
            [this](int code, QProcess::ExitStatus) {
                QProcess *p = qobject_cast<QProcess *>(sender());
                const QByteArray out = p ? p->readAllStandardOutput() : QByteArray();
                const QByteArray err = p ? p->readAllStandardError() : QByteArray();
                if (p) p->deleteLater();
                m_action = nullptr;
                emit actionBusyChanged();
                const QString kind = m_actionKind;
                m_actionKind.clear();
                handleActionFinished(kind, code, out, err);
            });
    connect(m_action, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        setActionStatus(QStringLiteral("adb 启动失败（错误码 %1）").arg(int(e)));
        m_action->deleteLater();
        m_action = nullptr;
        m_actionKind.clear();
        emit actionBusyChanged();
    });
    m_action->start();
    emit actionBusyChanged();
}

void DeviceTools::handleActionFinished(const QString &kind, int code,
                                       const QByteArray &out, const QByteArray &err) {
    const QString text = QString::fromUtf8(out).trimmed();
    const QString errText = QString::fromUtf8(err).trimmed();
    if (kind == QLatin1String("info")) {
        m_infoText = text.isEmpty() ? errText : formatInfo(text);
        emit infoTextChanged();
        setActionStatus(code == 0 ? QStringLiteral("设备信息已更新")
                                  : QStringLiteral("读取失败"));
        return;
    }
    if (kind == QLatin1String("packages")) {
        QStringList pkgs;
        const QStringList lines = text.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &l : lines) {
            const QString t = l.trimmed();
            if (t.startsWith(QLatin1String("package:"))) pkgs << t.mid(8);
        }
        pkgs.sort();
        m_packages = pkgs;
        emit packagesChanged();
        setActionStatus(QStringLiteral("共 %1 个第三方应用").arg(pkgs.size()));
        return;
    }
    if (kind == QLatin1String("shot")) {
        static const QByteArray kPngMagic("\x89PNG\r\n\x1a\n", 8);
        if (!out.startsWith(kPngMagic)) {
            setActionStatus(QStringLiteral("截图失败：") +
                            (text.isEmpty() ? errText : text.left(200)));
            return;
        }
        const QString dir = QStandardPaths::writableLocation(
                                QStandardPaths::PicturesLocation) +
                            QStringLiteral("/DevBoard");
        QDir().mkpath(dir);
        const QString path =
            dir + QStringLiteral("/shot-%1.png")
                      .arg(QDateTime::currentDateTime().toString(
                          QStringLiteral("yyyyMMdd-HHmmss")));
        QFile f(path);
        if (!f.open(QIODevice::WriteOnly)) {
            setActionStatus(QStringLiteral("截图保存失败：") + path);
            return;
        }
        f.write(out);
        f.close();
        setActionStatus(QStringLiteral("截图已保存：") + path);
        emit savedToPath(path);
        return;
    }
    if (kind == QLatin1String("record")) {
        if (code != 0 && text.isEmpty() && errText.isEmpty()) {
            setActionStatus(QStringLiteral("录制失败"));
            return;
        }
        m_recordLocal =
            QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) +
            QStringLiteral("/DevBoard/rec-%1.mp4")
                .arg(QDateTime::currentDateTime().toString(
                    QStringLiteral("yyyyMMdd-HHmmss")));
        startAction(QStringLiteral("pull"),
                    {QStringLiteral("-s"), m_actionSerial, QStringLiteral("pull"),
                     m_recordRemote, m_recordLocal},
                    QStringLiteral("拉取录像…"));
        return;
    }
    if (kind == QLatin1String("pull")) {
        setActionStatus(code == 0 ? QStringLiteral("录像已保存：") + m_recordLocal
                                  : QStringLiteral("录像回传失败"));
        if (code == 0 && !m_recordRemote.isEmpty()) {
            auto *rm = new QProcess(this);
            rm->setProgram(m_adb);
            rm->setArguments({QStringLiteral("-s"), m_actionSerial,
                              QStringLiteral("shell"),
                              QStringLiteral("rm -f ") + m_recordRemote});
            connect(rm, &QProcess::finished, rm, &QObject::deleteLater);
            rm->start();
        }
        return;
    }
    if (kind == QLatin1String("install")) {
        const bool ok = text.contains(QLatin1String("Success"));
        setActionStatus(ok ? QStringLiteral("安装成功")
                           : QStringLiteral("安装失败：") +
                                 (text.isEmpty() ? errText : text));
        return;
    }
    if (kind == QLatin1String("uninstall")) {
        const bool ok = text.contains(QLatin1String("Success"));
        setActionStatus(ok ? QStringLiteral("卸载成功")
                           : QStringLiteral("卸载失败：") +
                                 (text.isEmpty() ? errText : text));
        return;
    }
}

QString DeviceTools::formatInfo(const QString &raw) const {
    QStringList lines;
    for (const QString &l : raw.split(QLatin1Char('\n')))
        lines << l.trimmed();
    if (lines.size() < 8) return raw;

    QString out;
    out += QStringLiteral("品牌型号  %1 %2 (%3)\n").arg(lines[0], lines[1], lines[2]);
    out += QStringLiteral("系统版本  Android %1 (SDK %2)\n").arg(lines[3], lines[4]);
    out += QStringLiteral("构建号    %1\n").arg(lines[5]);
    out += QStringLiteral("ABI       %1\n").arg(lines[6]);

    QString size, density, level, status, temp;
    int dashes = 0;
    for (int i = 7; i < lines.size(); ++i) {
        const QString &l = lines[i];
        if (l == QLatin1String("---")) {
            ++dashes;
            continue;
        }
        if (dashes == 1) {
            if (l.startsWith(QLatin1String("Physical size"))) size = l;
            else if (l.startsWith(QLatin1String("Override size")))
                size += QStringLiteral(" · ") + l;
            else if (l.startsWith(QLatin1String("Physical density"))) density = l;
            else if (l.startsWith(QLatin1String("Override density")))
                density += QStringLiteral(" · ") + l;
        } else if (dashes >= 2) {
            if (l.startsWith(QLatin1String("level:"))) level = l.mid(6).trimmed();
            else if (l.startsWith(QLatin1String("status:")))
                status = l.mid(7).trimmed();
            else if (l.startsWith(QLatin1String("temperature:")))
                temp = l.mid(12).trimmed();
        }
    }
    out += QStringLiteral("分辨率    %1\n").arg(size);
    out += QStringLiteral("密度      %1\n").arg(density);
    if (!level.isEmpty()) {
        QString st;
        if (status == QLatin1String("2")) st = QStringLiteral("充电中");
        else if (status == QLatin1String("3")) st = QStringLiteral("放电中");
        else if (status == QLatin1String("4")) st = QStringLiteral("未充电");
        else if (status == QLatin1String("5")) st = QStringLiteral("已充满");
        else st = QStringLiteral("状态码 ") + status;
        const QString t = temp.isEmpty()
                              ? QStringLiteral("?")
                              : QString::number(temp.toInt() / 10.0, 'f', 1);
        out += QStringLiteral("电量      ") + level + QStringLiteral("% · ") + st +
               QStringLiteral(" · 电池温度 ") + t + QStringLiteral("°C");
    }
    return out;
}
