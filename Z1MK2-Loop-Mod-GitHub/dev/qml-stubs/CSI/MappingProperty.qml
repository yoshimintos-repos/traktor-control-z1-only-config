import QtQml 2.0
QtObject { property string path; property var value: Registry.get(path) }
