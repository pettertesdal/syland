import Quickshell
import QtQuick
import "./src/windows"
import "./src/popups"
import "./src/"

ShellRoot {
    property var _ipc: IpcManager
    property var _notifications: NotificationService

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                required property var modelData

                LeftModule { screen: modelData }
                CenterModule {
                    id: centerModule
                    screen: modelData
                    picker: picker
                }
                RightModule {
                    id: rightModule
                    screen: modelData
                    bluetoothPanel: bluetoothPanel
                }
                MusicModule { align: "left"; screen: modelData; centerModule: centerModule }
                MusicModule { align: "right"; screen: modelData; centerModule: centerModule }
                StatsModule { align: "left"; screen: modelData }
                StatsModule { align: "right"; screen: modelData }

                Border { screen: modelData; edge: "left" }
                Border { screen: modelData; edge: "right" }
                Border { screen: modelData; edge: "bottom" }

                ExamplePanel { screen: modelData }
                NotificationCenter {
                    id: notificationCenter
                    screen: modelData
                }
                NotificationLight {
                    id: notificationLight
                    screen: modelData
                    notificationCenter: notificationCenter
                }
                NotificationToast { screen: modelData }
                ThemeSwitcher { screen: modelData }
                TodoPanel { screen: modelData }
                BluetoothPanel {
                    id: bluetoothPanel
                    screen: modelData
                    notificationLight: notificationLight
                }

                Picker {
                    id: picker
                    screen: modelData
                    centerModule: centerModule
                }
            }
        }
    }
}
