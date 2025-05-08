#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QSurfaceFormat>
#include <QDir>
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Couples App");
    app.setOrganizationName("Couples App");
    QQuickStyle::setStyle("Material");
    QSurfaceFormat format;
    format.setSamples(8);
    QSurfaceFormat::setDefaultFormat(format);
    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qDebug() << "Failed to load:" << url;
            QCoreApplication::exit(-1);
        } else {
            qDebug() << "Successfully loaded:" << objUrl;
        }
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    return app.exec();
}
