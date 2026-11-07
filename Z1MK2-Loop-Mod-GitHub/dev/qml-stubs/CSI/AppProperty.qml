import QtQml 2.0
QtObject { property string path; property var value: Registry.has(path) ? Registry.get(path) : 4; property var description: Registry.get(path + "#desc") }
