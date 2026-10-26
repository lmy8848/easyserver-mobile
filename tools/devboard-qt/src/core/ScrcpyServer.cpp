#include "ScrcpyServer.h"

#include <QDir>
#include <QRegularExpression>

namespace {
// 与 third_party/scrcpy-server 的版本一致（ADR-006：锁定并常量校验）
constexpr auto kServerVersion = "2.7";
constexpr auto kDeviceJarPath = "/data/local/tmp/scrcpy-server.jar";
constexpr auto kLocalSocket = "localabstract:scrcpy";
} // namespace

ScrcpyServer::ScrcpyServer(QObject *parent) : QObject(parent) {
    // 设备端异常退出时同步给 UI（adb shell 会把远端 stderr 并入 stdout，两路都读）
    connect(&m_shell, &QProcess::finished, this, [this](int code) {
        if (code != 0) {
            const QString stdOut =
                QString::fromUtf8(m_shell.readAllStandardOutput()).trimmed();
            const QString stdErr =
                QString::fromUtf8(m_shell.readAllStandardError()).trimmed();
            emit serverError(QStringLiteral("scrcpy-server 异常退出（%1）：%2%3")
                                 .arg(code)
                                 .arg(stdOut, stdErr));
        }
    });
}

ScrcpyServer::~ScrcpyServer() { stop(); }

bool ScrcpyServer::ensureJarPushed(QString *error) {
    QProcess push;
    push.setProgram(m_adbPath);
    push.setArguments({QStringLiteral("-s"), m_serial, QStringLiteral("push"),
                       m_jarPath, QLatin1String(kDeviceJarPath)});
    push.start();
    if (!push.waitForFinished(15000) || push.exitCode() != 0) {
        if (error)
            *error = QStringLiteral("push scrcpy-server 失败：%1")
                         .arg(QString::fromUtf8(push.readAllStandardError()));
        return false;
    }
    return true;
}

bool ScrcpyServer::start(const QString &serial, int port, QString *error) {
    if (m_jarPath.isEmpty() || !QFileInfo::exists(m_jarPath)) {
        if (error) *error = QStringLiteral("scrcpy-server jar 不存在");
        return false;
    }
    m_serial = serial;

    stop(); // 清理旧实例

    if (!ensureJarPushed(error)) return false;

    // 端口冲突探测：forward 会覆盖同名规则，这里先探测 TCP 可用性
    m_port = port;

    QProcess fwd;
    fwd.setProgram(m_adbPath);
    fwd.setArguments({
        QStringLiteral("-s"), m_serial,
        QStringLiteral("forward"),
        QStringLiteral("tcp:%1").arg(m_port),
        QLatin1String(kLocalSocket),
    });
    fwd.start();
    if (!fwd.waitForFinished(5000) || fwd.exitCode() != 0) {
        if (error) *error = QStringLiteral("adb forward 失败");
        return false;
    }

    // 设备端 server（隧道模式：server 监听 localabstract，客户端经 forward 连入）
    m_shell.setProgram(m_adbPath);
    m_shell.setArguments({
        QStringLiteral("-s"), m_serial,
        QStringLiteral("shell"),
        QStringLiteral("CLASSPATH=%1 app_process / com.genymobile.scrcpy.Server "
                       "%2 log_level=info audio=false video=true max_size=0 "
                       "max_fps=60 video_bit_rate=8000000 "
                       "video_codec_options=low-latency=1,i-frame-interval=2 "
                       "stay_awake=true tunnel_forward=true "
                       "send_device_meta=true send_frame_meta=true "
                       "send_codec_meta=true")
            .arg(QLatin1String(kDeviceJarPath), QLatin1String(kServerVersion)),
    });
    m_shell.start();
    if (!m_shell.waitForStarted(5000)) {
        if (error) *error = QStringLiteral("scrcpy-server 启动失败");
        return false;
    }
    emit serverStarted(m_port);
    return true;
}

void ScrcpyServer::stop() {
    if (m_shell.state() != QProcess::NotRunning) {
        m_shell.kill();
        m_shell.waitForFinished(3000);
    }
    if (!m_serial.isEmpty() && !m_adbPath.isEmpty()) {
        QProcess cleanup;
        cleanup.setProgram(m_adbPath);
        cleanup.setArguments({
            QStringLiteral("-s"), m_serial,
            QStringLiteral("forward"), QStringLiteral("--remove"),
            QStringLiteral("tcp:%1").arg(m_port > 0 ? m_port : 0),
        });
        cleanup.start();
        cleanup.waitForFinished(3000);
    }
    m_port = 0;
}
