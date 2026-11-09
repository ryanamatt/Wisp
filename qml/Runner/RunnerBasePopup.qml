// qml/Runner/RunnerBasePopup.qml

import QtQuick
import Quickshell
import "../Colors"
import "../Config"

PanelWindow {
    id: root

    // Children of a subclass go into the content area.
    default property alias content: contentArea.data

    // ---- Inputs ----
    // True while the popup should be showing.
    property bool open: false

    // Geometry of the Runner this popup hangs from.
    property int runnerWidth: 400
    property int runnerHeight: 100
    property int runnerTopMargin: 0

    // ---- Tweakables ----
    property int popupWidth: runnerWidth
    property int popupHeight: 340
    property int bottomRadius: 30
    property int sidePadding: 14

    // Animation timing. Corners square off first, then the card slides.
    property int cornerDuration: 90
    property int openSlideDuration: 320
    property int closeSlideDuration: 200

    // How long to wait after `open` goes false before closing. Zero closes
    // right away. Useful when `open` can flicker while the user is typing.
    property int closeDelay: 0

    // Content area padding. Set both to 0 for free-form content.
    property int contentTopMargin: borderWidth * 2 + 6
    property int contentSideMargin: sidePadding + borderWidth

    // ---- Footer (optional) ----
    property bool showFooter: false
    property int footerHeight: 44
    property string footerText: ""
    property string footerHint: ""
    property bool footerHintVisible: false
    property color footerHintColor: Colors.colors.accent

    // ---- Empty state (optional) ----
    // Shown centred in the content area, for when there is nothing to list.
    property bool emptyVisible: false
    property string emptyText: ""

    readonly property int borderWidth: 2

    // ---- Animation state (also read by Runner.qml) ----
    property real cornerProgress: 0
    property real slideProgress: 0

    // ---- Internals ----
    property bool expanded: false

    function setExpanded(value) {
        if (value === expanded) return;
        expanded = value;

        openAnim.stop();
        closeAnim.stop();

        // Scale durations by the distance left so interrupting is seamless.
        if (value) {
            openCorners.duration = Math.round(cornerDuration * (1 - cornerProgress));
            openSlide.duration = Math.round(openSlideDuration * (1 - slideProgress));
            openAnim.start();
        } else {
            closeSlide.duration = Math.round(closeSlideDuration * slideProgress);
            closeCorners.duration = Math.round(cornerDuration * cornerProgress);
            closeAnim.start();
        }
    }

    // Jump straight to closed with no animation (used when the Runner hides).
    function snapClosed() {
        closeTimer.stop();
        openAnim.stop();
        closeAnim.stop();
        expanded = false;
        cornerProgress = 0;
        slideProgress = 0;
    }

    // Subclasses can add their own onOpenChanged handler as well, both run.
    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            setExpanded(true);
        } else if (closeDelay > 0) {
            closeTimer.restart();
        } else {
            setExpanded(false);
        }
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: root.setExpanded(false)
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation {
            id: openCorners
            target: root; property: "cornerProgress"
            to: 1; duration: root.cornerDuration; easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            id: openSlide
            target: root; property: "slideProgress"
            to: 1; duration: root.openSlideDuration; easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            id: closeSlide
            target: root; property: "slideProgress"
            to: 0; duration: root.closeSlideDuration; easing.type: Easing.InCubic
        }
        NumberAnimation {
            id: closeCorners
            target: root; property: "cornerProgress"
            to: 0; duration: root.cornerDuration; easing.type: Easing.InOutQuad
        }
    }

    // ---- Window ----
    visible: expanded || cornerProgress > 0 || slideProgress > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true }
    // Overlap the Runner by one border width so the two borders merge.
    margins.top: runnerTopMargin + runnerHeight - borderWidth

    implicitWidth: popupWidth
    implicitHeight: popupHeight

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: card
            visible: root.slideProgress > 0

            width: parent.width
            // Extra border width on top, pushed above the clip edge, so only
            // the side and bottom borders are visible.
            height: root.popupHeight + root.borderWidth
            y: -root.borderWidth - (1 - root.slideProgress) * root.popupHeight

            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.background
            border.width: root.borderWidth

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.bottomRadius
            bottomRightRadius: root.bottomRadius

            // ---- Body, where subclass content goes ----
            Item {
                id: contentArea
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: root.contentTopMargin
                    leftMargin: root.contentSideMargin
                    rightMargin: root.contentSideMargin
                    bottomMargin: root.showFooter ? root.footerHeight + root.borderWidth : 0
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    visible: root.emptyVisible
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Colors.colors.foregroundSubtle
                    font.pixelSize: 14
                    font.family: Config.font
                    text: root.emptyText
                }
            }

            // ---- Footer: details of the highlighted item ----
            Item {
                id: footer
                visible: root.showFooter
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: root.borderWidth
                }
                height: root.footerHeight

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.bottomRadius
                    anchors.rightMargin: root.bottomRadius
                    height: 1
                    color: Colors.colors.border
                    opacity: 0.6
                }

                Text {
                    id: hintLabel
                    anchors.right: parent.right
                    anchors.rightMargin: root.bottomRadius
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    visible: root.footerHintVisible
                    text: root.footerHint
                    color: root.footerHintColor
                    font.pixelSize: 12
                    font.family: Config.font
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.bottomRadius
                    anchors.right: hintLabel.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    text: root.footerText
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 14
                    font.family: Config.font
                    elide: Text.ElideRight
                }
            }
        }
    }
}
