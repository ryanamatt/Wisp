// src/backend/audio/audio.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>

class Audio : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // ----- Sink (speaker / output) -----
    Q_PROPERTY(bool hasSink READ hasSink NOTIFY sinkChanged)
    Q_PROPERTY(bool sinkMuted READ sinkMuted NOTIFY sinkChanged)
    Q_PROPERTY(qreal sinkVolume READ sinkVolume NOTIFY sinkChanged)

    // ----- Source (microphone / input) -----
    Q_PROPERTY(bool hasSource READ hasSource NOTIFY sourceChanged)
    Q_PROPERTY(bool sourceMuted READ sourceMuted NOTIFY sourceChanged)
    Q_PROPERTY(qreal sourceVolume READ sourceVolume NOTIFY sourceChanged)

public:
    explicit Audio(QObject *parent = nullptr);

    bool hasSink() const {
        return m_hasSink;
    }
    bool sinkMuted() const {
        return m_sinkMuted;
    }
    qreal sinkVolume() const {
        return m_sinkVolume;
    }

    bool hasSource() const {
        return m_hasSource;
    }
    bool sourceMuted() const {
        return m_sourceMuted;
    }
    qreal sourceVolume() const {
        return m_sourceVolume;
    }

public slots:
    // V is between 0..1, inclusive.
    void setSinkVolume(qreal v);
    void toggleSinkMute();

    void setSourceVolume(qreal v);
    void toggleSourceMute();

signals:
    void sinkChanged();
    void sourceChanged();

private slots:
    void poll();
    void writeSinkVolume();
    void writeSourceVolume();

private:
    static constexpr int kPollMs = 500;
    static constexpr int kDebounceMs = 80;

    // Polls a single node (sink or source), updating the target state and reporting whether anything actually
    // changed so the caller only emits when needed.
    void pollNode(const QString &nodeAlias, bool *hasNode, bool *mutedOut, qreal *volumeOut, bool *changedOut);
    void writeMute(const QString &nodeAlias, bool muted);

    QTimer m_pollTimer;
    QTimer m_sinkWriteDebounce;
    QTimer m_sourceWriteDebounce;

    // --- Sink ---
    bool m_hasSink = false;
    bool m_sinkMuted = false;
    qreal m_sinkVolume = 0.0;
    qreal m_pendingSinkVolume = 0.0;

    // --- Source ---
    bool m_hasSource = false;
    bool m_sourceMuted = false;
    qreal m_sourceVolume = 0.0;
    qreal m_pendingSourceVolume = 0.0;
};
