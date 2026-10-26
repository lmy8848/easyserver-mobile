#include <QGuiApplication>
#include <QQuickStyle>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "app/MirrorController.h"
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

    auto *mirror = new MirrorController(&app);
    engine.rootContext()->setContextProperty(QStringLiteral("Mirror"), mirror);
    engine.addImageProvider(QStringLiteral("mirror"), mirror->imageProvider());
    engine.loadFromModule("devboard", "Main");
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}
