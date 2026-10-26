pragma Singleton

import QtQuick

import Quickshell.Io

Item {
    id: root
    property var userFullName: null
    Process {
        id: fullNameFetcher

        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d ':' -f 5 | cut -d ',' -f 1"]

        running: true

        stdout: StdioCollector {
            onTextChanged: {
                if (text.trim() !== "") {
                    root.userFullName = text.trim();
                }
            }
        }
    }
}
