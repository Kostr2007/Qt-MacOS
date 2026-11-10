#include <QGuiApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "InteractionRecorder.h"
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
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
    InteractionRecorder recorder;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("interactionRecorder", &recorder);
    engine.load(QUrl(args.contains("--motion-lab") ? QStringLiteral("qrc:/gallery/demo/MotionLab.qml")
                    : args.contains("--layout") ? QStringLiteral("qrc:/gallery/demo/LayoutMain.qml")
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
        const int diagnostics = args.indexOf("--render-info");
        if (diagnostics >= 0 && diagnostics + 1 >= args.size()) return 2;
        const QString diagnosticsPath = diagnostics >= 0 ? args.at(diagnostics + 1) : QString();
        QTimer::singleShot(600, &app, [window, path, diagnosticsPath, &app] {
            const QImage image = window->grabWindow();
            if (image.isNull() || !image.save(path)) { app.exit(3); return; }
            if (!diagnosticsPath.isEmpty()) {
                const auto api = window->rendererInterface()->graphicsApi();
                const QJsonObject report {
                    {QStringLiteral("graphicsApi"), int(api)},
                    {QStringLiteral("software"), api == QSGRendererInterface::Software},
                    {QStringLiteral("devicePixelRatio"), window->devicePixelRatio()},
                    {QStringLiteral("platform"), QGuiApplication::platformName()}
                };
                QFile output(diagnosticsPath);
                const auto bytes = QJsonDocument(report).toJson();
                if (!output.open(QIODevice::WriteOnly) || output.write(bytes) != bytes.size()) {
                    app.exit(4); return;
                }
            }
            app.exit(0);
        });
    }
    return app.exec();
}
