#include <QFile>
#include <QGuiApplication>
#include <QQuickStyle>
#include <QTextStream>
#include <QDateTime>

static FILE *g_logFile = nullptr;
static void fileMessageHandler(QtMsgType type, const QMessageLogContext &ctx,
                               const QString &msg) {
    if (!g_logFile) {
        g_logFile = fopen("D:/devboard-deps/devboard-qt.log", "a");
        if (!g_logFile) return;
    }
    const char *level = type == QtDebugMsg ? "DBG"
        : type == QtWarningMsg ? "WRN"
        : type == QtCriticalMsg || type == QtFatalMsg ? "ERR" : "INF";
    fprintf(g_logFile, "[%s] %s: %s\n", level,
            QDateTime::currentDateTime().toString("hh:mm:ss.zzz").toUtf8().constData(),
            msg.toUtf8().constData());
    fflush(g_logFile);
}
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "app/MirrorController.h"
#include "core/AdbClient.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    qInstallMessageHandler(fileMessageHandler);
    QQuickStyle::setStyle(QStringLiteral("Material"));
    app.setOrganizationName(QStringLiteral("EasyServer"));
    app.setApplicationName(QStringLiteral("DevBoard"));

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    auto *adb = new AdbClient(&app);
    engine.rootContext()->setContextProperty(QStringLiteral("Adb"), adb);

    auto *mirror = new MirrorController(&app);
    mirror->setAdbPath(AdbClient::locateAdb());
    mirror->setAutoConnect(true);
    mirror->setAdbClient(adb);
    qDebug() << "[main] mirror ready, auto-connect armed";
    engine.rootContext()->setContextProperty(QStringLiteral("Mirror"), mirror);
    engine.addImageProvider(QStringLiteral("mirror"), mirror->imageProvider());

    // 设备串口选出后自动连接镜像（首次刷新即触发）
    QObject::connect(adb, &AdbClient::currentSerialChanged, mirror,
        [mirror, adb]() {
            if (mirror->autoConnect() && !adb->currentSerial().isEmpty()
                && !mirror->running())
                mirror->connectTo(adb->currentSerial());
        });

    adb->refreshDevices();
    engine.loadFromModule("devboard", "Main");
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}
