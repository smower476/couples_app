pragma Singleton
import QtQuick 2.15

QtObject {
    // Colors
    readonly property color backgroundColor: "#121212"  // dark gray-900
    readonly property color cardBackgroundColor: "#1f1f1f"  // gray-800
    readonly property color primaryColor: "#ec4899"  // pink-600
    readonly property color secondaryColor: "#4b5563"  // gray-600
    readonly property color textColor: "#ffffff"  // white
    readonly property color secondaryTextColor: "#9ca3af"  // gray-400
    
    // Button colors
    readonly property color greenColor: "#16a34a"  // green-600
    readonly property color yellowColor: "#d97706"  // yellow-600
    readonly property color redColor: "#dc2626"  // red-600
    
    // Font sizes
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeMedium: 16
    readonly property int fontSizeLarge: 20
    readonly property int fontSizeXLarge: 24
    readonly property int fontSizeXXLarge: 32
    
    // Margin & padding
    readonly property int marginSmall: 4
    readonly property int marginNormal: 8
    readonly property int marginMedium: 12
    readonly property int marginLarge: 16
    readonly property int marginXLarge: 24
    
    // Border radius
    readonly property int radiusSmall: 4
    readonly property int radiusNormal: 8
    
    // Icon sizes
    readonly property int iconSmall: 18
    readonly property int iconNormal: 24
    readonly property int iconLarge: 36
}