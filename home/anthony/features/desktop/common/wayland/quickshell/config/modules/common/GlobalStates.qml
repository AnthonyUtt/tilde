pragma Singleton

import Quickshell

// Central visibility-flag store. Empty for v0 — establishes the pattern so
// future panels (sidebar, overview, lock, OSD, etc.) hoist their open/closed
// state here instead of growing local flags.
//
// Planned flags as features land:
//   property bool barOpen: true
//   property bool screenLocked: false
//   property bool superDown: false
//   property bool sidebarLeftOpen: false
//   property bool sidebarRightOpen: false
//   property bool overviewOpen: false
Singleton {
    id: root
}
