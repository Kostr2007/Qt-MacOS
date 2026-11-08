#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QtQml/QQmlExtensionPlugin>

Q_IMPORT_QML_PLUGIN(QtMacOSPlugin)

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");
    QQuickWindow::setDefaultAlphaBuffer(true);
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/example/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;
    return app.exec();
}
