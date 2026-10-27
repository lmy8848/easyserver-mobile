#pragma once

#include <QMainWindow>
#include <QList>

#include "AdbClient.h"

class QComboBox;
class QLabel;
class QTabWidget;
class QPushButton;
class QWidget;
class QProcess;

class ScrcpyProcess;
class Panels;

// 主窗口：顶部设备栏 + 左侧镜像宿主 + 右侧面板 + 状态栏
class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

    // 直接连接指定 serial（--serial 启动参数用）
    void connectSerial(const QString &serial);

protected:
    // 镜像区由 scrcpy 子窗口占据，Qt 收不到那里的鼠标/键盘焦点；
    // 在应用级拦截键盘与滚轮，转发给 scrcpy 窗口。
    bool eventFilter(QObject *watched, QEvent *event) override;

private slots:
    void onDevicesChanged(const QList<AdbClient::Device> &devices);
    void onConnectClicked();
    void onDisconnectClicked();
    void onRefreshClicked();
    void onShellCommand(const QString &cmd);
    void onRefreshInfo();
    void onLogcatStart();
    void onLogcatStop();
    void flushLogcat();
    void onScreenshot();
    void onRecord(int seconds);
    void onCancelRecord();
    void onChooseCaptureDir();
    void onOpenCaptureDir();
    void onOpenCaptureFile(const QString &path);

private:
    void buildUi();
    void applyDarkTheme();
    QString currentSerial() const;
    bool currentOnline() const;

    QString ensureCaptureDir();
    void reportCapture(const QString &label, const QString &path, bool ok,
                       const QString &detail = QString());
    void captureViaDeviceFile(const QString &serial, const QString &localPath,
                              const QString &prevErr);
    void pullRecord(const QString &serial, const QString &remote, const QString &local,
                    bool cancelled);
    void probeRecord();
    void finishRecord();

    AdbClient *m_adb = nullptr;
    ScrcpyProcess *m_scrcpy = nullptr;

    QComboBox *m_deviceBox = nullptr;
    QLabel *m_deviceState = nullptr;
    QPushButton *m_connectBtn = nullptr;
    QPushButton *m_disconnectBtn = nullptr;
    Panels *m_panels = nullptr;
    QWidget *m_mirrorHost = nullptr;
    QLabel *m_status = nullptr;

    QList<AdbClient::Device> m_devices;
    QTimer *m_autoReconnect = nullptr;
    QString m_serial;
    int m_retries = 0;

    QProcess *m_logcat = nullptr;
    QByteArray m_logcatTail;
    QTimer *m_logFlush = nullptr;
    int m_logDropped = 0;

    // 截图 / 录屏
    QString m_captureDirPath;
    // 录屏走设备端后台进程（nohup），停止时发 SIGINT 让 screenrecord 正常写 moov，
    // 避免直接 kill 留下无法播放的 MP4
    QString m_recordSerial;
    QString m_recordRemote;
    QString m_recordLocal;
    QString m_recordPidFile;
    QProcess *m_recordProbe = nullptr;
    bool m_recordStopping = false;
    bool m_recordCancelled = false;
    QTimer *m_recordTick = nullptr;
    int m_recordRemain = 0;
    int m_recordTicks = 0;
    int m_recordSeconds = 0;
};
