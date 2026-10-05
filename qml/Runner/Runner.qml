
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
        if (first === ":") return "symbol"
        return "none";
    }

    // Calculator state that feeds RunnerCalcPopup.
    property bool calcSolvable: false
    property string calcExpression: ""
    property real calcAnswer: 0

    // Bottom corners square off as either popup opens.
    readonly property real popupCorners: Math.max(calcPopup.cornerProgress, symbolPopup.cornerProgress)

    function updateCalc() {
        calcSolvable = false;
        if (mode !== "calculator") return;

        const expr = runnerText.slice(1);
        if (expr.trim() === "") return;

        if (Calculator.solve(expr)) {
            // Answer has no change signal, so read it right after solve().
            calcExpression = expr;
            calcAnswer = Calculator.answer;
            calcSolvable = true;
        }
    }

    // Command mode: hand everything after the ">" to bash and close.
    // execDetached keeps the process alive after the Runner goes away.
    function runCommand() {
        const cmd = runnerText.slice(1).trim();
        if (cmd === "") return;

        Quickshell.execDetached(["bash", "-c", cmd]);
        IpcState.runner.close();
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
                symbolPopup.snapClosed()
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
                // Bottom corners square off as a popup opens.
                bottomLeftRadius: rect.height / 2 * (1 - runnerScope.popupCorners)
                bottomRightRadius: rect.height / 2 * (1 - runnerScope.popupCorners)

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
                            rightPadding: leftPadding

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

                            // The text field keeps focus, so forward keys to
                            // whichever mode is active.
                            Keys.onPressed: event => {
                                if (runnerScope.mode === "command") {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        runnerScope.runCommand();
                                        event.accepted = true;
                                    }
                                    return;
                                }

                                if (runnerScope.mode !== "symbol") return;
                                switch (event.key) {
                                case Qt.Key_Down:    symbolPopup.move(0, 1);  event.accepted = true; break;
                                case Qt.Key_Up:      symbolPopup.move(0, -1); event.accepted = true; break;
                                case Qt.Key_Tab:     symbolPopup.move(1, 0);  event.accepted = true; break;
                                case Qt.Key_Backtab: symbolPopup.move(-1, 0); event.accepted = true; break;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:   symbolPopup.activate();  event.accepted = true; break;
                                }
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

    RunnerSymbolPopup {
        id: symbolPopup
        screen: runnerScope.targetScreen
        runnerWidth: runnerScope.runnerWidth
        runnerHeight: runnerScope.runnerHeight
        runnerTopMargin: runner.margins.top
        open: runner.visible && runnerScope.mode === "symbol"
        query: runnerScope.mode === "symbol" ? runnerScope.runnerText.slice(1) : ""
        onSymbolCopied: IpcState.runner.close()
    }

}
