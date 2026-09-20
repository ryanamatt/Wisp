// qml/CommandCenter/SystemSection/NetworkCard.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../Colors"
import "../../Config"
import "../../Icons"
import "../../Utils/Utils.js" as Utils
import Wisp.System

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: innerColumn.implicitHeight + innerColumn.anchors.margins * 2

    color: Colors.colors.surface
    radius: 12

    // How many ticks of history the sparkline keeps on screen. The worker
    // polls every ~1s, so this is roughly a minute-wide window.
    readonly property int maxPoints: 60

    property var rxHistory: []
    property var txHistory: []

    readonly property real currentRx: SystemMonitor.netRxBytesPerSec
    readonly property real currentTx: SystemMonitor.netTxBytesPerSec

    function pushSample(rx, tx) {
        var safeRx = rx >= 0 ? rx : 0
        var safeTx = tx >= 0 ? tx : 0
        root.rxHistory = root.rxHistory.concat([safeRx]).slice(-root.maxPoints)
        root.txHistory = root.txHistory.concat([safeTx]).slice(-root.maxPoints)
    }

    Connections {
        target: SystemMonitor
        function onSystemChanged() {
            root.pushSample(SystemMonitor.netRxBytesPerSec, SystemMonitor.netTxBytesPerSec)
        }
    }

    Component.onCompleted: root.pushSample(SystemMonitor.netRxBytesPerSec, SystemMonitor.netTxBytesPerSec)

    ColumnLayout {
        id: innerColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: "Network"
                font.pixelSize: 20
                font.family: Config.font
                font.bold: true
                color: Colors.colors.accentAlt
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 4

                Image {
                    source: Icons.getIcon("arrowDown")
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio

                    Layout.preferredWidth: rxText.height
                    Layout.preferredHeight: rxText.height

                    fillMode: Image.PreserveAspectFit

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Colors.colors.info
                    }
                }

                Text {
                    id: rxText
                    text: Utils.formatRate(root.currentRx)
                    font.pixelSize: 16
                    font.family: Config.font
                    color: Colors.colors.foreground
                }
            }

            RowLayout {
                spacing: 4

                Image {
                    source: Icons.getIcon("arrowUp")
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio

                    Layout.preferredWidth: txText.height
                    Layout.preferredHeight: txText.height

                    fillMode: Image.PreserveAspectFit

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Colors.colors.warning
                    }
                }

                Text {
                    id: txText
                    text: Utils.formatRate(root.currentRx)
                    font.pixelSize: 16
                    font.family: Config.font
                    color: Colors.colors.foreground
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 70

            Canvas {
                id: graph
                anchors.fill: parent

                // Autoscale to the busiest sample currently on screen, with a
                // 1 KB/s floor so an idle link doesn't render as a flat line
                // pinned to the top, and some headroom so peaks don't clip.
                readonly property real maxSample: {
                    var m = 1024
                    for (var i = 0; i < root.rxHistory.length; i++) {
                        if (root.rxHistory[i] > m) m = root.rxHistory[i]
                        if (root.txHistory[i] > m) m = root.txHistory[i]
                    }
                    return m * 1.15
                }

                function drawLine(ctx, data, color, fill) {
                    if (data.length < 2) return

                    var w = width
                    var h = height
                    var stepX = w / (root.maxPoints - 1)
                    var startX = w - (data.length - 1) * stepX

                    if (fill) {
                        ctx.beginPath()
                        for (var i = 0; i < data.length; i++) {
                            var x = startX + i * stepX
                            var y = h - (data[i] / graph.maxSample) * h
                            if (i === 0) ctx.moveTo(x, y)
                            else ctx.lineTo(x, y)
                        }
                        var lastX = startX + (data.length - 1) * stepX
                        ctx.lineTo(lastX, h)
                        ctx.lineTo(startX, h)
                        ctx.closePath()

                        var grad = ctx.createLinearGradient(0, 0, 0, h)
                        grad.addColorStop(0, color)
                        grad.addColorStop(1, "transparent")
                        ctx.globalAlpha = 0.25
                        ctx.fillStyle = grad
                        ctx.fill()
                        ctx.globalAlpha = 1.0
                    }

                    ctx.beginPath()
                    for (var j = 0; j < data.length; j++) {
                        var xx = startX + j * stepX
                        var yy = h - (data[j] / graph.maxSample) * h
                        if (j === 0) ctx.moveTo(xx, yy)
                        else ctx.lineTo(xx, yy)
                    }
                    ctx.lineWidth = 2
                    ctx.lineJoin = "round"
                    ctx.strokeStyle = color
                    ctx.stroke()
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()

                    // Faint horizontal guides, purely decorative.
                    ctx.strokeStyle = Colors.colors.borderSoft
                    ctx.lineWidth = 1
                    ctx.globalAlpha = 0.35
                    for (var g = 1; g < 4; g++) {
                        var gy = (height / 4) * g
                        ctx.beginPath()
                        ctx.moveTo(0, gy)
                        ctx.lineTo(width, gy)
                        ctx.stroke()
                    }
                    ctx.globalAlpha = 1.0

                    drawLine(ctx, root.txHistory, Colors.colors.accentAlt, true)
                    drawLine(ctx, root.rxHistory, Colors.colors.info, true)
                }

                Connections {
                    target: root
                    function onRxHistoryChanged() { graph.requestPaint() }
                    function onTxHistoryChanged() { graph.requestPaint() }
                }

                Component.onCompleted: requestPaint()
            }
        }
    }
}
