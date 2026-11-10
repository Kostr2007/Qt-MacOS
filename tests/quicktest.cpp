#include <QtQuickTest/quicktest.h>
#include <QtQml/QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QQmlContext>
#include <QDir>
#include <QTemporaryDir>
#include "InteractionRecorder.h"
Q_IMPORT_QML_PLUGIN(QtMacOSPlugin)
Q_IMPORT_QML_PLUGIN(QtMacOSDemoPlugin)

class LayoutTestSetup : public QObject {
    Q_OBJECT
    InteractionRecorder recorder{this};
    QTemporaryDir scratch;
public slots:
    void qmlEngineAvailable(QQmlEngine *engine) {
        const QString path = qEnvironmentVariable("QTMACOS_STORY_DIR");
        if (!path.isEmpty()) QDir().mkpath(path);
        engine->rootContext()->setContextProperty("layoutStoryDirectory", path);
        engine->rootContext()->setContextProperty("interactionRecorder", &recorder);
        engine->rootContext()->setContextProperty("interactionTestDirectory", scratch.path());
    }
};
QUICK_TEST_MAIN_WITH_SETUP(qtmacos, LayoutTestSetup)
#include "quicktest.moc"
