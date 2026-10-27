#include <QApplication>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

#include "MainWindow.h"

// 日志落盘，便于无控制台环境诊断
static void logHandler(QtMsgType type, const QMessageLogContext &, const QString &msg) {
    const char *tag = "DBG";
    switch (type) {
    case QtInfoMsg: tag = "INF"; break;
    case QtWarningMsg: tag = "WRN"; break;
    case QtCriticalMsg: tag = "CRT"; break;
    case QtFatalMsg: tag = "FTL"; break;
    default: break;
    }
    QFile f(QStringLiteral("D:/devboard-deps/devboard-qt.log"));
    if (f.open(QIODevice::WriteOnly | QIODevice::Append)) {
        f.write(QStringLiteral("[%1] %2\n").arg(QLatin1String(tag), msg).toUtf8());
    }
}

int main(int argc, char **argv) {
    qInstallMessageHandler(logHandler);

    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("DevBoard"));
    QApplication::setApplicationVersion(QStringLiteral("0.1.0"));

    MainWindow win;
    win.show();

    qInfo() << "[main] started, window shown";
    return app.exec();
}
