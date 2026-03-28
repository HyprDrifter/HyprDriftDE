pragma Singleton

import QtQuick
import QtQml

import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Configs.Settings

Singleton {
    id: root

    property int logLevel : Settings.system.logSettings.logLevel
    property string subCharMarker: "-"
    property string dividerString:      "---------------------------------------------------------------------------"
    property string dividerStringChar: "-"


    function log(logList: list<string>) {
        for(let p of logList)
        {
            var ll = root.logLevel;
            switch (true) {
                case (ll >= 2):
                case (ll >= 1):
                case (ll >= 0):
                    console.log(p)
            }
        }
    }

    function printDivide() {
        log([dividerString])
    }

    function printDivideSmall() {
        
        log([dividerString])
    }

    function logWithHeader(logList: list<string>) {
        var list = []
        var headerDone = false
        var headerCharCount = logList[0].length
        var dividerStringLength = dividerString.length
        logList[0] = `|  ${logList[0]}  |`
        var underline = generateUnderline(logList[0])

        for(let s of logList)
        {
            if(!headerDone)
            {
                headerDone = true
                root.log([dividerString])
                root.log([`${s}`])
                root.log([`${underline}`])
                
            } else {
                list.push(`${subCharMarker} ${s}`)
            }
        }
        log(list)
    }

    function generateUnderline(s: string): string {
        var underline = ""
        for(let p of s)
        {
            underline = underline + dividerStringChar
        }
        
        return underline
    }

}