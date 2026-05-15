pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50

    FileView {
        id: fileView
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
                root.ready = true;
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            property JsonObject bar: JsonObject {
                property int width: 36
                property int margin: 8
                property int cornerRadius: 16
            }

            property JsonObject clock: JsonObject {
                property bool use24Hour: true
            }
        }
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: fileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: fileView.writeAdapter()
    }
}
