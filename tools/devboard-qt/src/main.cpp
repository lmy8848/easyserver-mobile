#include <QDateTime>
#include <QFile>
#include <QGuiApplication>
#include <QQuickStyle>
#include <QSettings>
#include <QTextStream>
#include <QTimer>
#include <cstdio>

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

#include "app/DeviceTools.h"
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
    mirror->setAdbClient(adb); // 内部连接串口/设备列表信号（含在线校验与重试预算）
    qDebug() << "[main] mirror ready, auto-connect armed";
    engine.rootContext()->setContextProperty(QStringLiteral("Mirror"), mirror);
    engine.addImageProvider(QStringLiteral("mirror"), mirror->imageProvider());

    auto *tools = new DeviceTools(&app);
    tools->setAdbPath(AdbClient::locateAdb());
    engine.rootContext()->setContextProperty(QStringLiteral("Tools"), tools);

    // 上次目标设备持久化：启动即恢复，设备上线时由 devicesChanged 自动连接
    QSettings settings;
    const QString last = settings.value(QStringLiteral("device/lastSerial")).toString();
    if (!last.isEmpty()) adb->setCurrentSerial(last);
    QObject::connect(adb, &AdbClient::currentSerialChanged, &app, [adb]() {
        QSettings s;
        s.setValue(QStringLiteral("device/lastSerial"), adb->currentSerial());
    });

    // 3s 轮询刷新设备列表：无线掉线自动重连的基础（PLAN §6 M4）
    auto *watch = new QTimer(&app);
    watch->setInterval(3000);
    QObject::connect(watch, &QTimer::timeout, adb, &AdbClient::refreshDevices);
    watch->start();

    adb->refreshDevices();
    engine.loadFromModule("devboard", "Main");
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}
