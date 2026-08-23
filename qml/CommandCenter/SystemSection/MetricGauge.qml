// qml/CommandCenter/SystemSection/MetricGauge.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"

ColumnLayout {
    id: root

    // --- Public API ---
    property string label: ""
    property real value: 0
    property real maxValue: 100
    property string unit: ""
    property int decimals: 0

    // Optional color thresholds. Leave at -1 to disable a tier.
    property real warnThreshold: -1
    property real critThreshold: -1

    property color normalColor: Colors.colors.accent
    property color warnColor: Colors.colors.warning
    property color critColor: Colors.colors.error
    property color trackColor: Colors.colors.surfaceAlt

    property real size: 120
    property real thickness: 10

    spacing: 8

    // --- Derived state ---
    property real ratio: root.maxValue > 0
        ? Math.max(0, Math.min(1, root.value / root.maxValue))
        : 0

    property color ringColor: {
        if (root.critThreshold >= 0 && root.value >= root.critThreshold) return root.critColor
        if (root.warnThreshold >= 0 && root.value >= root.warnThreshold) return root.warnColor
        return root.normalColor
    }

    // Animate transitions whenever the underlying stat ticks
    Behavior on ratio {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }
    Behavior on ringColor {
        ColorAnimation { duration: 350 }
    }

    Item {
        Layout.preferredWidth: root.size
        Layout.preferredHeight: root.size
        Layout.alignment: Qt.AlignHCenter

        Canvas {
            id: canvas
            anchors.fill: parent

            readonly property real startAngle: 135  // degrees
            readonly property real sweepAngle: 270  // degrees, leaves a gap at the bottom

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var cx = width / 2
                var cy = height / 2
                var r = Math.min(width, height) / 2 - root.thickness / 2
                var start = (Math.PI / 180) * canvas.startAngle
                var full = (Math.PI / 180) * canvas.sweepAngle

                // Track (full arc, dim)
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, start + full, false)
                ctx.lineWidth = root.thickness
                ctx.lineCap = "round"
                ctx.strokeStyle = root.trackColor
                ctx.stroke()

                // Value arc
                if (root.ratio > 0) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start, start + full * root.ratio, false)
                    ctx.lineWidth = root.thickness
                    ctx.lineCap = "round"
                    ctx.strokeStyle = root.ringColor
                    ctx.stroke()
                }
            }

            // Canvas doesn't auto-track JS reads inside onPaint, so repaint
            // explicitly whenever the animated values move.
            Connections {
                target: root
                function onRatioChanged() { canvas.requestPaint() }
                function onRingColorChanged() { canvas.requestPaint() }
            }

            Component.onCompleted: requestPaint()
        }

        Text {
            anchors.centerIn: parent
            text: root.value >= 0 ? root.value.toFixed(root.decimals) + root.unit : "--"
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: root.size * 0.16
            font.bold: true
            color: Colors.colors.foreground
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        font.family: "Iosevka Nerd Font Propo"
        font.pixelSize: 12
        color: Colors.colors.foregroundMuted
    }
}
