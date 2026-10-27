#include <QApplication>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QTimer>

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

    // --serial <addr>：启动后直接连接该设备（快捷方式/脚本调试用）
    const QStringList args = QApplication::arguments();
    const int idx = args.indexOf(QStringLiteral("--serial"));
    const QString autoSerial = (idx > 0 && idx + 1 < args.size()) ? args.at(idx + 1) : QString();
    if (!autoSerial.isEmpty()) {
        qInfo() << "[main] auto connect:" << autoSerial;
        QTimer::singleShot(1500, &win, [&win, autoSerial]() { win.connectSerial(autoSerial); });
    }

    qInfo() << "[main] started, window shown";
    return app.exec();
}
