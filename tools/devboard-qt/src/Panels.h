#pragma once

#include <QTabWidget>

class QPlainTextEdit;
class QLineEdit;
class QTextEdit;
class QListWidget;
class QCheckBox;

// 右侧四面板：终端 / 日志 / 设备 / 操作
class Panels : public QTabWidget {
    Q_OBJECT
public:
    explicit Panels(QWidget *parent = nullptr);

    void appendShell(const QString &text);
    void clearShell();
    void appendLog(const QString &text);
    void clearLog();
    void setInfo(const QString &text);
    void appendInfo(const QString &text);
    void appendPackage(const QString &line);
    void clearPackages();

signals:
    void shellCommandEntered(const QString &command);
    void refreshInfoRequested();
    void screenshotRequested();
    void recordRequested();
    void installApkRequested();
    void listPackagesRequested();
    void uninstallPackageRequested(const QString &package);

private:
    void buildShellTab();
    void buildLogTab();
    void buildInfoTab();
    void buildActionTab();

    QPlainTextEdit *m_shellOut = nullptr;
    QLineEdit *m_shellIn = nullptr;
    QPlainTextEdit *m_logOut = nullptr;
    QTextEdit *m_infoOut = nullptr;
    QListWidget *m_pkgList = nullptr;
    QCheckBox *m_pauseLog = nullptr;
    QLineEdit *m_logFilter = nullptr;
};
