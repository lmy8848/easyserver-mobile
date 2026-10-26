#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QUrl>

/// M4 右侧面板后端：交互式 shell / logcat 流式 / 设备信息 / APK 操作。
/// 终端与日志内容通过 append 信号增量推给 QML（避免大文本整体重绑定），
/// 原始行缓冲有上限，长时间流式输出不会撑爆内存。
class DeviceTools : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool shellRunning READ shellRunning NOTIFY shellRunningChanged)
    Q_PROPERTY(bool logcatRunning READ logcatRunning NOTIFY logcatRunningChanged)
    Q_PROPERTY(bool logPaused READ logPaused WRITE setLogPaused NOTIFY logPausedChanged)
    Q_PROPERTY(QString infoText READ infoText NOTIFY infoTextChanged)
    Q_PROPERTY(QString actionStatus READ actionStatus NOTIFY actionStatusChanged)
    Q_PROPERTY(bool actionBusy READ actionBusy NOTIFY actionBusyChanged)
    Q_PROPERTY(QStringList packages READ packages NOTIFY packagesChanged)

public:
    explicit DeviceTools(QObject *parent = nullptr);

    void setAdbPath(const QString &path) { m_adb = path; }

    bool shellRunning() const { return m_shell != nullptr; }
    bool logcatRunning() const { return m_logcat != nullptr; }
    bool logPaused() const { return m_logPaused; }
    QString infoText() const { return m_infoText; }
    QString actionStatus() const { return m_actionStatus; }
    bool actionBusy() const { return m_action != nullptr; }
    QStringList packages() const { return m_packages; }

    // 终端（交互式 adb shell）
    Q_INVOKABLE void shellStart(const QString &serial);
    Q_INVOKABLE void shellStop();
    Q_INVOKABLE void shellSend(const QString &line);
    Q_INVOKABLE void shellClear();

    // 日志（logcat 流式 + 过滤 + 暂停；暂停期间丢弃新行防止恢复时洪水）
    Q_INVOKABLE void logcatStart(const QString &serial);
    Q_INVOKABLE void logcatStop();
    Q_INVOKABLE void logcatClear();
    Q_INVOKABLE void setLogPaused(bool paused);
    Q_INVOKABLE void setLogFilter(const QString &filter);
    Q_INVOKABLE QString logText() const;

    // 设备信息（后台动作，不与显式操作抢占）
    Q_INVOKABLE void refreshInfo(const QString &serial);

    // 操作
    Q_INVOKABLE void screenshot(const QString &serial);
    Q_INVOKABLE void recordScreen(const QString &serial);
    Q_INVOKABLE void installApk(const QString &serial, const QUrl &file);
    Q_INVOKABLE void uninstallApk(const QString &serial, const QString &packageName);
    Q_INVOKABLE void listPackages(const QString &serial);

signals:
    void shellRunningChanged();
    void shellAppended(const QString &chunk);
    void shellViewReset();
    void logcatRunningChanged();
    void logPausedChanged();
    void logAppended(const QString &chunk);
    void logViewReset();
    void infoTextChanged();
    void actionStatusChanged();
    void actionBusyChanged();
    void packagesChanged();
    void savedToPath(const QString &path);

private:
    QStringList baseArgs(const QString &serial) const;
    void setActionStatus(const QString &text);
    void startAction(const QString &kind, const QStringList &args,
                     const QString &runningText);
    void handleActionFinished(const QString &kind, int code,
                              const QByteArray &out, const QByteArray &err);
    QString formatInfo(const QString &raw) const;
    void appendShell(const QByteArray &chunk);
    void feedLogLines(const QByteArray &chunk);

    QString m_adb;

    QProcess *m_shell = nullptr;

    QProcess *m_logcat = nullptr;
    QByteArray m_logPending;
    QStringList m_logRaw;
    QString m_logFilter;
    bool m_logPaused = false;

    QProcess *m_action = nullptr;
    QString m_actionKind;
    QString m_actionSerial;
    QString m_actionStatus;
    QString m_infoText;
    QStringList m_packages;
    QString m_recordRemote;
    QString m_recordLocal;
};
