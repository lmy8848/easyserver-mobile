#pragma once

#include <QMainWindow>
#include <QList>

#include "AdbClient.h"

class QComboBox;
class QLabel;
class QTabWidget;
class QPushButton;
class QWidget;

class ScrcpyProcess;
class Panels;

// 主窗口：顶部设备栏 + 左侧镜像宿主 + 右侧面板 + 状态栏
class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

private slots:
    void onDevicesChanged(const QList<AdbClient::Device> &devices);
    void onConnectClicked();
    void onDisconnectClicked();
    void onRefreshClicked();
    void onShellCommand(const QString &cmd);
    void onRefreshInfo();

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
};
