pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string xdgConfigHome: {
        const v = Quickshell.env("XDG_CONFIG_HOME");
        return (v && v.length > 0) ? v : home + "/.config";
    }
    readonly property string xdgStateHome: {
        const v = Quickshell.env("XDG_STATE_HOME");
        return (v && v.length > 0) ? v : home + "/.local/state";
    }
    readonly property string xdgCacheHome: {
        const v = Quickshell.env("XDG_CACHE_HOME");
        return (v && v.length > 0) ? v : home + "/.cache";
    }

    readonly property string shellName: "quickshell"
    readonly property string shellConfigPath: xdgConfigHome + "/" + shellName + "/config.json"
    readonly property string shellStateDir: xdgStateHome + "/" + shellName
}
