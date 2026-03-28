import QtQuick
import QtQuick.Controls

SpinBox {
    id: root
    
    default property list<var> data: []
    property QtObject boundObject: null
    
    property alias max: aliases.max
    property alias min: aliases.min
    property alias number: aliases.number

    Item {
        id: aliases
        property int max
        property int min
        property int number
    }

    to: root.max
    from: root.min
    value: root.number

    wheelEnabled: true
    editable: true
}