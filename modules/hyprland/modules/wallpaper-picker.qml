import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

ShellRoot {
    id: root
    property var files: []
    property var filtered: []
    property int selected: 0
    property bool ready: false
    property color background: "#171219"
    property color foreground: "#eee7ef"
    property color accent: "#e3b4db"
    readonly property bool preview: Quickshell.env("WALLPAPER_PICKER_PREVIEW") === "1"
    readonly property int step: 200
    property string monitorName: ""

    Component.onCompleted: {
        if (Hyprland.focusedMonitor) monitorName = Hyprland.focusedMonitor.name;
    }

    function parseColor(text, name, fallback) {
        const match = text.match(new RegExp("\\b" + name + "\\s*:\\s*(#[0-9a-fA-F]{6})\\b"));
        return match ? match[1] : fallback;
    }

    function filter(query) {
        const previous = filtered[selected]?.path;
        motion.stop();
        filtered = files.filter(file => file.name.toLowerCase().includes(query.toLowerCase()));
        selected = Math.max(0, filtered.findIndex(file => file.path === previous));
        carousel.contentX = selected * step;
    }

    function select(index) {
        if (!filtered.length) return;
        selected = Math.max(0, Math.min(index, filtered.length - 1));
        motion.stop();
        motion.to = selected * step;
        motion.start();
    }

    function apply(index) {
        if (!filtered.length) return;
        if (!preview) {
            Quickshell.execDetached([Quickshell.env("WALLPAPER_PICKER_APPLY"), filtered[index].path]);
        }
        Qt.quit();
    }

    function shuffle() {
        root.apply(Math.floor(Math.random() * root.filtered.length));
    }

    Process {
        command: [Quickshell.env("WALLPAPER_PICKER_SCAN")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.files = data.files;
                    root.filtered = data.files;
                    root.selected = Math.max(0, data.files.findIndex(file => file.path === data.current));
                    root.background = root.parseColor(data.colors, "background", root.background);
                    root.foreground = root.parseColor(data.colors, "foreground", root.foreground);
                    root.accent = root.parseColor(data.colors, "selected", root.accent);
                    carousel.contentX = root.selected * root.step;
                } catch (error) {
                    console.error("Could not load wallpapers:", error);
                }
                root.ready = true;
            }
        }
    }

    // Useful for controlling or inspecting an open picker without simulating keys.
    IpcHandler {
        target: "picker"
        function select(index: int): void { root.select(index); }
        function search(query: string): void { searchField.text = query; }
        function close(): void { Qt.quit(); }
        function status(): string {
            let pending = 0;
            let errors = 0;
            for (let i = 0; i < cards.count; ++i) {
                const card = cards.itemAt(i);
                if (card && card.nearby) {
                    if (card.imageStatus !== Image.Ready) ++pending;
                    if (card.imageStatus === Image.Error) ++errors;
                }
            }
            return JSON.stringify({ready: root.ready, count: root.filtered.length,
                selected: root.selected, position: carousel.contentX / root.step,
                animating: motion.running, preview: root.preview,
                pendingImages: pending, imageErrors: errors});
        }
    }

    PanelWindow {
        id: panel
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 350
        color: root.background
        exclusionMode: ExclusionMode.Ignore
        screen: Quickshell.screens.find(screen => screen.name === root.monitorName) ?? Quickshell.screens[0]
        WlrLayershell.namespace: "wallpaper-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) Qt.quit();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.apply(root.selected);
                else if (event.key === Qt.Key_Left) root.select(root.selected - 1);
                else if (event.key === Qt.Key_Right) root.select(root.selected + 1);
                else if (event.key === Qt.Key_Up) root.shuffle();
                else if (event.key === Qt.Key_Home) root.select(0);
                else if (event.key === Qt.Key_End) root.select(root.filtered.length - 1);
                else return;
                event.accepted = true;
            }

            // Receive wheel events before the Flickable and thumbnail controls.
            // Button presses still pass through to the controls underneath.
            MouseArea {
                anchors.fill: parent
                z: 100
                acceptedButtons: Qt.NoButton
                scrollGestureEnabled: true
                property real accumulatedSteps: 0
                onWheel: event => {
                    const pixels = event.pixelDelta.y || event.pixelDelta.x;
                    const angle = event.angleDelta.y || event.angleDelta.x;
                    const delta = pixels ? pixels / 40 : angle / 120;
                    if (delta * accumulatedSteps < 0) accumulatedSteps = 0;
                    accumulatedSteps += delta;
                    const steps = Math.trunc(accumulatedSteps + Math.sign(accumulatedSteps) * 0.000001);
                    if (steps) {
                        root.select(root.selected - steps);
                        accumulatedSteps -= steps;
                    }
                    event.accepted = true;
                }
            }

            component ActionButton: Button {
                id: button
                property bool primary: false
                implicitHeight: 36
                leftPadding: 16
                rightPadding: 16
                background: Rectangle {
                    radius: 12
                    color: button.primary ? root.accent : Qt.alpha(root.foreground, button.hovered ? 0.15 : 0.08)
                    opacity: button.enabled ? 1 : 0.4
                    border.width: button.activeFocus ? 1 : 0
                    border.color: root.accent
                }
                contentItem: Text {
                    text: button.text
                    color: button.primary ? root.background : root.foreground
                    font.pixelSize: 14
                    font.bold: button.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            RowLayout {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 24; topMargin: 16 }
                spacing: 16
                Text {
                    text: "Wallpapers"
                    color: root.foreground
                    font { pixelSize: 20; bold: true }
                    Layout.fillWidth: true
                }
                TextField {
                    id: searchField
                    Layout.preferredWidth: Math.min(320, panel.width * 0.3)
                    Layout.preferredHeight: 36
                    placeholderText: "Search wallpapers…"
                    color: root.foreground
                    placeholderTextColor: Qt.alpha(root.foreground, 0.5)
                    selectionColor: root.accent
                    selectedTextColor: root.background
                    leftPadding: 12
                    rightPadding: 12
                    font.pixelSize: 14
                    background: Rectangle {
                        color: Qt.alpha(root.foreground, 0.06)
                        radius: 12
                        border.width: 1
                        border.color: searchField.activeFocus ? root.accent : Qt.alpha(root.foreground, 0.2)
                    }
                    onTextChanged: root.filter(text)
                    Component.onCompleted: forceActiveFocus()
                    Keys.onPressed: event => {
                        if ((text.length === 0 || (event.modifiers & Qt.ControlModifier))
                                && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                            root.select(root.selected + (event.key === Qt.Key_Right ? 1 : -1));
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.shuffle(); event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            Qt.quit(); event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.apply(root.selected); event.accepted = true;
                        }
                    }
                }
                ActionButton {
                    text: "Shuffle"
                    enabled: root.filtered.length > 0
                    onClicked: root.shuffle()
                }
                ActionButton {
                    text: "Apply"
                    primary: true
                    enabled: root.filtered.length > 0
                    onClicked: root.apply(root.selected)
                }
                ActionButton { text: "×"; onClicked: Qt.quit() }
            }

            Flickable {
                id: carousel
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 60 }
                height: 230
                contentWidth: width + Math.max(0, root.filtered.length - 1) * root.step
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                onMovementStarted: motion.stop()
                onMovementEnded: root.select(Math.round(contentX / root.step))
                onContentXChanged: {
                    if (dragging || flicking) root.selected = Math.max(0,
                        Math.min(Math.round(contentX / root.step), root.filtered.length - 1));
                }

                NumberAnimation {
                    id: motion
                    target: carousel
                    property: "contentX"
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.0
                }

                Row {
                    x: (carousel.width - root.step) / 2
                    height: carousel.height
                    Repeater {
                        id: cards
                        model: root.filtered
                        delegate: Item {
                            id: card
                            required property int index
                            required property var modelData
                            width: root.step
                            height: carousel.height
                            readonly property real emphasis: Math.max(0, 1 - Math.abs(index - carousel.contentX / root.step))
                            readonly property bool nearby: Math.abs(index - carousel.contentX / root.step) < carousel.width / root.step / 2 + 2
                            readonly property int imageStatus: wallpaperImage.status

                            Rectangle {
                                anchors.centerIn: parent
                                width: picture.width + 10
                                height: width
                                radius: 18
                                color: "transparent"
                                border.width: 2
                                border.color: Qt.alpha(root.accent, card.emphasis)
                            }
                            ClippingRectangle {
                                id: picture
                                anchors.centerIn: parent
                                width: 144 + 36 * card.emphasis
                                height: width
                                radius: 14
                                color: Qt.alpha(root.foreground, 0.08)
                                Image {
                                    id: wallpaperImage
                                    anchors.fill: parent
                                    source: card.nearby ? "file://" + encodeURI(card.modelData.path).replace(/#/g, "%23").replace(/\?/g, "%3F") : ""
                                    sourceSize { width: 360; height: 360 }
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    autoTransform: true
                                    opacity: 0.65 + 0.35 * card.emphasis
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (card.index === root.selected) root.apply(card.index);
                                        else root.select(card.index);
                                    }
                                    onDoubleClicked: root.apply(card.index)
                                }
                            }
                        }
                    }
                }
            }

            // Gradients hide partially visible cards at the viewport edges.
            Repeater {
                model: 2
                Rectangle {
                    required property int index
                    x: index === 0 ? 0 : panel.width - width
                    y: carousel.y
                    width: 90
                    height: carousel.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: index === 0 ? root.background : Qt.alpha(root.background, 0) }
                        GradientStop { position: 1; color: index === 0 ? Qt.alpha(root.background, 0) : root.background }
                    }
                }
            }
            Text {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 24; bottomMargin: 40 }
                text: !root.ready ? "Loading wallpapers…" : root.filtered.length
                    ? (root.filtered[root.selected]?.name ?? "") + "    ·    " + (root.selected + 1) + " / " + root.filtered.length
                    : "No matching wallpapers"
                color: root.foreground
                font.pixelSize: 14
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
                text: "← → or scroll to browse    ·    ↑ to shuffle    ·    Enter or click selected to apply    ·    Esc to close"
                color: Qt.alpha(root.foreground, 0.55)
                font.pixelSize: 12
            }
        }
    }
}
