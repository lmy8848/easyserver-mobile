#include "AppLog.h"

#include <QCoreApplication>
#include <QDate>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMetaObject>
#include <QMutexLocker>
#include <QStandardPaths>
#include <QTime>

AppLog *AppLog::s_instance = nullptr;

AppLog::AppLog(QObject *parent) : QObject(parent) {}

AppLog::~AppLog() {
    QMutexLocker lock(&m_mutex);
    if (m_file) {
        m_file->close();
        delete m_file;
        m_file = nullptr;
    }
}

QString AppLog::logDir() {
    return QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
        .filePath(QStringLiteral("logs"));
}

QString AppLog::logFilePath() {
    return QDir(logDir()).filePath(
        QStringLiteral("devboard-%1.log").arg(QDate::currentDate().toString(QStringLiteral("yyyyMMdd"))));
}

AppLog *AppLog::instance() { return s_instance; }

AppLog *AppLog::install() {
    if (!s_instance)
        s_instance = new AppLog(qApp);
    qInstallMessageHandler(&AppLog::messageHandler);
    s_instance->pruneOldFiles();
    return s_instance;
}

void AppLog::messageHandler(QtMsgType type, const QMessageLogContext &, const QString &msg) {
    const char *level = "DBG";
    switch (type) {
    case QtInfoMsg: level = "INF"; break;
    case QtWarningMsg: level = "WRN"; break;
    case QtCriticalMsg: level = "CRT"; break;
    case QtFatalMsg: level = "FTL"; break;
    default: break;
    }
    const QString line = QStringLiteral("[%1] [%2] %3")
                             .arg(QTime::currentTime().toString(QStringLiteral("HH:mm:ss.zzz")),
                                  QLatin1String(level), msg);
    if (s_instance)
        s_instance->writeLine(line);
    if (type == QtFatalMsg)
        abort();
}

void AppLog::writeLine(const QString &line) {
    {
        QMutexLocker lock(&m_mutex);
        const QDate today = QDate::currentDate();
        if (!m_file || m_openDate != today)
            openForDate(today);
        if (m_file) {
            m_file->write(line.toUtf8());
            m_file->write("\n");
            // 每行 flush：崩溃/被杀时尾部日志不丢，这是定位问题的关键信息
            m_file->flush();
        }
    }
    // 跨线程（解码/IO 线程）也安全：排队到对象所在线程再发信号给界面
    QMetaObject::invokeMethod(
        this, [this, line]() { emit lineWritten(line); }, Qt::QueuedConnection);
}

void AppLog::openForDate(const QDate &date) {
    if (m_file) {
        m_file->close();
        delete m_file;
        m_file = nullptr;
    }
    QDir().mkpath(logDir());
    auto *file = new QFile(
        QDir(logDir()).filePath(QStringLiteral("devboard-%1.log")
                                    .arg(date.toString(QStringLiteral("yyyyMMdd")))));
    if (!file->open(QIODevice::WriteOnly | QIODevice::Append)) {
        delete file;
        return;
    }
    m_file = file;
    m_openDate = date;
}

void AppLog::pruneOldFiles() {
    QDir dir(logDir());
    if (!dir.exists())
        return;
    const QDate cutoff = QDate::currentDate().addDays(-7);
    const QStringList names = dir.entryList({QStringLiteral("devboard-*.log")}, QDir::Files);
    for (const QString &name : names) {
        const QDate date = QDate::fromString(name.mid(9, 8), QStringLiteral("yyyyMMdd"));
        if (!date.isValid() || date >= cutoff)
            continue;
        const QString path = dir.filePath(name);
        if (m_file && QFileInfo(*m_file).absoluteFilePath() == path)
            continue;
        QFile::remove(path);
    }
}
