pragma Singleton

import Quickshell

Singleton {
    function play(fileLocation: string): void {
        Quickshell.execDetached(["paplay", fileLocation])
    }
}
