#pragma once

#include <QByteArray>
#include <QString>

class QSettings;

// 镜像参数：决定 scrcpy.exe 的启动参数，改动在下次连接镜像时生效
struct MirrorOptions {
    int maxSize = 720;           // 长边像素上限，0 = 原始分辨率
    int maxFps = 60;             // 0 = 不限帧率
    int bitRateMbps = 8;         // 0 = 用 scrcpy 默认码率
    bool stayAwake = true;       // 连接期间保持设备唤醒
    bool turnScreenOff = false;  // 连接后立即关闭手机屏幕（视频仍继续传输）
};

// 连接参数
struct ConnOptions {
    bool autoConnectLast = true;
    int reconnectMax = 6;        // 0 = 不自动重连
    int reconnectDelaySec = 3;
    QString lastSerial;          // 上次成功连接的设备
};

// 界面参数
struct UiOptions {
    int fontSize = 13;
    bool followResize = true;    // 宿主窗口变化时同步 scrcpy 子窗口尺寸
};

// 所有可调参数的唯一入口（QSettings 落盘）。
// 此前这些值散落在各处的硬编码与零散 QSettings 调用里，改一次要重编译；
// 集中到这里后由设置对话框写入，运行时直接读取。
class Settings {
public:
    static Settings &instance();

    MirrorOptions mirror() const;
    ConnOptions conn() const;
    UiOptions ui() const;

    QString adbPath() const;      // 空 = 自动探测
    QString scrcpyPath() const;   // 空 = 自动探测
    QString captureDir() const;   // 有默认值：图片/DevBoard

    // 默认保存目录（设置对话框「恢复默认」用）
    static QString defaultCaptureDir();

    QByteArray windowGeometry() const;

    void setMirror(const MirrorOptions &o);
    void setConn(const ConnOptions &o);
    void setUi(const UiOptions &o);
    void setAdbPath(const QString &path);
    void setScrcpyPath(const QString &path);
    void setCaptureDir(const QString &dir);
    void setWindowGeometry(const QByteArray &geometry);

    // 恢复全部默认值（写盘）
    void resetAll();

private:
    Settings();

    QSettings *m_s = nullptr;
};
