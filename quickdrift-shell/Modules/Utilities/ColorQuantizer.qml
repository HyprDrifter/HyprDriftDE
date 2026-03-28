pragma Singleton

import Quickshell
import QtQuick

// ColorQuantizer provides dominant color extraction from a wallpaper or image.
// Set 'source' to the path of the image you want to quantize before use.
ColorQuantizer {
    id: colorQuantizer
    source: ""    // Set to the image path, e.g. Qt.resolvedUrl("path/to/image.png")
    depth: 3       // Will produce 8 colors (2³)
    rescaleSize: 64 // Rescale to 64x64 for faster processing
}
