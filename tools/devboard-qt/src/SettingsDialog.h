#pragma once

#include <QDialog>

class QCheckBox;
class QComboBox;
class QLineEdit;
class QSpinBox;

// 设置对话框：镜像参数 / 连接策略 / 工具路径 / 界面。
// 只在用户点「保存」时写盘，取消不产生副作用。
class SettingsDialog : public QDialog {
    Q_OBJECT
public:
    explicit SettingsDialog(QWidget *parent = nullptr);

private:
    void loadValues();
    void saveValues();
    void applyDefaultsToUi();
    void browseAdb();
    void browseScrcpy();
    void browseCaptureDir();

    QComboBox *m_maxSize = nullptr;
    QComboBox *m_maxFps = nullptr;
    QSpinBox *m_bitRate = nullptr;
    QCheckBox *m_stayAwake = nullptr;
    QCheckBox *m_turnScreenOff = nullptr;

    QCheckBox *m_autoConnectLast = nullptr;
    QSpinBox *m_reconnectMax = nullptr;
    QSpinBox *m_reconnectDelay = nullptr;

    QLineEdit *m_adbPath = nullptr;
    QLineEdit *m_scrcpyPath = nullptr;
    QLineEdit *m_captureDir = nullptr;

    QSpinBox *m_fontSize = nullptr;
    QCheckBox *m_followResize = nullptr;
};
