import QtQuick
import "./theme"

// The actual visual lock screen, one instance per WlSessionLockSurface
// (one per monitor) — clock, password field, wrong-password flash. Same
// straight-edge/mechanical visual language as the main shell (no
// cornerRadius, ProggyClean, Theme/Metrics tokens throughout), but
// deliberately self-contained: no clock/service singletons reached in
// from home/quickshell/src/ beyond theme/ itself (see home/dotfiles.nix's
// own comment on why that boundary is explicit), so this keeps working
// even if the main shell's own process is down.
Item {
    id: root

    property var context: null

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }

    Column {
        anchors.centerIn: parent
        spacing: Metrics.spacingLg

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clockTimer.now, "hh:mm")
            color: Theme.foreground
            font.family: Metrics.fontFamily
            font.pixelSize: 64
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clockTimer.now, "dddd, d MMMM")
            color: Theme.foreground
            opacity: 0.7
            font.family: Metrics.fontFamily
            font.pixelSize: Metrics.fontSizeRegular
        }

        Rectangle {
            id: fieldBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: Metrics.moduleHeight
            color: Theme.background
            border.width: 1
            border.color: borderColor

            property color borderColor: Theme.foreground

            function flash() {
                flashFade.stop()
                borderColor = Theme.red
                flashFade.restart()
            }

            ColorAnimation {
                id: flashFade
                target: fieldBox; property: "borderColor"
                to: Theme.foreground
                duration: Metrics.settleDuration * 3
                easing.type: Easing.Linear
            }

            Connections {
                target: root.context
                function onShowFailureChanged() {
                    if (root.context.showFailure)
                        fieldBox.flash()
                }
            }

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: Metrics.spacingSm
                color: Theme.foreground
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeRegular
                echoMode: TextInput.Password
                focus: true
                enabled: root.context && !root.context.unlockInProgress

                onTextChanged: if (root.context) root.context.currentText = text
                Keys.onReturnPressed: if (root.context) root.context.tryUnlock()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (root.context.currentText === "" && passwordInput.text !== "")
                            passwordInput.text = ""
                    }
                }

                Component.onCompleted: passwordInput.forceActiveFocus()
            }
        }
    }
}
