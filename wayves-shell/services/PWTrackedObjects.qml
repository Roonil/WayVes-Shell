pragma Singleton

import QtQuick

import Quickshell.Services.Pipewire

Item {
    id: root
    readonly property var hardwareOutputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream).sort((n1, n2) => n1.id - n2.id)
    readonly property var hardwareInputs: Pipewire.nodes.values.filter(node => !node.isSink && !node.isStream && node.audio != null).sort((n1, n2) => n1.id - n2.id)
    readonly property var outputStreams: Pipewire.nodes.values.filter(node => node.isSink && node.isStream).sort((n1, n2) => n1.id - n2.id)
    property var inputStreams: Pipewire.nodes.values.filter(node => !node.isSink && node.isStream && node.audio != null).sort((n1, n2) => n1.id - n2.id)

    PwObjectTracker {
        id: sinkTracker
        objects: root.hardwareOutputs
    }

    PwObjectTracker {
        id: sourceTracker
        objects: root.hardwareInputs
    }

    PwObjectTracker {
        id: applicationsTracker
        objects: root.outputStreams
    }

    PwObjectTracker {
        id: applicationsInputTracker
        objects: root.inputStreams
    }
}
