// qml/CommandCenter/SettingsSection/SettingsSection.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Config"
import "SettingsComponents"
import "BarSubSection"
import "ThemeSubSection"
import "FontSubSection"
import "BatterySubSection"
import "PackagesSubSection"
import "NotificationsSubSection"
import "WelcomeSubSection"
import "OSDSubSection"

ColumnLayout {
    id: root

    anchors.fill: parent
    clip: true
    spacing: 20

    // ----- Outline state -----
    // Every SettingsSubSection placed directly inside `contentColumn` below is
    // picked up automatically, so adding one needs no outline changes.
    readonly property var subSections: collectSubSections()
    property int activeIndex: 0

    // After an outline click the clicked entry stays highlighted until the user
    // scrolls somewhere else. Without this, short sections near the bottom could
    // never become "active" because the view cannot scroll far enough.
    property int pinnedIndex: -1
    property real pinnedY: 0

    function collectSubSections() {
        const result = []
        if (!contentColumn) return result
        const kids = contentColumn.children
        for (let i = 0; i < kids.length; i++) {
            if (kids[i].isSubSection) result.push(kids[i])
        }
        return result
    }

    function maxScrollY() {
        return Math.max(0, flick.contentHeight - flick.height)
    }

    function scrollToSection(index) {
        const target = subSections[index]
        if (!target) return

        const y = Math.min(target.y, maxScrollY())
        pinnedIndex = index
        pinnedY = y
        activeIndex = index

        flick.cancelFlick()
        scrollAnim.stop()
        scrollAnim.from = flick.contentY
        scrollAnim.to = y
        scrollAnim.start()
    }

    function updateActive() {
        if (subSections.length === 0) return

        if (pinnedIndex >= 0) {
            if (scrollAnim.running || Math.abs(flick.contentY - pinnedY) < 2) {
                activeIndex = pinnedIndex
                return
            }
            pinnedIndex = -1
        }

        const probe = flick.contentY + 24
        let idx = 0
        for (let i = 0; i < subSections.length; i++) {
            if (subSections[i].y <= probe) idx = i
        }
        if (maxScrollY() > 0 && flick.contentY >= maxScrollY() - 2) {
            idx = subSections.length - 1
        }
        activeIndex = idx
    }

    onSubSectionsChanged: updateActive()
    Component.onCompleted: updateActive()

    // ----- Header -----
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Wisp Settings"
            font.pixelSize: 25
            font.family: Config.font
            font.bold: true
            color: Colors.colors.accent
        }

        Text {
            text: "Customize Wisp to Your Heart's Delight!"
            font.pixelSize: 10
            font.family: Config.font
            color: Colors.colors.accent
        }
    }

    // ----- Outline + settings -----
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        SettingsOutline {
            Layout.preferredWidth: 120
            Layout.fillHeight: true
            Layout.leftMargin: 4

            model: root.subSections
            activeIndex: root.activeIndex
            onEntryClicked: (index) => root.scrollToSection(index)
        }

        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            onContentYChanged: root.updateActive()
            onContentHeightChanged: root.updateActive()
            onHeightChanged: root.updateActive()

            NumberAnimation {
                id: scrollAnim
                target: flick
                property: "contentY"
                duration: 250
                easing.type: Easing.OutCubic
            }

            ColumnLayout {
                id: contentColumn

                // Leaves a little room so the scrollbar never overlaps content
                width: flick.width - 12
                spacing: 20

                BarSubSection {}
                ThemeSubSection {}
                FontSubSection {}
                BatterySubSection {}
                PackagesSubSection {}
                NotificationsSubSection {}
                WelcomeSubSection {}
                OSDSubSection {}

            }
        }
    }

    // ----- Global save bar -----
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.bottomMargin: 10
        spacing: 10

        Rectangle {
            id: saveButton

            readonly property bool active: Config.dirty

            Layout.preferredWidth: 100
            Layout.preferredHeight: 32
            radius: 8

            color: active ? (saveArea.pressed ? Colors.colors.accentAlt : Colors.colors.accent)
                          : Colors.colors.surfaceAlt
            border.width: 1
            border.color: active ? Colors.colors.borderActive : Colors.colors.border

            Text {
                anchors.centerIn: parent
                text: "Save"
                font.pixelSize: 13
                font.bold: true
                font.family: Config.font
                color: saveButton.active ? Colors.colors.background : Colors.colors.foregroundMuted
            }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                enabled: saveButton.active
                cursorShape: saveButton.active ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Config.save()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Config.dirty
            text: "You have unsaved changes"
            font.pixelSize: 11
            font.family: Config.font
            color: Colors.colors.warning
        }
    }
}
