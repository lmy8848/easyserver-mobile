#pragma once

#include <QObject>
#include <QString>

#include <windows.h>

class QProcess;
class QTimer;
class QWidget;

// 管理 scrcpy.exe 子进程，并把它的 SDL 窗口嵌进宿主 QWidget。
//
// 为什么走 scrcpy.exe 而不是自研协议：
//  - 本机 Qt Quick 场景图渲染不可用，自研 QImage 显示链路无法出画；
//  - scrcpy.exe 的 SDL 渲染已验证可用，Widgets 宿主渲染也已验证可用；
//  - 用官方客户端把协议/编码/输入复杂度全部接住，壳层只做窗口与设备管理。
//
// 嵌入稳定性约定：启动时按宿主尺寸给 --window-width/--window-height，
// 嵌入后不再改动子窗口尺寸（SDL 重建交换链会破坏渲染），宿主 resize 时只重排位置。
class ScrcpyProcess : public QObject {
    Q_OBJECT
public:
    explicit ScrcpyProcess(QObject *parent = nullptr);
    ~ScrcpyProcess() override;

    void setHost(QWidget *host);
    // 启动参数由 Settings 决定（分辨率/帧率/码率/保持唤醒/关屏）
    void start(const QString &serial);
    void stop();

    // 设置里改了 scrcpy.exe 路径后调用，重新探测
    void reloadExePath();
    QString exePath() const { return m_exePath; }

    // 宿主尺寸变化时同步子窗口（SDL 会收到 resize 并重建交换链）
    void resizeEmbedded(int width, int height);

    bool isRunning() const;
    bool isEmbedded() const { return m_child != nullptr; }
    HWND childHandle() const { return m_child; }

signals:
    void runningChanged(bool running);
    void statusText(const QString &text);
    void errorOccurred(const QString &text);
    // 非用户主动停止（崩溃/设备掉线）时发出，供上层自动重连
    void exitedUnexpectedly(int code);
    // 编码分辨率（scrcpy 收到首帧后打印 "Texture: WxH"）
    void videoSizeChanged(int width, int height);
    // 渲染帧率（--print-fps 每秒打印 "N fps"）
    void fpsChanged(int fps);
    // 每秒被丢掉的帧数（日志里的 "+N frames skipped"），即客户端消费不过来的帧
    void jankChanged(int skippedFrames);

private:
    static QString locateScrcpy();
    void pollForWindow();
    void embedWindow(HWND hwnd);
    // 逐行消费 scrcpy 的日志：既落应用日志，也提取分辨率/帧率
    void consumeLog(QByteArray &buf, const QByteArray &chunk);

    QProcess *m_proc = nullptr;
    QByteArray m_stdoutBuf;
    QByteArray m_stderrBuf;
    QTimer *m_pollTimer = nullptr;
    QWidget *m_host = nullptr;
    HWND m_child = nullptr;
    QString m_exePath;
    QString m_title;
    bool m_userStopped = false;
    // 日志去重：scrcpy 在控制通道拥塞时会连续打印同一条 WARN，
    // 不合并会把应用日志和 UI 拖死
    QString m_lastLogLine;
    qint64 m_lastLogMs = 0;
    int m_repeatCount = 0;
};
