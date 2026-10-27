#include "ScrcpyProcess.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QProcessEnvironment>
#include <QTimer>
#include <QWidget>

static const wchar_t *kWindowTitle = L"DevBoard Mirror";

ScrcpyProcess::ScrcpyProcess(QObject *parent) : QObject(parent) {
    m_exePath = locateScrcpy();
    m_title = QString::fromWCharArray(kWindowTitle);
    qInfo() << "[scrcpy] exe=" << m_exePath;
}

ScrcpyProcess::~ScrcpyProcess() { stop(); }

void ScrcpyProcess::setHost(QWidget *host) { m_host = host; }

// 探测顺序：DEVBOARD_SCRCPY → 仓库内 third_party/scrcpy-win64/*/scrcpy.exe
QString ScrcpyProcess::locateScrcpy() {
    const QString env = QProcessEnvironment::systemEnvironment().value(QStringLiteral("DEVBOARD_SCRCPY"));
    if (!env.isEmpty() && QFileInfo(env).isExecutable())
        return env;

    QDir dir(QCoreApplication::applicationDirPath());
    for (int i = 0; i < 8; ++i) {
        QDir candidates = dir.absoluteFilePath(QStringLiteral("third_party/scrcpy-win64"));
        if (candidates.exists()) {
            for (const QFileInfo &sub : candidates.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot)) {
                const QString exe = sub.absoluteFilePath() + QStringLiteral("/scrcpy.exe");
                if (QFileInfo::exists(exe))
                    return exe;
            }
        }
        if (!dir.cdUp())
            break;
    }
    return QStringLiteral("scrcpy");
}

bool ScrcpyProcess::isRunning() const {
    return m_proc && m_proc->state() != QProcess::NotRunning;
}

void ScrcpyProcess::start(const QString &serial, int maxSize, int maxFps) {
    if (isRunning()) {
        emit statusText(QStringLiteral("镜像已在运行"));
        return;
    }
    if (m_exePath.isEmpty() || (m_exePath != QStringLiteral("scrcpy") && !QFileInfo::exists(m_exePath))) {
        emit errorOccurred(QStringLiteral("找不到 scrcpy.exe，已探测：%1").arg(m_exePath));
        return;
    }

    // 窗口尺寸直接用宿主尺寸：嵌入时 MoveWindow 与启动尺寸一致，
    // SDL 不会收到 resize（resize 会重建交换链导致重影/黑屏）。
    // 视频比例由 scrcpy 自己 letterbox。
    int w = 720, h = 1600;
    if (m_host && m_host->width() > 80 && m_host->height() > 80) {
        w = m_host->width();
        h = m_host->height();
    }

    QStringList args{
        QStringLiteral("-s"), serial,
        QStringLiteral("--max-size=%1").arg(maxSize),
        QStringLiteral("--max-fps=%1").arg(maxFps),
        QStringLiteral("--stay-awake"),
        QStringLiteral("--no-audio"),
        QStringLiteral("--window-borderless"),
        // 先在屏幕外创建：scrcpy 的窗口是独立顶层窗口，嵌入完成前会单独露出来，
        // 放到屏幕外等嵌入时再 MoveWindow 进宿主，用户就只看到主窗口。
        QStringLiteral("--window-x=-32000"),
        QStringLiteral("--window-y=-32000"),
        QStringLiteral("--window-title=%1").arg(m_title),
        QStringLiteral("--window-width=%1").arg(w),
        QStringLiteral("--window-height=%1").arg(h),
    };

    m_proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("MSYS_NO_PATHCONV"), QStringLiteral("1"));
    m_proc->setProcessEnvironment(env);
    m_proc->setWorkingDirectory(QFileInfo(m_exePath).absolutePath());

    connect(m_proc, &QProcess::readyReadStandardOutput, this, [this]() {
        const QString out = QString::fromLocal8Bit(m_proc->readAllStandardOutput()).trimmed();
        if (!out.isEmpty())
            emit statusText(out);
    });
    connect(m_proc, &QProcess::readyReadStandardError, this, [this]() {
        const QString err = QString::fromLocal8Bit(m_proc->readAllStandardError()).trimmed();
        if (!err.isEmpty())
            emit errorOccurred(err);
    });
    connect(m_proc, &QProcess::finished, this, [this](int code, QProcess::ExitStatus) {
        qInfo() << "[scrcpy] exited code=" << code;
        m_child = nullptr;
        if (m_pollTimer)
            m_pollTimer->stop();
        emit runningChanged(false);
        emit statusText(QStringLiteral("scrcpy 已退出（code=%1）").arg(code));
    });
    connect(m_proc, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart)
            emit errorOccurred(QStringLiteral("scrcpy 启动失败：%1").arg(m_exePath));
    });

    qInfo() << "[scrcpy] starting:" << m_exePath << args.join(QLatin1Char(' '));
    m_proc->start(m_exePath, args);

    if (!m_pollTimer) {
        m_pollTimer = new QTimer(this);
        m_pollTimer->setInterval(100);
        connect(m_pollTimer, &QTimer::timeout, this, &ScrcpyProcess::pollForWindow);
    }
    m_pollTimer->start();

    emit runningChanged(true);
    emit statusText(QStringLiteral("scrcpy 启动中…"));
}

struct EnumCtx {
    DWORD pid;
    const wchar_t *title;
    HWND found;
};

static BOOL CALLBACK enumProc(HWND hwnd, LPARAM lParam) {
    auto *ctx = reinterpret_cast<EnumCtx *>(lParam);
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != ctx->pid)
        return TRUE;
    if (!IsWindowVisible(hwnd))
        return TRUE;

    wchar_t buf[256] = {0};
    GetWindowTextW(hwnd, buf, 255);
    // 标题精确匹配我们指定的窗口，避免误抓 Ctrl 隐藏窗口
    if (wcscmp(buf, ctx->title) != 0)
        return TRUE;

    ctx->found = hwnd;
    return FALSE;
}

void ScrcpyProcess::pollForWindow() {
    if (m_child || !isRunning())
        return;
    EnumCtx ctx{m_proc->processId(), kWindowTitle, nullptr};
    EnumWindows(enumProc, LPARAM(&ctx));
    if (ctx.found) {
        embedWindow(ctx.found);
        m_pollTimer->stop();
    }
}

void ScrcpyProcess::embedWindow(HWND hwnd) {
    if (!m_host) {
        emit errorOccurred(QStringLiteral("宿主窗口未设置，无法嵌入"));
        return;
    }

    ShowWindow(hwnd, SW_HIDE);

    // 子窗口不该出现在任务栏里；嵌入期间保持隐藏
    LONG exStyle = GetWindowLongW(hwnd, GWL_EXSTYLE);
    exStyle = (exStyle | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW;
    SetWindowLongW(hwnd, GWL_EXSTYLE, exStyle);

    // 去弹窗/标题栏/边框，改成子窗口样式后 SetParent
    LONG style = GetWindowLongW(hwnd, GWL_STYLE);
    style &= ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_SYSMENU);
    style |= WS_CHILD;
    SetWindowLongW(hwnd, GWL_STYLE, style);

    SetParent(hwnd, reinterpret_cast<HWND>(m_host->winId()));
    const int w = qMax(1, m_host->width());
    const int h = qMax(1, m_host->height());
    MoveWindow(hwnd, 0, 0, w, h, TRUE);
    ShowWindow(hwnd, SW_SHOW);

    m_child = hwnd;
    qInfo() << "[scrcpy] embedded hwnd=" << (quintptr)hwnd << "size=" << QSize(w, h);
    emit statusText(QStringLiteral("镜像已嵌入"));
}

void ScrcpyProcess::stop() {
    if (m_pollTimer)
        m_pollTimer->stop();

    if (m_child) {
        // 先解除父子关系，否则 scrcpy 退出时窗口析构顺序可能触发宿主重绘异常
        SetParent(m_child, nullptr);
        m_child = nullptr;
    }
    if (isRunning()) {
        qInfo() << "[scrcpy] stopping";
        m_proc->terminate();
        if (!m_proc->waitForFinished(2000))
            m_proc->kill();
        m_proc->waitForFinished(1000);
    }
    if (m_proc) {
        m_proc->deleteLater();
        m_proc = nullptr;
    }
    emit runningChanged(false);
}
