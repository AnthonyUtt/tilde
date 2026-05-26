pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var toplevels: ToplevelManager.toplevels

    // HyprlandData.workspaces is pre-filtered to ids 1-100 (lock-screen temp ids
    // and Hyprland specials are excluded). Sort by id so layout is stable.
    readonly property var sortedWorkspaces: HyprlandData.workspaces.slice().sort((a, b) => a.id - b.id)

    // Lowest positive integer N where no existing workspace is named String(N).
    // This is the label shown on the trailing placeholder cell.
    readonly property string placeholderName: {
        const used = new Set(sortedWorkspaces.map(w => w.name));
        let n = 1;
        while (used.has(String(n))) n++;
        return String(n);
    }

    readonly property var cells: [
        ...sortedWorkspaces.map(w => ({ id: w.id, name: w.name, isPlaceholder: false })),
        { id: -1, name: placeholderName, isPlaceholder: true }
    ]
    readonly property var workspaceIdSet: new Set(sortedWorkspaces.map(w => w.id))

    readonly property int columnsCount: Config.options.overview.columns
    readonly property int rowsCount: Math.max(1, Math.ceil(cells.length / columnsCount))
    // Width-wise we only allocate space for as many cells as actually exist (capped
    // by columnsCount), so the overview shrinks to fit when few workspaces are open.
    readonly property int visibleColumnsCount: Math.max(1, Math.min(cells.length, columnsCount))

    property bool monitorIsFocused: (Hyprland.focusedMonitor?.name == monitor.name)
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var windowAddresses: HyprlandData.addresses
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Appearance.colors.colSecondary

    property real workspaceImplicitWidth: (monitorData?.transform % 2 === 1) ? 
        ((monitor.height - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale) :
        ((monitor.width - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale)
    property real workspaceImplicitHeight: (monitorData?.transform % 2 === 1) ? 
        ((monitor.width - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale) :
        ((monitor.height - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale)
    property real largeWorkspaceRadius: Appearance.rounding.large
    property real smallWorkspaceRadius: Appearance.rounding.verysmall

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: 250 * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 5

    property string draggingFromWorkspaceName: ""
    property string draggingTargetWorkspaceName: ""

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []
    
    function cellIndexForWorkspaceId(id) {
        for (let i = 0; i < cells.length; i++) {
            const c = cells[i];
            if (!c.isPlaceholder && c.id === id) return i;
        }
        return -1;
    }
    function rowOfIndex(i) {
        const normal = Math.floor(i / columnsCount);
        return Config.options.overview.orderBottomUp ? rowsCount - 1 - normal : normal;
    }
    function colOfIndex(i) {
        const normal = i % columnsCount;
        return Config.options.overview.orderRightLeft ? columnsCount - 1 - normal : normal;
    }

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle { // Background
        id: overviewBackground
        property real padding: 10
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: root.largeWorkspaceRadius + padding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Item { // Workspaces
            id: workspaceColumnLayout

            z: root.workspaceZ
            anchors.centerIn: parent
            implicitWidth: root.visibleColumnsCount * root.workspaceImplicitWidth + (root.visibleColumnsCount - 1) * root.workspaceSpacing
            implicitHeight: root.rowsCount * root.workspaceImplicitHeight + (root.rowsCount - 1) * root.workspaceSpacing

            Repeater {
                model: root.cells.length
                delegate: Rectangle {
                    id: workspace
                    required property int index
                    readonly property var cell: root.cells[index]
                    readonly property int colIdx: root.colOfIndex(index)
                    readonly property int rowIdx: root.rowOfIndex(index)
                    readonly property string workspaceName: cell.name
                    readonly property int workspaceId: cell.id
                    readonly property bool isPlaceholder: cell.isPlaceholder

                    property color defaultWorkspaceColor: Appearance.colors.colSurfaceContainerLow
                    property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
                    property color hoveredBorderColor: Appearance.colors.colLayer2Hover
                    property bool hoveredWhileDragging: false

                    x: (root.workspaceImplicitWidth + root.workspaceSpacing) * colIdx
                    y: (root.workspaceImplicitHeight + root.workspaceSpacing) * rowIdx
                    implicitWidth: root.workspaceImplicitWidth
                    implicitHeight: root.workspaceImplicitHeight
                    color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor

                    // For partial last rows, the last-existing cell still acts as the
                    // right-side corner of the grid.
                    property bool workspaceAtLeft: colIdx === 0
                    property bool workspaceAtRight: (colIdx === root.columnsCount - 1) || (index === root.cells.length - 1)
                    property bool workspaceAtTop: rowIdx === 0
                    property bool workspaceAtBottom: rowIdx === root.rowsCount - 1
                    topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    topRightRadius: (workspaceAtRight && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    border.width: 2
                    border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: workspace.workspaceName
                        font {
                            pixelSize: root.workspaceNumberSize * root.scale
                            weight: Font.DemiBold
                            family: Appearance.font.family.expressive
                        }
                        color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
                        opacity: workspace.isPlaceholder ? 0.4 : 1.0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: workspaceArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onPressed: {
                            if (root.draggingTargetWorkspaceName === "") {
                                GlobalStates.overviewOpen = false
                                Hyprland.dispatch(`hl.dsp.focus({ workspace = "name:${workspace.workspaceName}" })`)
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onEntered: {
                            root.draggingTargetWorkspaceName = workspace.workspaceName
                            if (root.draggingFromWorkspaceName === root.draggingTargetWorkspaceName) return;
                            workspace.hoveredWhileDragging = true
                        }
                        onExited: {
                            workspace.hoveredWhileDragging = false
                            if (root.draggingTargetWorkspaceName === workspace.workspaceName) root.draggingTargetWorkspaceName = ""
                        }
                    }
                }
            }
        }

        Item { // Windows & focused workspace indicator
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Repeater { // Window repeater
                model: ScriptModel {
                    values: {
                        return ToplevelManager.toplevels.values.filter((toplevel) => {
                            const address = `0x${toplevel.HyprlandToplevel?.address}`
                            var win = windowByAddress[address]
                            return root.workspaceIdSet.has(win?.workspace?.id);
                        })
                    }
                }
                delegate: OverviewWindow {
                    id: window
                    required property var modelData
                    property int monitorId: windowData?.monitor
                    property var monitor: HyprlandData.monitors.find(m => m.id == monitorId)
                    property var address: `0x${modelData.HyprlandToplevel.address}`
                    toplevel: modelData
                    monitorData: this.monitor
                    scale: root.scale
                    widgetMonitor: HyprlandData.monitors.find(m => m.id == root.monitor.id)
                    windowData: windowByAddress[address]

                    property bool atInitPosition: (initX == x && initY == y)

                    // Offset on the canvas — look up the window's workspace in the
                    // dynamic cell list, fall back to (0,0) if it disappeared mid-render.
                    readonly property int wsCellIndex: root.cellIndexForWorkspaceId(windowData?.workspace.id)
                    property int workspaceColIndex: wsCellIndex >= 0 ? root.colOfIndex(wsCellIndex) : 0
                    property int workspaceRowIndex: wsCellIndex >= 0 ? root.rowOfIndex(wsCellIndex) : 0
                    xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceRowIndex
                    property real xWithinWorkspaceWidget: Math.max((windowData?.at[0] - (monitor?.x ?? 0) - monitorData?.reserved[0]) * root.scale, 0)
                    property real yWithinWorkspaceWidget: Math.max((windowData?.at[1] - (monitor?.y ?? 0) - monitorData?.reserved[1]) * root.scale, 0)

                    // Radius — match the new partial-row rule used for workspace cells.
                    property real minRadius: Appearance.rounding.small
                    property bool workspaceAtLeft: workspaceColIndex === 0
                    property bool workspaceAtRight: (workspaceColIndex === root.columnsCount - 1) || (wsCellIndex === root.cells.length - 1)
                    property bool workspaceAtTop: workspaceRowIndex === 0
                    property bool workspaceAtBottom: workspaceRowIndex === root.rowsCount - 1
                    property bool workspaceAtTopLeft: (workspaceAtLeft && workspaceAtTop) 
                    property bool workspaceAtTopRight: (workspaceAtRight && workspaceAtTop) 
                    property bool workspaceAtBottomLeft: (workspaceAtLeft && workspaceAtBottom) 
                    property bool workspaceAtBottomRight: (workspaceAtRight && workspaceAtBottom) 
                    property real distanceFromLeftEdge: xWithinWorkspaceWidget
                    property real distanceFromRightEdge: root.workspaceImplicitWidth - (xWithinWorkspaceWidget + targetWindowWidth)
                    property real distanceFromTopEdge: yWithinWorkspaceWidget
                    property real distanceFromBottomEdge: root.workspaceImplicitHeight - (yWithinWorkspaceWidget + targetWindowHeight)
                    property real distanceFromTopLeftCorner: Math.max(distanceFromLeftEdge, distanceFromTopEdge)
                    property real distanceFromTopRightCorner: Math.max(distanceFromRightEdge, distanceFromTopEdge)
                    property real distanceFromBottomLeftCorner: Math.max(distanceFromLeftEdge, distanceFromBottomEdge)
                    property real distanceFromBottomRightCorner: Math.max(distanceFromRightEdge, distanceFromBottomEdge)
                    topLeftRadius: Math.max((workspaceAtTopLeft ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromTopLeftCorner, minRadius)
                    topRightRadius: Math.max((workspaceAtTopRight ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromTopRightCorner, minRadius)
                    bottomLeftRadius: Math.max((workspaceAtBottomLeft ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromBottomLeftCorner, minRadius)
                    bottomRightRadius: Math.max((workspaceAtBottomRight ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromBottomRightCorner, minRadius)

                    Timer {
                        id: updateWindowPosition
                        interval: Config.options.hacks.arbitraryRaceConditionDelay
                        repeat: false
                        running: false
                        onTriggered: {
                            window.x = Math.round(xWithinWorkspaceWidget + xOffset)
                            window.y = Math.round(yWithinWorkspaceWidget + yOffset)
                        }
                    }

                    z: Drag.active ? root.windowDraggingZ : (root.windowZ + windowData?.floating + windowData?.fullscreen * 2)
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true // For hover color change
                        onExited: hovered = false // For hover color change
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        onPressed: (mouse) => {
                            root.draggingFromWorkspaceName = windowData?.workspace.name ?? ""
                            window.pressed = true
                            window.Drag.active = true
                            window.Drag.source = window
                            window.Drag.hotSpot.x = mouse.x
                            window.Drag.hotSpot.y = mouse.y
                        }
                        onReleased: {
                            const targetWorkspaceName = root.draggingTargetWorkspaceName
                            window.pressed = false
                            window.Drag.active = false
                            root.draggingFromWorkspaceName = ""
                            if (targetWorkspaceName !== "" && targetWorkspaceName !== (windowData?.workspace.name ?? "")) {
                                Hyprland.dispatch(`hl.dsp.window.move({ workspace = "name:${targetWorkspaceName}", follow = false, window = "address:${window.windowData?.address}" })`)
                                updateWindowPosition.restart()
                            }
                            else {
                                if (!window.windowData.floating) {
                                    updateWindowPosition.restart()
                                    return
                                }
                                const percentageX = (window.x - xOffset) / root.workspaceImplicitWidth
                                const percentageY = (window.y - yOffset) / root.workspaceImplicitHeight
                                Hyprland.dispatch(`hl.dsp.window.move({ x = "${percentageX * root.screen.width}", y = "${percentageY * root.screen.height}", window = "address:${window.windowData?.address}" })`)
                            }
                        }
                        onClicked: (event) => {
                            if (!windowData) return;

                            if (event.button === Qt.LeftButton) {
                                GlobalStates.overviewOpen = false
                                Hyprland.dispatch(`hl.dsp.focus({window = "address:${windowData.address}"})`)
                                event.accepted = true
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`hl.dsp.window.close({window = "address:${windowData.address}"})`)
                                event.accepted = true
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                            text: `${windowData?.title}\n[${windowData?.class}] ${windowData?.xwayland ? "[XWayland] " : ""}`
                        }
                    }
                }
            }

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                readonly property int activeCellIndex: root.cellIndexForWorkspaceId(root.monitor?.activeWorkspace?.id ?? -1)
                property int rowIndex: activeCellIndex >= 0 ? root.rowOfIndex(activeCellIndex) : 0
                property int colIndex: activeCellIndex >= 0 ? root.colOfIndex(activeCellIndex) : 0
                visible: activeCellIndex >= 0
                x: (root.workspaceImplicitWidth + workspaceSpacing) * colIndex
                y: (root.workspaceImplicitHeight + workspaceSpacing) * rowIndex
                z: root.windowZ
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                color: "transparent"
                property bool workspaceAtLeft: colIndex === 0
                property bool workspaceAtRight: (colIndex === root.columnsCount - 1) || (activeCellIndex === root.cells.length - 1)
                property bool workspaceAtTop: rowIndex === 0
                property bool workspaceAtBottom: rowIndex === root.rowsCount - 1
                topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                topRightRadius: (workspaceAtRight && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                border.width: 2
                border.color: root.activeBorderColor
                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on topLeftRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on topRightRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on bottomLeftRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on bottomRightRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
            }
        }
    }
}
