import QtQml 2.0
QtObject { default property list<QtObject> children; property string name; property bool enabled: true; signal press(); signal release(); property var color; property real brightness; property bool output: true }
