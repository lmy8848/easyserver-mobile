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

private:
    void buildUi();
    void applyDarkTheme();
    QString currentSerial() const;
    bool currentOnline() const;

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
    QProcess *m_logcat = nullptr;
    QByteArray m_logcatTail;
    QTimer *m_logFlush = nullptr;
    int m_logDropped = 0;
};
