// qml/Bar/Weather/WeatherPopup.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../Colors"
import "../../Config"
import "../../Icons"

BarPopup {
    id: weatherPopup

    signal requestClose()

    // ----- State (shared via WeatherSingleton so it stays in sync across monitors) -----
    readonly property bool hasLocation: Config.getWeatherFromIp || Config.weatherCity.trim() !== ""
    readonly property var hourly: WeatherSingleton.hourly
    readonly property bool hasData: hourly.length > 0
    readonly property bool fetchFailed: WeatherSingleton.fetchFailed

    readonly property string locationLabel: WeatherSingleton.locationName !== ""
        ? WeatherSingleton.locationName
        : (Config.weatherCity.trim() !== "" ? Config.weatherCity.trim() : "Current location")

    function closePopup() {
        weatherPopup.requestClose()
    }

    function refreshAll() {
        WeatherSingleton.refreshIfStale()
    }

    function forceRefresh() {
        WeatherSingleton.refresh()
    }

    function resetScroll() {
        listView.contentX = 0
    }

    // Moves the hourly row by dx pixels, staying inside its bounds.
    function scrollBy(dx) {
        const maxX = Math.max(0, listView.contentWidth - listView.width)
        listView.contentX = Math.max(0, Math.min(maxX, listView.contentX + dx))
    }

    Keys.onEscapePressed: weatherPopup.closePopup()
    Keys.onLeftPressed: weatherPopup.scrollBy(-listView.width / 2)
    Keys.onRightPressed: weatherPopup.scrollBy(listView.width / 2)

        ColumnLayout {
        id: rootLayout
        anchors.fill: parent
        spacing: 8

        // ----- Header: current conditions -----
        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(rootLayout.height * 0.27)
            radius: 8
            color: Colors.colors.surfaceAlt
            border.width: 1
            border.color: Colors.colors.borderSoft
            visible: weatherPopup.hasLocation && weatherPopup.hasData

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                Image {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: header.height * 0.7
                    Layout.preferredHeight: width
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio
                    source: {
                        const icon = WeatherSingleton.getWeatherIcon(WeatherSingleton.weatherCode, WeatherSingleton.weatherIsDay)
                        return icon === "" ? "" : Icons.getIcon("weather/" + icon)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: WeatherSingleton.weatherTemp + "°F"
                            color: Colors.colors.foreground
                            font.pixelSize: Math.round(header.height * 0.38)
                            font.family: Config.font
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: WeatherSingleton.describe(WeatherSingleton.weatherCode)
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: Math.max(11, Math.round(header.height * 0.26))
                            font.family: Config.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: weatherPopup.locationLabel
                            + "  H:" + WeatherSingleton.highTemp + "°  L:" + WeatherSingleton.lowTemp + "°"
                        color: Colors.colors.foregroundSubtle
                        font.pixelSize: Math.max(10, Math.round(header.height * 0.22))
                        font.family: Config.font
                        elide: Text.ElideRight
                    }
                }

                Image {
                    id: refreshIcon
                    source: Icons.getIcon("ui/refresh")
                    Layout.alignment: Qt.AlignVCenter

                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio

                    Layout.preferredWidth: header.height * 0.4
                    Layout.preferredHeight: width

                    rotation: 0

                    RotationAnimation on rotation {
                        id: spinAnimation
                        target: refreshIcon
                        from: 0
                        to: 360
                        duration: 600
                        running: false
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            spinAnimation.restart()
                            weatherPopup.forceRefresh()
                        }
                    }
                }
            }
        }

        // ----- Hourly forecast (scrolls horizontally) -----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: weatherPopup.hasLocation && weatherPopup.hasData

            // Four cards plus half of a fifth, so it is obvious the row scrolls.
            readonly property real cardSpacing: 6
            readonly property real cardWidth: (listView.width - 4 * cardSpacing) / 4.5

            ListView {
                id: listView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: scrollTrack.top
                anchors.bottomMargin: 4

                orientation: ListView.Horizontal
                spacing: parent.cardSpacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: weatherPopup.hourly

                // Lets a normal mouse wheel scroll sideways. Touchpad
                // horizontal swipes are handled natively by the flickable.
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        if (event.angleDelta.y === 0) {
                            event.accepted = false
                            return
                        }
                        weatherPopup.scrollBy(-event.angleDelta.y)
                    }
                }

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property bool isNow: index === 0

                    width: listView.parent.cardWidth
                    height: listView.height
                    radius: 10
                    color: isNow ? Colors.colors.selected
                         : cardHover.hovered ? Colors.colors.hover
                         : Colors.colors.surface
                    border.width: 1
                    border.color: isNow ? Colors.colors.borderActive : Colors.colors.borderSoft

                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: cardHover }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        spacing: 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: card.isNow ? "Now" : WeatherSingleton.formatHour(card.modelData.hour)
                            color: card.isNow ? Colors.colors.foreground : Colors.colors.foregroundMuted
                            font.pixelSize: Math.max(10, Math.round(card.width * 0.17))
                            font.family: Config.font
                        }

                        Item { Layout.fillHeight: true }

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: card.width * 0.55
                            Layout.preferredHeight: width
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: width * Screen.devicePixelRatio
                            sourceSize.height: height * Screen.devicePixelRatio
                            source: {
                                const icon = WeatherSingleton.getWeatherIcon(card.modelData.code, card.modelData.isDay)
                                return icon === "" ? "" : Icons.getIcon("weather/" + icon)
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: card.modelData.temp + "°"
                            color: Colors.colors.foreground
                            font.pixelSize: Math.max(12, Math.round(card.width * 0.22))
                            font.family: Config.font
                            font.bold: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: card.modelData.precip + "%"
                            color: card.modelData.precip >= 30 ? Colors.colors.info : Colors.colors.foregroundSubtle
                            font.pixelSize: Math.max(10, Math.round(card.width * 0.16))
                            font.family: Config.font
                        }
                    }
                }
            }

            // Thin position indicator under the row, only when it can scroll.
            Rectangle {
                id: scrollTrack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 3
                radius: 1.5
                color: Colors.colors.borderSoft
                opacity: 0.5
                visible: listView.contentWidth > listView.width

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * listView.visibleArea.widthRatio
                    x: parent.width * listView.visibleArea.xPosition
                    color: Colors.colors.foregroundSubtle
                }
            }
        }

        // ----- Empty / error states -----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !weatherPopup.hasLocation || !weatherPopup.hasData

            Text {
                anchors.centerIn: parent
                width: parent.width * 0.85
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Colors.colors.foregroundMuted
                font.pixelSize: 12
                font.family: Config.font
                text: !weatherPopup.hasLocation ? "Set a weather location in Settings"
                    : weatherPopup.fetchFailed ? "Couldn't load the forecast"
                    : "Loading forecast..."
            }
        }

        // ----- Stale data notice (shown only if a refresh failed but old data is on screen) -----
        Text {
            Layout.fillWidth: true
            visible: weatherPopup.hasData && weatherPopup.fetchFailed
            text: "Couldn't refresh. Showing the last forecast."
            color: Colors.colors.error
            font.pixelSize: 11
            font.family: Config.font
            wrapMode: Text.WordWrap
        }
    }
}

