pragma Singleton
import QtQml 2.0
// Testwerte fuer die Stub-Properties (AppProperty / MappingProperty)
QtObject {
  property var data: ({})
  function get(p) { return data[p]; }
  function has(p) { return data.hasOwnProperty(p); }
}
