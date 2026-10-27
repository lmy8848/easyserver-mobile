#include <QApplication>
#include <QDir>
#include <QTimer>

#include "AppLog.h"
#include "MainWindow.h"

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("DevBoard"));
    QApplication::setApplicationName(QStringLiteral("DevBoard"));
    QApplication::setApplicationVersion(QStringLiteral("0.1.0"));

    // 全局日志：落盘 + 实时推送到界面「应用日志」面板
    AppLog::install();
    qInfo() << "[main] ===== DevBoard start =====" << QApplication::applicationVersion()
            << "log:" << QDir::toNativeSeparators(AppLog::logFilePath());

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
