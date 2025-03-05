#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QSurfaceFormat>
#include <QDir>
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Set application info
    app.setApplicationName("CouplesApp");
    app.setOrganizationName("CouplesApp");
    
    // Set Material style for consistent look on all platforms
    QQuickStyle::setStyle("Material");
    
    // Set surface format for better rendering
    QSurfaceFormat format;
    format.setSamples(8);
    QSurfaceFormat::setDefaultFormat(format);
    
    QQmlApplicationEngine engine;
    
    // Debug output to check the current working directory
    qDebug() << "Current working directory:" << QDir::currentPath();
    qDebug() << "Application directory:" << QCoreApplication::applicationDirPath();
    
    // Try to load from resources first
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
