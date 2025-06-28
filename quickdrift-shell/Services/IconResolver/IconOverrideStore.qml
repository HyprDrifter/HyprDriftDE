pragma Singleton
import QtQuick 2.0

QtObject {
    property var overrides: ({})
    signal overrideChanged(string id)
}
