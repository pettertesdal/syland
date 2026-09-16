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
                }
                RightModule { screen: modelData }

                Border { screen: modelData; edge: "left" }
                Border { screen: modelData; edge: "right" }
                Border { screen: modelData; edge: "bottom" }

                ExamplePanel { screen: modelData }
                NotificationCenter { screen: modelData }
                NotificationToast { screen: modelData }
                ThemeSwitcher { screen: modelData }
                TodoPanel { screen: modelData }
                BluetoothPanel { screen: modelData }

                Picker {
                    targetWindow: centerModule
                }
            }
        }
    }
}
