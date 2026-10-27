#pragma once

#include <QTabWidget>

class QComboBox;
class QPlainTextEdit;
class QLineEdit;
class QTextEdit;
class QListWidget;
class QCheckBox;
class QPushButton;

// 右侧四面板：终端 / 日志 / 设备 / 操作
class Panels : public QTabWidget {
    Q_OBJECT
public:
    explicit Panels(QWidget *parent = nullptr);

    void appendShell(const QString &text);
    void clearShell();
    void appendLog(const QString &text);
    void appendLogLines(const QStringList &lines);
    void clearLog();
    void setInfo(const QString &text);
    void appendInfo(const QString &text);
    void appendPackage(const QString &line);
    void clearPackages();
    void setLogcatRunning(bool running);

    // 截图 / 录屏：保存目录、结果列表、录制中状态
    void setCaptureDir(const QString &dir);
    void appendCapture(const QString &label, const QString &path, bool ok);
    void setRecording(bool recording);

    // 应用自身日志（区别于 logcat）：实时追加、清空
    void appendAppLog(const QString &line);
    void clearAppLog();

signals:
    void shellCommandEntered(const QString &command);
    void refreshInfoRequested();
    void screenshotRequested();
    void recordRequested(int seconds);
    void cancelRecordRequested();
    void chooseCaptureDirRequested();
    void openCaptureDirRequested();
    void openCaptureFileRequested(const QString &path);
    void installApkRequested();
    void listPackagesRequested();
    void uninstallPackageRequested(const QString &package);
    void logcatStartRequested();
    void logcatStopRequested();
    void openLogDirRequested();

private:
    void buildShellTab();
    void buildLogTab();
    void buildInfoTab();
    void buildActionTab();
    void buildAppLogTab();

    QPlainTextEdit *m_shellOut = nullptr;
    QLineEdit *m_shellIn = nullptr;
    QPlainTextEdit *m_logOut = nullptr;
    QTextEdit *m_infoOut = nullptr;
    QListWidget *m_pkgList = nullptr;
    QListWidget *m_captureList = nullptr;
    QLineEdit *m_captureDir = nullptr;
    QCheckBox *m_pauseLog = nullptr;
    QLineEdit *m_logFilter = nullptr;
    QPushButton *m_logcatBtn = nullptr;
    QPushButton *m_recordBtn = nullptr;
    QPlainTextEdit *m_appLog = nullptr;
    QComboBox *m_recordDur = nullptr;
    bool m_logcatRunning = false;
    bool m_recording = false;
};
