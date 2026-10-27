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
    void start(const QString &serial, int maxSize = 720, int maxFps = 60);
    void stop();

    bool isRunning() const;
    bool isEmbedded() const { return m_child != nullptr; }

signals:
    void runningChanged(bool running);
    void statusText(const QString &text);
    void errorOccurred(const QString &text);

private:
    static QString locateScrcpy();
    void pollForWindow();
    void embedWindow(HWND hwnd);

    QProcess *m_proc = nullptr;
    QTimer *m_pollTimer = nullptr;
    QWidget *m_host = nullptr;
    HWND m_child = nullptr;
    QString m_exePath;
    QString m_title;
};
