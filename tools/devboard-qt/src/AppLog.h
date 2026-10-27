#pragma once

#include <QDate>
#include <QMutex>
#include <QObject>
#include <QString>

class QFile;

// 应用层全局日志：接管 qDebug/qInfo/qWarning 等输出，
// 落盘到 <AppData>/DevBoard/logs/devboard-YYYYMMDD.log（按天轮转、保留 7 天），
// 并实时推送到界面「应用日志」面板，便于监测运行状态与定位故障。
class AppLog : public QObject {
    Q_OBJECT
public:
    // 安装消息处理器（须在 QApplication 构造之后调用一次）
    static AppLog *install();
    static AppLog *instance();

    static QString logDir();
    static QString logFilePath();  // 今天对应的日志文件

signals:
    void lineWritten(const QString &line);

private:
    explicit AppLog(QObject *parent = nullptr);
    ~AppLog() override;

    static void messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg);
    void writeLine(const QString &line);
    void openForDate(const QDate &date);
    void pruneOldFiles();

    QMutex m_mutex;
    QFile *m_file = nullptr;
    QDate m_openDate;

    static AppLog *s_instance;
};
