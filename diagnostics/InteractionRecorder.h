#pragma once
#include <QObject>
#include <QElapsedTimer>
#include <QJsonArray>
#include <QPointer>
#include <QQuickWindow>
#include <QVariantMap>

// Development tooling only; never linked into the public QML library.
class InteractionRecorder : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString outputRoot READ outputRoot CONSTANT)
public:
    explicit InteractionRecorder(QObject *parent = nullptr) : QObject(parent) {}
    QString outputRoot() const;
    Q_INVOKABLE bool start(const QString &directory, QQuickWindow *window, bool capture = true);
    Q_INVOKABLE bool sample(const QVariantMap &state);
    Q_INVOKABLE bool stop();
    Q_INVOKABLE bool savePreset(const QString &path, const QVariantMap &preset);
    Q_INVOKABLE QVariantMap loadPreset(const QString &path) const;
protected:
    bool eventFilter(QObject *watched, QEvent *event) override;
private:
    QPointer<QQuickWindow> m_window;
    QElapsedTimer m_clock;
    QJsonArray m_events, m_samples, m_frames;
    QString m_directory;
    bool m_capture = false;
    quint64 m_generation = 0;
    QMetaObject::Connection m_frameConnection;
};
