
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../IpcState"
import "../Colors"
import "../Config"
import Wisp.Calculator

Scope {
    id: runnerScope

    property var targetScreen: {
        let focusedName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focusedName)
                return Quickshell.screens[i];
        }
        return Quickshell.screens[0];
    }

    readonly property int runnerWidth: 400
    readonly property int runnerHeight: 100

    property string runnerText: ""

    // Current mode, decided by the first character of the text field.
    // "none" | "command" | "calculator"
    readonly property string mode: {
        const first = runnerText.charAt(0);
        if (first === ">") return "command";
        if (first === "=") return "calculator";
        return "none";
    }

    // Calculator state that feeds RunnerCalcPopup.
    property bool calcSolvable: false
    property string calcExpression: ""
    property real calcAnswer: 0

    function updateCalc() {
        calcSolvable = false;
        if (mode !== "calculator") return;

        const expr = runnerText.slice(1);
        // Ignore empty input and input with no digits at all.
        if (!/\d/.test(expr)) return;

        if (Calculator.solve(expr)) {
            // Answer has no change signal, so read it right after solve().
            calcExpression = expr;
            calcAnswer = Calculator.answer;
            calcSolvable = true;
        }
    }

    PanelWindow {
        id: runner
        focusable: true
        screen: targetScreen

        visible: IpcState.runner.isOpen
        
        implicitWidth: runnerScope.runnerWidth
        implicitHeight: runnerScope.runnerHeight

        anchors { top: true; }
        margins.top: (runner.screen ? runner.screen.height : 1000) / 20

        color: "transparent"

        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: {
            if (visible) {
                textField.forceActiveFocus()
                textField.selectAll()
            } else {
                runnerScope.runnerText = ""
                runnerScope.calcSolvable = false
                calcPopup.snapClosed()
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: IpcState.runner.close()

            Rectangle {
                id: rect
                anchors.fill: parent

                radius: rect.width / 5
                // Bottom corners square off as the calculator popup opens.
                bottomLeftRadius: rect.height / 2 * (1 - calcPopup.cornerProgress)
                bottomRightRadius: rect.height / 2 * (1 - calcPopup.cornerProgress)

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                ColumnLayout {
                    id: root
                    anchors.fill: parent
                    
                    Layout.margins: 0
                    spacing: -25

                    Text { 
                        id: headerText
                        Layout.alignment: Qt.AlignHCenter
                        text: "Wisp Runner"
                        color: Colors.colors.accent
                        font.pixelSize: root.width * 0.05
                        font.bold: true
                        font.family: Config.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter 
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        spacing: 8

                        ModeBadge {
                            mode: runnerScope.mode
                            Layout.preferredWidth: textField.implicitHeight
                            Layout.preferredHeight: textField.implicitHeight
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextField {
                            id: textField

                            Layout.fillWidth: true
                            implicitHeight: root.height / 3
                            leftPadding: 15

                            text: runnerScope.runnerText
                            selectByMouse: true

                            font.pixelSize: 15
                            font.family: Config.font
                            color: Colors.colors.foreground
                            verticalAlignment: TextInput.AlignVCenter

                            background: Rectangle {
                                color: Colors.colors.surfaceAlt
                                border.width: 2
                                radius: textField.width / 5
                                border.color: textField.activeFocus ? Colors.colors.borderActive : Colors.colors.border
                            }

                            onTextEdited: {
                                runnerScope.runnerText = text
                                runnerScope.updateCalc()
                            }

                        }
                        
                    }

                }
            }

        }

    }

    RunnerCalcPopup {
        id: calcPopup
        screen: runnerScope.targetScreen
        runnerWidth: runnerScope.runnerWidth
        runnerHeight: runnerScope.runnerHeight
        runnerTopMargin: runner.margins.top
        open: runner.visible && runnerScope.calcSolvable
        expression: runnerScope.calcExpression
        answer: runnerScope.calcAnswer
    }

}
