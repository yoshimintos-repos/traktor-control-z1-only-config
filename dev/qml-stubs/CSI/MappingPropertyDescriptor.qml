import QtQml 2.0
QtObject { enum Type { Boolean, Integer, Float }
  default property list<QtObject> children; property string path; property int type; property var value; property list<QtObject> values; property real min; property real max; property var description }
