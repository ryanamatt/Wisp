// src/backend/audio/audio.cpp

#include "audio.hpp"

#include <QByteArray>
#include <QProcess>
#include <QRegularExpression>
#include <algorithm>
#include <qcontainerfwd.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qprocess.h>

namespace {

constexpr const char *kSinkAlias = "@DEFAULT_AUDIO_SINK@";
constexpr const char *kSourceAlias = "@DEFAULT_AUDIO_SOURCE@";

// `wpctl get-volume <node>` prints a single line, e.g.
//   "Volume: 0.45"
//   "Volume: 0.45 [MUTED]"
bool parseVolumeLine(const QString &output, qreal *volumeOut, bool *mutedOut) {
    static const QRegularExpression re(R"(Volume:\s*([0-9.]+)(\s*\[MUTED\])?)");
    const QRegularExpressionMatch match = re.match(output);
    if (!match.hasMatch()) return false;

    *volumeOut = match.captured(1).toDouble();
    *mutedOut = !match.captured(2).isEmpty();
    return true;
}

QString runWpctl(const QStringList &args) {
    QProcess proc;
    proc.start("wpctl", args);
    if (!proc.waitForFinished(1000)) return QString();
    return QString::fromUtf8(proc.readAllStandardOutput());
}

// Each line looks like "3;5;1;7;0;4;2;6;5;3;" (trailing ';' possible).
QList<int> parseCavaLine(const QByteArray &line, int maxRange) {
    QList<int> values;
    const QString text = QString::fromUtf8(line).trimmed();
    const QStringList parts = text.split(";", Qt::SkipEmptyParts);
    values.reserve(parts.size());
    for (const QString &part : parts) {
        bool ok = false;
        const int v = part.toInt(&ok);
        if (ok) values.append(std::clamp(v, 0, maxRange));
    }
    return values;
}

} // namespace

Audio::Audio(QObject *parent) : QObject(parent) {
    m_sinkWriteDebounce.setSingleShot(true);
    m_sinkWriteDebounce.setInterval(kDebounceMs);
    connect(&m_sinkWriteDebounce, &QTimer::timeout, this, &Audio::writeSinkVolume);

    m_sourceWriteDebounce.setSingleShot(true);
    m_sourceWriteDebounce.setInterval(kDebounceMs);
    connect(&m_sourceWriteDebounce, &QTimer::timeout, this, &Audio::writeSourceVolume);

    m_pollTimer.setInterval(kPollMs);
    connect(&m_pollTimer, &QTimer::timeout, this, &Audio::poll);
    m_pollTimer.start();

    // Populate initial state synchronously so the first paint isn't empty.
    poll();

    connect(&m_cava, &QProcess::readyReadStandardOutput, this, &Audio::onCavaReadyRead);
    connect(&m_cava, &QProcess::errorOccurred, this, [this](QProcess::ProcessError) {
        m_cavaFailed = true;
        emit cavaChanged();
    });
    connect(&m_cava, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        // Cava is meant to run forever, so any exit is a failure.
        m_cavaFailed = true;
        emit cavaChanged();
    });
    startCava();
}

Audio::~Audio() {
    if (m_cava.state() != QProcess::NotRunning) {
        m_cava.disconnect(this);
        m_cava.terminate();
        if (!m_cava.waitForFinished(500)) {
            m_cava.kill();
            m_cava.waitForFinished(500);
        }
    }
}

void Audio::pollNode(const QString &nodeAlias, bool *hasNode, bool *mutedOut, qreal *volumeOut, bool *changedOut) {
    const QString output = runWpctl({"get-volume", nodeAlias});

    qreal volume = 0.0;
    bool muted = false;
    const bool ok = parseVolumeLine(output, &volume, &muted);

    *changedOut = (*hasNode != ok) || (ok && (muted != *mutedOut || !qFuzzyCompare(volume + 1.0, *volumeOut + 1.0)));

    *hasNode = ok;
    if (ok) {
        *mutedOut = muted;
        *volumeOut = volume;
    }
}

void Audio::poll() {
    bool sinkChangedFlag = false;
    pollNode(kSinkAlias, &m_hasSink, &m_sinkMuted, &m_sinkVolume, &sinkChangedFlag);
    if (sinkChangedFlag) emit sinkChanged();

    bool sourceChangedFlag = false;
    pollNode(kSourceAlias, &m_hasSource, &m_sourceMuted, &m_sourceVolume, &sourceChangedFlag);
    if (sourceChangedFlag) emit sourceChanged();
}

void Audio::setSinkVolume(qreal v) {
    if (!m_hasSink) return;

    m_sinkVolume = std::clamp(v, 0.0, 1.0);
    m_pendingSinkVolume = m_sinkVolume;
    emit sinkChanged();

    m_sinkWriteDebounce.start();
}

void Audio::writeSinkVolume() {
    if (!m_hasSink) return;
    QProcess::startDetached("wpctl", {"set-volume", kSinkAlias, QString::number(m_pendingSinkVolume, 'f', 4)});
}

void Audio::toggleSinkMute() {
    if (!m_hasSink) return;
    m_sinkMuted = !m_sinkMuted;
    emit sinkChanged();
    writeMute(kSinkAlias, m_sinkMuted);
}

void Audio::setSourceVolume(qreal v) {
    if (!m_hasSource) return;

    m_sourceVolume = std::clamp(v, 0.0, 1.0);
    m_pendingSourceVolume = m_sourceVolume;
    emit sourceChanged();

    m_sourceWriteDebounce.start();
}

void Audio::writeSourceVolume() {
    if (!m_hasSource) return;
    QProcess::startDetached("wpctl", {"set-volume", kSourceAlias, QString::number(m_pendingSourceVolume, 'f', 4)});
}

void Audio::toggleSourceMute() {
    if (!m_hasSource) return;
    m_sourceMuted = !m_sourceMuted;
    emit sourceChanged();
    writeMute(kSourceAlias, m_sourceMuted);
}

void Audio::writeMute(const QString &nodeAlias, bool muted) {
    QProcess::startDetached("wpctl", {"set-mute", nodeAlias, muted ? "1" : "0"});
}

void Audio::startCava() {
    // Cava wants a config file path. A temp file lives as long as this object does.
    if (!m_cavaConfig.open()) {
        m_cavaFailed = true;
        emit cavaChanged();
        return;
    }

    const QString config = QStringLiteral("[general]\n"
                                          "bars = %1\n"
                                          "\n"
                                          "[output]\n"
                                          "method = raw\n"
                                          "raw_target = /dev/stdout\n"
                                          "data_format = ascii\n"
                                          "ascii_max_range = %2\n"
                                          "bar_delimiter = 59\n"
                                          "frame_delimiter = 10\n")
                               .arg(kCavaBarCount)
                               .arg(kCavaMaxRange);

    m_cavaConfig.write(config.toUtf8());
    m_cavaConfig.close();

    m_cava.setStandardErrorFile(QProcess::nullDevice());
    m_cava.start("cava", {"-p", m_cavaConfig.fileName()});
}

void Audio::onCavaReadyRead() {
    // Cava can emit faster than we are scheduled, so only publish the newest complete frame.
    QList<int> latest;
    while (m_cava.canReadLine()) {
        const QList<int> frame = parseCavaLine(m_cava.readLine(), kCavaMaxRange);
        if (!frame.isEmpty()) latest = frame;
    }

    if (latest.isEmpty()) return;

    m_cavaBars = latest;
    if (m_cavaFailed) m_cavaFailed = false;
    emit cavaChanged();
}
