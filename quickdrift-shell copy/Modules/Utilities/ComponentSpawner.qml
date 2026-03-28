import QtQuick
import QtQml

import Quickshell

Item {
    id: root
    property Component factory
    property var props: ({})
    property var createdObject

    Component.onCompleted: {
        if (factory) createdObject = factory.createObject(root, props)
    }
    onFactoryChanged: {
        if (createdObject) createdObject.destroy()
        if (factory) createdObject = factory.createObject(root, props)
    }
}
