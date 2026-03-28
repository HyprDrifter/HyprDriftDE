// Settings.qml
pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Configs.Themeing

Scope {
    id: root

    property bool isActive : false
    property bool isReady : false

    signal ready()
    signal activated()

    Connections {
        target: root
        function onReady() {
            root.isReady = true
        }
    }

    function activate(){
        if (isActive) return
        isActive = true
        activated()
    }

    // 🎨 Base16 Theme Palette
    property string currentBase16ThemeName : "tokyo-city-dark"
    property var themeColors               : ({})

    // Semantic Base16 Roles (Tinted Theming Compliant)
    property color background   : Theme.hexToRGB(base00, .90) // Main background
    property color mantle       : Theme.hexToRGB(base01, .90) // Lighter background (panels, hovers)
    property color surface0     : Theme.hexToRGB(base02, .90) // Selection background
    property color surface1     : Theme.hexToRGB(base03, .90) // Comments, invisibles, line highlight
    property color surface2     : Theme.hexToRGB(base04, .90) // Status bar, dark UI elements
    property color text         : Theme.hexToRGB(base05, .90) // Main foreground text
    property color rosewater    : Theme.hexToRGB(base06, .90) // Secondary/hint text
    property color lavender     : Theme.hexToRGB(base07, .90) // Light background (borders, etc.)
    property color red          : Theme.hexToRGB(base08, .90) // Errors, deleted diffs, variables
    property color peach        : Theme.hexToRGB(base09, .90) // Numbers, decorators
    property color yellow       : Theme.hexToRGB(base0A, .90) // Constants, classes
    property color green        : Theme.hexToRGB(base0B, .90) // Strings, inserted diffs
    property color teal         : Theme.hexToRGB(base0C, .90) // Support, escape characters
    property color blue         : Theme.hexToRGB(base0D, .90) // Functions, methods
    property color mauve        : Theme.hexToRGB(base0E, .90) // Keywords, storage
    property color flamingo     : Theme.hexToRGB(base0F, .90) // Deprecated, warnings

    // Raw fallback values
    property color base00 : "#000000"
    property color base01 : "#111111"
    property color base02 : "#222222"
    property color base03 : "#333333"
    property color base04 : "#444444"
    property color base05 : "#555555"
    property color base06 : "#666666"
    property color base07 : "#777777"
    property color base08 : "#888888"
    property color base09 : "#999999"
    property color base0A : "#aaaaaa"
    property color base0B : "#bbbbbb"
    property color base0C : "#cccccc"
    property color base0D : "#dddddd"
    property color base0E : "#eeeeee"
    property color base0F : "#ffffff"

    function applyThemeFromMap(palette) {
        base00 = palette.base00 || base00
        base01 = palette.base01 || base01
        base02 = palette.base02 || base02
        base03 = palette.base03 || base03
        base04 = palette.base04 || base04
        base05 = palette.base05 || base05
        base06 = palette.base06 || base06
        base07 = palette.base07 || base07
        base08 = palette.base08 || base08
        base09 = palette.base09 || base09
        base0A = palette.base0A || base0A
        base0B = palette.base0B || base0B
        base0C = palette.base0C || base0C
        base0D = palette.base0D || base0D
        base0E = palette.base0E || base0E
        base0F = palette.base0F || base0F
        console.log("🎨 Theme applied to Settings")
        console.log("---------------------------------")
        root.ready()
    }

    Component.onCompleted: Theme.loadTheme(currentBase16ThemeName)

    // Icon Pack Diectory
    property string iconDirectory: "/home/suzie/.local/share/icons/candy-icons/apps/scalable/"

    // ⏰ Clock
    property string systemTimeFormat : "hh:mm AP"
    property string systemDateFormat : "ddd d MMM"
    readonly property var now : clock.date
    readonly property bool dateFirst : true
    readonly property string systemTime : Qt.formatDateTime(now, systemTimeFormat)
    readonly property string systemDate : Qt.formatDateTime(now, systemDateFormat)
    readonly property string clockDisplay : dateFirst ? systemDate + " | " + systemTime : systemTime + " | " + systemDate

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    

    // 🔤 Fonts
    property string fontFamily : "JetBrains Mono"
    property string fontColor  : text
    property string fontColorInactive  : root.surface1
    property int fontPixelSize : 14
    property int fontLargePixelsize : 16
    property int fontWeight : 50
    property bool fontKerning : true
    property bool fontBold : false
    property bool fontItalic : false
    property bool fontUnderline : false
    property bool fontOverline : false
    property bool fontStrikeout : false
    property int fontWrapMode : 2
    property bool fontDropShadowOn : true
    property string fontDropShadowColor : mantle
    property int fontDropShadowRadius : 2
    property int fontDropShadowHoffset : 3
    property int fontDropShadowVoffset : 2

    //Buttons
    property JsonObject buttons: JsonObject {
        property color backgroundColor: root.background
        property color backgroundColorHovered: root.surface1
    }

    // 💻 Widgets
    property bool nerdFontAvailable : true
    property int cpuRefreshRate : 100
    property string cpuIcon : nerdFontAvailable ? "" : "CPU"
    property int ramRefreshRate : 100
    property string ramIcon : nerdFontAvailable ? "" : "RAM"
    property int gpuRefreshRate : 100
    property string gpuIcon : nerdFontAvailable ? "󰍹" : "GPU"

    // 🚀 Launcher
    property string applaunchIconText : ""
    property bool applaunchClearTextOnClose : true
    property double applaunchWidthInScreenPercent : 0.35
    property double applaunchHeightInScreenPercent : 0.5
    property int applaunchTextInputAlignment : 2
    property color applaunchLauncherColor : background 
    property color applaunchSearchBarColor : mantle
    property color applaunchSearchBarTextColor : red

    // 🧱 Taskbar
    property int taskbarHeight : 28
    property color taskbarColor : background
    property int taskbarRadius : 12
    property int taskbarLeftGap : 15
    property int taskbarRightGap : 15
    property int taskbarTopGap : 15
    property int taskbarTrayIconPreferedWidth : 16
    property int taskbarTrayPadding : 3
    property bool taskbarTrayEnableBorder : true
    property int taskbarTrayBorderWidth : 1
    property color taskbarTrayBorderColor : surface1

    // 🔊 Audio
    property JsonObject soundSettings: JsonObject {
        property string volumeMutedIcon: ""
        property string volumeOffIcon: ""
        property string volumeLowIcon: ""
        property string volumeMidIcon: "󰕾"
        property string volumeHighIcon: ""
        property bool audioProtection : true
        property int audioMaxVolume : 150
        property int audioMaxIncrease : audioMaxVolume

        // Volume Controller
        property color volumeControllerBackgroundColor: root.background
    }
    


    // 📋 Clipboard
    property color clipmanIconBackground : "transparent"
    property color clipmanIconBackgroundHover : mantle
    property color clipmanPopupBackground : background //+ "90"
    property color clipmanPopupButtonBackground : "transparent"
    property color clipmanPopupButtonBackgroundHover : surface0

    // 📂 Minimizer
    property bool minimizerPlayAudioOnRestore : false
    property string minimizerPlayOnRestoreSound : systemAudioComplete
    property bool minimizerPlayAudioOnMinimize : false
    property string minimizerPlayOnMinimizeSound : systemAudioBell
    property string minimizerTempDirectory : "/tmp/SlightlyBetterDesktop/Minimizer"
    property string minimizerWindowJson : minimizerTempDirectory + "/windows.json"
    property string minimizerWindowPreviewDirectory: minimizerTempDirectory + "/Previews"
    property bool minimizerLivePreview : true

    // Workspace Manager
    property color workspaceManagerButtonHover           : flamingo
    property color workspaceManagerButtonBorderColor     : flamingo

    // 🔊 System Audio Files
    property string systemAudioAlarmClockElapsed         : "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
    property string systemAudioFrontCenter               : "/usr/share/sounds/freedesktop/stereo/audio-channel-front-center.oga"
    property string systemAudioFrontLeft                 : "/usr/share/sounds/freedesktop/stereo/audio-channel-front-left.oga"
    property string systemAudioFrontRight                : "/usr/share/sounds/freedesktop/stereo/audio-channel-front-right.oga"
    property string systemAudioRearCenter                : "/usr/share/sounds/freedesktop/stereo/audio-channel-rear-center.oga"
    property string systemAudioRearLeft                  : "/usr/share/sounds/freedesktop/stereo/audio-channel-rear-left.oga"
    property string systemAudioRearRight                 : "/usr/share/sounds/freedesktop/stereo/audio-channel-rear-right.oga"
    property string systemAudioSideLeft                  : "/usr/share/sounds/freedesktop/stereo/audio-channel-side-left.oga"
    property string systemAudioSideRight                 : "/usr/share/sounds/freedesktop/stereo/audio-channel-side-right.oga"
    property string systemAudioTestSignal                : "/usr/share/sounds/freedesktop/stereo/audio-test-signal.oga"
    property string systemAudioVolumeChange              : "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
    property string systemAudioBell                      : "/usr/share/sounds/freedesktop/stereo/bell.oga"
    property string systemAudioCameraShutter             : "/usr/share/sounds/freedesktop/stereo/camera-shutter.oga"
    property string systemAudioComplete                  : "/usr/share/sounds/freedesktop/stereo/complete.oga"
    property string systemAudioDeviceAdded               : "/usr/share/sounds/freedesktop/stereo/device-added.oga"
    property string systemAudioDeviceRemoved             : "/usr/share/sounds/freedesktop/stereo/device-removed.oga"
    property string systemAudioDialogError               : "/usr/share/sounds/freedesktop/stereo/dialog-error.oga"
    property string systemAudioDialogInformation         : "/usr/share/sounds/freedesktop/stereo/dialog-information.oga"
    property string systemAudioDialogWarning             : "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
    property string systemAudioMessageNewInstant         : "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
    property string systemAudioMessage                   : "/usr/share/sounds/freedesktop/stereo/message.oga"
    property string systemAudioNetworkConnectEstablished : "/usr/share/sounds/freedesktop/stereo/network-connectivity-established.oga"
    property string systemAudioNetworkConnectivityLost   : "/usr/share/sounds/freedesktop/stereo/network-connectivity-lost.oga"
    property string systemAudioPhoneIncomingCall         : "/usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga"
    property string systemAudioPhoneOutgoingBusy         : "/usr/share/sounds/freedesktop/stereo/phone-outgoing-busy.oga"
    property string systemAudioPhoneOutgoingCalling      : "/usr/share/sounds/freedesktop/stereo/phone-outgoing-calling.oga"
    property string systemAudioPowerPlug                 : "/usr/share/sounds/freedesktop/stereo/power-plug.oga"
    property string systemAudioPowerUnplug               : "/usr/share/sounds/freedesktop/stereo/power-unplug.oga"
    property string systemAudioScreenCapture             : "/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
    property string systemAudioServiceLogin              : "/usr/share/sounds/freedesktop/stereo/service-login.oga"
    property string systemAudioServiceLogout             : "/usr/share/sounds/freedesktop/stereo/service-logout.oga"
    property string systemAudioSuspendError              : "/usr/share/sounds/freedesktop/stereo/suspend-error.oga"
    property string systemAudioTrashEmpty                : "/usr/share/sounds/freedesktop/stereo/trash-empty.oga"
    property string systemAudioWindowAttention           : "/usr/share/sounds/freedesktop/stereo/window-attention.oga"
    property string systemAudioWindowQuestion            : "/usr/share/sounds/freedesktop/stereo/window-question.oga"

    signal settingsChanged
}
