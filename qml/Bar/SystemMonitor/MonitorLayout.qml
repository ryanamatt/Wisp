// qml/Bar/SystemMonitor/MonitorLayout.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../Components"
import "../../Colors"
import "../../Config"

ColumnLayout {
    id: rootLayout
    Layout.fillWidth: true
    spacing: 3

    property string icon: ""
    property string name: ""

    property string beforeBarText: ""
    property string afterBarText: ""

    property real barValue: -1.0
    property int warnAt: -1
    property int critAt: -1

    property int labelWidth: 100
    property int beforeTextWidth: 46
    property int afterTextWidth: 110

    // Small helper so every bar's fill color reacts to how "hot" the stat is
    function levelColor() {
        if (barValue >= rootLayout.critAt && rootLayout.critAt !== -1) return Colors.colors.error
        if (barValue >= rootLayout.warnAt && rootLayout.warnAt !== -1) return Colors.colors.warning
        return Colors.colors.accent
    }

    RowLayout {
        id: rowLayout
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            id: innerLayout
            Layout.preferredWidth: rootLayout.labelWidth
            Layout.minimumWidth: rootLayout.labelWidth
            Layout.maximumWidth: rootLayout.labelWidth
            spacing: 2

            Image {
                source: rootLayout.icon
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio

                Layout.preferredWidth: rootLayout.labelWidth * 0.25
                Layout.preferredHeight: rootLayout.labelWidth * 0.25
                Layout.fillHeight: true

                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: rootLayout.name
                color: Colors.colors.foreground
                font.bold: true
                font.pixelSize: 14
                font.family: Config.font
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Text {
            text: rootLayout.beforeBarText
            color: rootLayout.levelColor()
            font.pixelSize: 14
            font.family: Config.font
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            Layout.preferredWidth: rootLayout.beforeTextWidth
            Layout.minimumWidth: rootLayout.beforeTextWidth
            Layout.maximumWidth: rootLayout.beforeTextWidth
        }

        UsageBar {
            Layout.fillWidth: true
            barColor: Colors.colors.foregroundMuted
            barFillColor: rootLayout.levelColor()
            value: rootLayout.barValue
        }

        Text {
            text: rootLayout.afterBarText
            color: Colors.colors.foreground
            font.pixelSize: 12
            font.family: Config.font
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            Layout.preferredWidth: rootLayout.afterTextWidth
            Layout.minimumWidth: rootLayout.afterTextWidth
            Layout.maximumWidth: rootLayout.afterTextWidth
        }
    }
}
