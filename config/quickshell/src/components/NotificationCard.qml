import QtQuick
import Quickshell.Services.Notifications
import "../"

// Shared visual for one notification — used by both popups/NotificationCenter.qml
// (a list of these) and popups/NotificationToast.qml (a stack of these), so both
// look and animate identically instead of drifting apart. This is the concrete
// reason Metrics gained a real typography/spacing scale instead of more
// ad hoc pixelSize values like modules/Clock.qml or popups/Picker.qml have.
Rectangle {
    id: root

    required property Notification notification
    // Toast cards are standalone floating elements and want their own
    // frame; NotificationCenter's list rows sit inside a panel that
    // already has one, so it turns this off to avoid nested boxes.
    property bool bordered: true

    implicitWidth: 320
    implicitHeight: body.implicitHeight + Metrics.spacingMd * 2
    radius: Metrics.cornerRadius
    color: Theme.background
    border.width: bordered ? 1 : 0
    border.color: Theme.foreground

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Metrics.spacingMd
        spacing: Metrics.spacingXs

        Item {
            width: parent.width
            height: Math.max(appNameText.implicitHeight, dismissBtn.implicitHeight)

            Text {
                id: appNameText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.notification.appName
                color: Theme.accent
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeSmall
            }

            IconBtn {
                id: dismissBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: "×" // ×
                onClicked: root.notification.dismiss()
            }
        }

        Text {
            width: parent.width
            text: root.notification.summary
            color: root.notification.urgency === NotificationUrgency.Critical ? Theme.red : Theme.foreground
            font.family: Metrics.fontFamily
            font.pixelSize: Metrics.fontSizeRegular
            wrapMode: Text.WordWrap
        }

        Text {
            visible: root.notification.body.length > 0
            width: parent.width
            text: root.notification.body
            color: Theme.foreground
            opacity: 0.75
            font.family: Metrics.fontFamily
            font.pixelSize: Metrics.fontSizeSmall
            wrapMode: Text.WordWrap
        }

        Row {
            visible: root.notification.actions.length > 0
            spacing: Metrics.spacingSm

            Repeater {
                model: root.notification.actions

                delegate: Rectangle {
                    id: actionBtn
                    required property NotificationAction modelData

                    implicitWidth: actionLabel.implicitWidth + Metrics.spacingMd
                    implicitHeight: actionLabel.implicitHeight + Metrics.spacingXs
                    radius: Metrics.cornerRadius
                    color: actionHover.hovered ? Theme.accent : "transparent"
                    border.width: 1
                    border.color: Theme.accent

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionBtn.modelData.text
                        color: Theme.foreground
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeSmall
                    }

                    HoverHandler { id: actionHover }
                    TapHandler { onTapped: actionBtn.modelData.invoke() }
                }
            }
        }
    }
}
