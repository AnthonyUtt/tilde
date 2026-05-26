import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    function openInMode(mode) {
        if (GlobalStates.workspaceSwitcherOpen && GlobalStates.workspaceSwitcherMode === mode) {
            GlobalStates.workspaceSwitcherOpen = false;
            return;
        }
        GlobalStates.workspaceSwitcherMode = mode;
        GlobalStates.workspaceSwitcherOpen = true;
    }

    Loader {
        id: switcherLoader
        active: GlobalStates.workspaceSwitcherOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:workspaceSwitcher"
            WlrLayershell.layer: WlrLayer.Overlay
            // Hyprland 0.49: OnDemand is Exclusive (grabs focus); Exclusive just breaks
            // click-outside-to-close. See modules/sidebarLeft/SidebarLeft.qml:103.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            mask: Region {
                item: content
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.workspaceSwitcherOpen = false;
                }
            }

            WorkspaceSwitcherContent {
                id: content
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    IpcHandler {
        target: "workspaceSwitcher"

        function pick(): void {
            root.openInMode("switch");
        }
        function move(): void {
            root.openInMode("move");
        }
        function create(): void {
            root.openInMode("new");
        }
        function rename(): void {
            root.openInMode("rename");
        }
    }

    GlobalShortcut {
        name: "workspaceSwitcherSwitch"
        description: "Pick a workspace to switch to"
        onPressed: root.openInMode("switch")
    }

    GlobalShortcut {
        name: "workspaceSwitcherMove"
        description: "Move focused window to a workspace"
        onPressed: root.openInMode("move")
    }

    GlobalShortcut {
        name: "workspaceSwitcherNew"
        description: "Create and switch to a new named workspace"
        onPressed: root.openInMode("new")
    }

    GlobalShortcut {
        name: "workspaceSwitcherRename"
        description: "Rename the current workspace"
        onPressed: root.openInMode("rename")
    }
}
