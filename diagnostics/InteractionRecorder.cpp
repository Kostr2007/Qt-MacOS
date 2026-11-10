#include "InteractionRecorder.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMouseEvent>
#include <QKeyEvent>
#include <QSaveFile>
#include <QSGRendererInterface>
#include <QStandardPaths>

QString InteractionRecorder::outputRoot() const {
    return qEnvironmentVariable("QTMACOS_INTERACTION_DIR",
        QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/interactions");
}

bool InteractionRecorder::start(const QString &directory, QQuickWindow *window, bool capture) {
    if (!window || m_window || directory.isEmpty()) return false;
    // Each recording is a fresh directory: never overwrite earlier evidence.
    if (QFileInfo::exists(directory) || !QDir().mkpath(directory)) return false;
    m_directory = directory;
    m_window = window;
    m_capture = capture;
    m_events = {}; m_samples = {}; m_frames = {};
    m_clock.start();
    window->installEventFilter(this);
    // Queued delivery is intentionally labelled as such, not a display-present
    // timestamp. Snapshot capture itself can slow rendering.
    const auto generation = ++m_generation;
    m_frameConnection = connect(window, &QQuickWindow::frameSwapped, this, [this, generation] {
        if (m_window && generation == m_generation && m_frames.size() < 20000)
            m_frames.append(double(m_clock.nsecsElapsed()) / 1e6);
    }, Qt::QueuedConnection);
    return true;
}

bool InteractionRecorder::eventFilter(QObject *, QEvent *event) {
    if (event->type() == QEvent::MouseMove || event->type() == QEvent::MouseButtonPress
        || event->type() == QEvent::MouseButtonRelease) {
        const auto *mouse = static_cast<QMouseEvent *>(event);
        if (m_events.size() < 20000)
            m_events.append(QJsonObject{{"received_ms", double(m_clock.nsecsElapsed()) / 1e6},
                {"type", int(event->type())}, {"x", mouse->position().x()},
                {"y", mouse->position().y()}, {"buttons", int(mouse->buttons())}});
    }
    if ((event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) && m_events.size() < 20000) {
        const auto *key = static_cast<QKeyEvent *>(event);
        m_events.append(QJsonObject{{"received_ms", double(m_clock.nsecsElapsed()) / 1e6},
            {"type", int(event->type())}, {"key", key->key()},
            {"modifiers", int(key->modifiers())}, {"autorepeat", key->isAutoRepeat()}});
    }
    return false;
}

bool InteractionRecorder::sample(const QVariantMap &state) {
    if (!m_window || m_samples.size() >= 2000) return false;
    QJsonObject row = QJsonObject::fromVariantMap(state);
    row["sample_ms"] = double(m_clock.nsecsElapsed()) / 1e6;
    if (m_capture) {
        const auto image = m_window->grabWindow();
        const QString name = QString("frame-%1.png").arg(m_samples.size(), 4, 10, QChar('0'));
        if (image.isNull() || !image.save(m_directory + "/" + name)) return false;
        if (state.contains("probe_x") && state.contains("probe_y")) {
            const int x = qBound(0, qRound(state.value("probe_x").toDouble() * m_window->devicePixelRatio()), image.width() - 1);
            const int y = qBound(0, qRound(state.value("probe_y").toDouble() * m_window->devicePixelRatio()), image.height() - 1);
            const auto color = image.pixelColor(x, y);
            row["probe_rgb"] = QJsonArray{color.red(), color.green(), color.blue()};
            row["probe_luma"] = .2126 * color.redF() + .7152 * color.greenF() + .0722 * color.blueF();
        }
        row["file"] = name;
        row["capture_finished_ms"] = double(m_clock.nsecsElapsed()) / 1e6;
    }
    m_samples.append(row);
    return true;
}

bool InteractionRecorder::stop() {
    if (!m_window) return false;
    disconnect(m_frameConnection);
    ++m_generation;
    m_window->removeEventFilter(this);
    QJsonObject report{{"schema", 1}, {"qt_version", QT_VERSION_STR},
        {"platform", QGuiApplication::platformName()},
        {"graphics_api", int(m_window->rendererInterface()->graphicsApi())},
        {"dpr", m_window->devicePixelRatio()}, {"capture_enabled", m_capture},
        {"input_events", m_events}, {"samples", m_samples},
        {"frame_swapped_queued_ms", m_frames},
        {"timing_note", "Monotonic received/sample timestamps; queued frame signals; not display latency or FPS."}};
    m_window = nullptr;
    QSaveFile file(m_directory + "/trace.json");
    const auto bytes = QJsonDocument(report).toJson();
    return file.open(QIODevice::WriteOnly) && file.write(bytes) == bytes.size() && file.commit();
}

bool InteractionRecorder::savePreset(const QString &path, const QVariantMap &preset) {
    if (!QDir().mkpath(QFileInfo(path).absolutePath())) return false;
    QSaveFile file(path);
    const auto bytes = QJsonDocument(QJsonObject::fromVariantMap(preset)).toJson();
    return file.open(QIODevice::WriteOnly) && file.write(bytes) == bytes.size() && file.commit();
}

QVariantMap InteractionRecorder::loadPreset(const QString &path) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return {};
    return QJsonDocument::fromJson(file.readAll()).object().toVariantMap();
}
