import QtQuick
import Quickshell.Hyprland
import "../"
import "../components"

// The left hanging module: this screen's workspaces, active one in
// Theme.accent, click a number to switch to it. Filtered from the global
// Hyprland.workspaces model down to just this monitor's — required on a
// multi-monitor setup, harmless on a single-monitor one.
HangingModule {
    id: root

    align: "left"
    boxWidth: workspaceRow.implicitWidth + Metrics.spacingMd * 2

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Metrics.spacingSm

        Repeater {
            model: Hyprland.workspaces

            delegate: Text {
                id: wsText
                required property var modelData

                visible: modelData.monitor === Hyprland.monitorFor(root.screen)
                text: modelData.id
                color: modelData.active ? Theme.accent : Theme.foreground
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeRegular

                TapHandler {
                    onTapped: Hyprland.dispatch("workspace " + wsText.modelData.id)
                }
            }
        }
    }
}
