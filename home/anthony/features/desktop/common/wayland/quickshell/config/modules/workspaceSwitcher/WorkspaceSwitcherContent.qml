import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    // When the PanelWindow becomes active, Qt walks focus down to the root of the
    // window's content tree — i.e. this Item. Hand it off to the input here, and
    // catch any stray key in Keys.onPressed so even the first keystroke lands in
    // the field if focus hasn't fully settled yet.
    focus: true
    onFocusChanged: focus => {
        if (focus) inputField.forceActiveFocus();
    }
    Keys.onPressed: inputField.forceActiveFocus()

    readonly property string mode: GlobalStates.workspaceSwitcherMode
    readonly property bool isListMode: mode === "switch" || mode === "move"

    readonly property string headerText: {
        switch (mode) {
        case "switch": return Translation.tr("Switch to workspace");
        case "move":   return Translation.tr("Move window to workspace");
        case "new":    return Translation.tr("New workspace");
        case "rename": return Translation.tr("Rename current workspace");
        default: return "";
        }
    }

    readonly property string inputPlaceholder: {
        switch (mode) {
        case "switch": return Translation.tr("Workspace name");
        case "move":   return Translation.tr("Workspace name (type to create)");
        case "new":    return Translation.tr("New workspace name");
        case "rename": {
            const cur = HyprlandData.activeWorkspace?.name ?? "";
            return cur ? Translation.tr("Rename \"%1\" to…").arg(cur) : Translation.tr("New name");
        }
        default: return "";
        }
    }

    readonly property var prepped: HyprlandData.workspaces.map(ws => ({
        nameKey: Fuzzy.prepare(ws.name),
        entry: ws
    }))

    readonly property var filtered: {
        if (!isListMode) return [];
        const q = inputField.text;
        if (q.length === 0) return HyprlandData.workspaces;
        return Fuzzy.go(q, prepped, { all: true, key: "nameKey" })
            .map(r => r.obj.entry);
    }

    function sanitize(s) {
        return s.replace(/["\n\r]/g, "").trim();
    }

    function confirm() {
        const query = sanitize(inputField.text);
        const m = mode;

        if (m === "switch") {
            const picked = root.filtered[wsList.currentIndex];
            if (!picked) return;
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "name:${picked.name}" })`);
        } else if (m === "move") {
            let target = root.filtered[wsList.currentIndex]?.name;
            if (!target) {
                if (query.length === 0) return;
                target = query.replace(/:new$/, "");
            }
            Hyprland.dispatch("focuscurrentorlast");
            Hyprland.dispatch(`movetoworkspace name:${target}`);
        } else if (m === "new") {
            if (query.length === 0) return;
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "name:${query}" })`);
        } else if (m === "rename") {
            const id = HyprlandData.activeWorkspace?.id;
            if (id == null || query.length === 0) return;
            // Refuse on special / out-of-range workspaces.
            if (!HyprlandData.workspaceIds.includes(id)) return;
            Hyprland.dispatch(`renameworkspace ${id} ${query}`);
        }

        GlobalStates.workspaceSwitcherOpen = false;
    }

    function focusInput() {
        inputField.text = "";
        wsList.currentIndex = 0;
        inputField.forceActiveFocus();
    }

    onModeChanged: focusInput()

    implicitWidth: card.width + Appearance.sizes.elevationMargin * 2
    implicitHeight: card.implicitHeight + Appearance.sizes.elevationMargin * 2

    StyledRectangularShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Appearance.sizes.elevationMargin
        }
        width: 480
        clip: true
        radius: Appearance.rounding.normal
        color: Appearance.colors.colBackgroundSurfaceContainer
        implicitHeight: cardLayout.implicitHeight

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: cardLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 10
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                horizontalAlignment: Text.AlignHCenter
                text: root.headerText
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
            }

            ToolbarTextField {
                id: inputField
                focus: GlobalStates.workspaceSwitcherOpen
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 12
                placeholderText: root.inputPlaceholder
                font.pixelSize: Appearance.font.pixelSize.small

                onAccepted: root.confirm()

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.workspaceSwitcherOpen = false;
                        event.accepted = true;
                        return;
                    }
                    if (!root.isListMode) return;
                    if (event.key === Qt.Key_Down) {
                        wsList.currentIndex = Math.min(wsList.count - 1, wsList.currentIndex + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        wsList.currentIndex = Math.max(0, wsList.currentIndex - 1);
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                visible: root.isListMode && wsList.count > 0
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.preferredHeight: 1
                color: Appearance.colors.colOutlineVariant
            }

            ListView {
                id: wsList
                visible: root.isListMode
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 6
                Layout.bottomMargin: 12
                Layout.preferredHeight: root.isListMode ? Math.min(360, contentHeight + topMargin + bottomMargin) : 0
                clip: true
                spacing: 2
                currentIndex: 0
                highlightMoveDuration: 100
                topMargin: 4
                bottomMargin: 4
                ScrollBar.vertical: ScrollBar {}

                model: root.filtered

                delegate: Rectangle {
                    id: itemRect
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    implicitHeight: 36
                    radius: Appearance.rounding.small
                    color: index === wsList.currentIndex
                        ? Appearance.colors.colLayer2
                        : (itemMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    StyledText {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        text: itemRect.modelData?.name ?? ""
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    StyledText {
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            rightMargin: 14
                        }
                        text: "#" + (itemRect.modelData?.id ?? "")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        opacity: 0.65
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            wsList.currentIndex = itemRect.index;
                            root.confirm();
                        }
                    }
                }
            }
        }
    }
}
