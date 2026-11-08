#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QtQml/QQmlExtensionPlugin>

Q_IMPORT_QML_PLUGIN(QtMacOSPlugin)
Q_IMPORT_QML_PLUGIN(QtMacOSDemoPlugin)

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Qt-MacOS Gallery");
    app.setOrganizationName("QtMacOS");
    QQuickStyle::setStyle("Basic");
    QQuickWindow::setDefaultAlphaBuffer(true);
    const auto args = app.arguments();
    QQmlApplicationEngine engine;
    engine.load(QUrl(args.contains("--layout") ? QStringLiteral("qrc:/gallery/demo/LayoutMain.qml")
                    : args.contains("--settings") ? QStringLiteral("qrc:/gallery/demo/SettingsMain.qml")
                                                : QStringLiteral("qrc:/gallery/demo/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;
    // Deterministic screenshot entry point, also useful in CI/offscreen mode.
    const int screenshot = args.indexOf("--screenshot");
    if (screenshot >= 0) {
        if (screenshot + 1 >= args.size()) return 2;
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        const QString path = args.at(screenshot + 1);
        QTimer::singleShot(600, &app, [window, path, &app] {
            const QImage image = window->grabWindow();
            app.exit(!image.isNull() && image.save(path) ? 0 : 3);
        });
    }
    return app.exec();
}
