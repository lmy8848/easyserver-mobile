#pragma once

#include <QObject>
#include <QString>

class AdbClient;
class QElapsedTimer;
class QProcess;
class QTimer;

// 镜像实时指标。
//
// 数据来源（都取自设备端或设备链路，不靠估）：
//  - 码率 / 累计流量：scrcpy server 进程的 /proc/<pid>/io 里 wchar（写入 socket 的字节数）
//    每秒采样一次取差分。手机上播静态画面时 VBR 编码器几乎不出数据，所以静止画面下
//    码率接近 0 是真实值，不是没采到。
//  - 链路 RTT：设备 ping 电脑（ping -c 1），拿 rtt avg；反映 WiFi 往返，不是显示延迟。
// 分辨率和帧率由 scrcpy 客户端日志提供（见 ScrcpyProcess 的 --print-fps）。
class MirrorStats : public QObject {
    Q_OBJECT
public:
    explicit MirrorStats(AdbClient *adb, QObject *parent = nullptr);

    // 开始采样指定设备；传空串等于 clear()
    void setSerial(const QString &serial);
    void clear();

    bool valid() const { return m_valid; }
    int kbps() const { return m_kbps; }
    qint64 totalBytes() const { return m_totalBytes; }
    int rttMs() const { return m_rttMs; }

signals:
    void changed();

private:
    void sampleIo();
    void sampleRtt();
    QString pcAddress() const;

    AdbClient *m_adb = nullptr;
    QString m_serial;
    QTimer *m_ioTimer = nullptr;
    QTimer *m_rttTimer = nullptr;
    QProcess *m_ioProc = nullptr;
    QProcess *m_rttProc = nullptr;
    qint64 m_lastWchar = -1;
    qint64 m_firstWchar = -1;
    qint64 m_totalBytes = 0;
    int m_kbps = 0;
    int m_rttMs = -1;
    bool m_valid = false;
};
