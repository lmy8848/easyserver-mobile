#include <QGuiApplication>
#include <QQuickStyle>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "core/AdbClient.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle(QStringLiteral("Material"));
    app.setOrganizationName(QStringLiteral("EasyServer"));
    app.setApplicationName(QStringLiteral("DevBoard"));

    qmlRegisterSingletonType<AdbClient>(
        "devboard", 1, 0, "Adb",
        [](QQmlEngine *engine, QJSEngine *) -> QObject * {
            return new AdbClient();
        });

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule("devboard", "Main");
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}
