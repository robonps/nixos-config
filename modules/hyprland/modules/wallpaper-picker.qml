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
    property bool isOpen: false
    property bool ready: false
    property bool applying: false
    property string applyingPath: ""
    property string applyingLayout: "repeat"
    property string applyError: ""
    property var screens: [{label: "All screens", target: "all"}]
    property int targetIndex: 0
    property string layoutMode: "repeat"
    property string savedLayout: "repeat"
    property string currentPath: ""
    property string librarySignature: ""
    property bool optionsEdited: false
    property bool browsingEdited: false
    property var thumbnailSources: ({})
    property var thumbnailRequested: ({})
    property var thumbnailQueue: []
    property color background: "#171219"
    property color foreground: "#eee7ef"
    property color accent: "#e3b4db"
    property bool preview: false
    readonly property int step: 200
    property string monitorName: Quickshell.env("WALLPAPER_PICKER_MONITOR")
    readonly property string targetOutput: screens[targetIndex]?.target ?? "all"
    readonly property bool canSpan: targetOutput === "all" && screens.length > 2

    onSelectedChanged: applyError = ""

    function open(monitor, previewMode) {
        monitorName = monitor || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        preview = previewMode;
        targetIndex = 0;
        layoutMode = canSpan && savedLayout === "span" ? "span" : "repeat";
        optionsEdited = false;
        applyError = "";
        searchField.text = "";
        filtered = files;
        selected = Math.max(0, files.findIndex(file => file.path === currentPath));
        motion.stop();
        carousel.contentX = selected * step;
        browsingEdited = false;
        isOpen = true;
        Qt.callLater(() => searchField.forceActiveFocus());
        // Show the loaded library immediately; reconcile disk changes asynchronously.
        if (!scanProcess.running) scanProcess.running = true;
    }

    function close() {
        isOpen = false;
        motion.stop();
    }

    function setLayout(mode) {
        if (applying) return;
        if (mode !== "repeat" && !(mode === "span" && canSpan)) return;
        optionsEdited = true;
        layoutMode = mode;
        searchField.forceActiveFocus();
    }

    function toggleLayout() {
        if (!applying && canSpan) setLayout(layoutMode === "span" ? "repeat" : "span");
    }

    function requestThumbnail(file, index) {
        if (file.thumbnailReady !== false || thumbnailRequested[file.path]) return;
        thumbnailRequested[file.path] = true;
        thumbnailQueue.push({path: file.path, index: index});
        Qt.callLater(loadNextThumbnail);
    }

    function loadNextThumbnail() {
        if (thumbnailProcess.running || !thumbnailQueue.length) return;
        // Decode one source at a time, prioritizing the card closest to selection.
        thumbnailQueue.sort((a, b) => Math.abs(a.index - selected) - Math.abs(b.index - selected));
        const file = thumbnailQueue.shift();
        thumbnailProcess.command = [Quickshell.env("WALLPAPER_PICKER_THUMBNAIL"), file.path];
        thumbnailProcess.running = true;
    }

    function setTarget(index) {
        if (applying) return;
        optionsEdited = true;
        targetIndex = index;
        if (!canSpan) layoutMode = "repeat";
        searchField.forceActiveFocus();
    }

    Component.onCompleted: {
        if (!monitorName && Hyprland.focusedMonitor) monitorName = Hyprland.focusedMonitor.name;
    }

    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            if (!root.monitorName && Hyprland.focusedMonitor)
                root.monitorName = Hyprland.focusedMonitor.name;
        }
    }

    function parseColor(text, name, fallback) {
        const match = text.match(new RegExp("\\b" + name + "\\s*:\\s*(#[0-9a-fA-F]{6})\\b"));
        return match ? match[1] : fallback;
    }

    function filter(query, userInput) {
        if (userInput) browsingEdited = true;
        const previous = filtered[selected]?.path;
        motion.stop();
        filtered = query ? files.filter(file => file.name.toLowerCase().includes(query.toLowerCase())) : files;
        selected = Math.max(0, filtered.findIndex(file => file.path === previous));
        applyError = "";
        carousel.contentX = selected * step;
    }

    function select(index) {
        if (!filtered.length) return;
        browsingEdited = true;
        selected = Math.max(0, Math.min(index, filtered.length - 1));
        motion.stop();
        motion.to = selected * step;
        motion.start();
    }

    function apply(index) {
        if (!filtered.length || applying) return;
        selected = index;
        if (!preview) {
            applyError = "";
            applying = true;
            applyingPath = filtered[index].path;
            applyingLayout = layoutMode;
            applyProcess.command = [Quickshell.env("WALLPAPER_PICKER_APPLY"), filtered[index].path,
                                    layoutMode, targetOutput];
            applyProcess.running = true;
        } else root.close();
    }

    function shuffle() {
        root.apply(Math.floor(Math.random() * root.filtered.length));
    }

    Process {
        id: scanProcess
        command: [Quickshell.env("WALLPAPER_PICKER_SCAN")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const signature = JSON.stringify(data.files);
                    const libraryChanged = signature !== root.librarySignature;
                    const initialLoad = !root.ready;
                    if (libraryChanged) {
                        root.librarySignature = signature;
                        // Discard stale in-memory URLs when source files or their
                        // cache keys change during this resident picker's lifetime.
                        root.thumbnailSources = ({});
                        root.thumbnailRequested = ({});
                        root.thumbnailQueue = [];
                        root.files = data.files;
                        root.filter(searchField.text, false);
                    }
                    root.screens = [{label: "All screens", target: "all"}].concat(data.screens ?? []);
                    root.currentPath = data.current;
                    root.savedLayout = data.layout === "span" ? "span" : "repeat";
                    if (initialLoad || !root.browsingEdited) {
                        root.selected = Math.max(0, root.filtered.findIndex(file => file.path === data.current));
                        carousel.contentX = root.selected * root.step;
                    }
                    if (!root.optionsEdited)
                        root.layoutMode = root.canSpan ? root.savedLayout : "repeat";
                    root.background = root.parseColor(data.colors, "background", root.background);
                    root.foreground = root.parseColor(data.colors, "foreground", root.foreground);
                    root.accent = root.parseColor(data.colors, "selected", root.accent);
                } catch (error) {
                    console.error("Could not load wallpapers:", error);
                }
                root.ready = true;
            }
        }
    }

    Process {
        id: thumbnailProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    const file = root.files.find(file => file.path === result.path);
                    if (file && file.thumbnail === result.thumbnail)
                        root.thumbnailSources = Object.assign({}, root.thumbnailSources,
                            {[result.path]: result.thumbnail});
                } catch (error) {
                    console.error("Could not generate wallpaper thumbnail:", error);
                }
            }
        }
        onExited: Qt.callLater(root.loadNextThumbnail)
    }

    Process {
        id: applyProcess
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.applyError = text.trim();
        }
        onExited: exitCode => {
            root.applying = false;
            if (exitCode === 0) {
                root.currentPath = root.applyingPath;
                root.savedLayout = root.applyingLayout;
                root.close();
            }
            else if (!root.applyError) root.applyError = "Could not apply wallpaper. Try another file.";
        }
    }

    // Useful for controlling or inspecting an open picker without simulating keys.
    IpcHandler {
        target: "picker"
        function open(monitor: string, preview: bool): void { root.open(monitor, preview); }
        function select(index: int): void { root.select(index); }
        function search(query: string): void { searchField.text = query; }
        function close(): void { root.close(); }
        function setScreen(index: int): void { root.setTarget(index); }
        function layout(mode: string): void {
            root.setLayout(mode);
        }
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
            return JSON.stringify({ready: root.ready, open: root.isOpen, count: root.filtered.length,
                selected: root.selected, position: carousel.contentX / root.step,
                animating: motion.running, preview: root.preview,
                layout: root.layoutMode, target: root.targetOutput, screens: root.screens,
                monitor: panel.screen?.name ?? "",
                applying: root.applying, error: root.applyError,
                pendingImages: pending, imageErrors: errors});
        }
    }

    PanelWindow {
        id: panel
        visible: root.isOpen && Quickshell.screens.some(screen => screen.name === root.monitorName)
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 398
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
                if (event.key === Qt.Key_Escape) root.close();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.apply(root.selected);
                else if (event.key === Qt.Key_Left) root.select(root.selected - 1);
                else if (event.key === Qt.Key_Right) root.select(root.selected + 1);
                else if (event.key === Qt.Key_Up) root.toggleLayout();
                else if (event.key === Qt.Key_Down) root.shuffle();
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
                    onTextChanged: root.filter(text, true)
                    Keys.onPressed: event => {
                        if ((text.length === 0 || (event.modifiers & Qt.ControlModifier))
                                && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                            root.select(root.selected + (event.key === Qt.Key_Right ? 1 : -1));
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.toggleLayout(); event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.shuffle(); event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.close(); event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.apply(root.selected); event.accepted = true;
                        }
                    }
                }
                ActionButton {
                    text: "Shuffle"
                    enabled: root.filtered.length > 0 && !root.applying
                    onClicked: root.shuffle()
                }
                ActionButton {
                    text: root.applying ? "Applying…" : "Apply"
                    primary: true
                    enabled: root.filtered.length > 0 && !root.applying
                    onClicked: root.apply(root.selected)
                }
                ActionButton { text: "×"; onClicked: root.close() }
            }

            RowLayout {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 62 }
                spacing: 8
                enabled: !root.applying
                Text { text: "Screens"; color: root.foreground; font.pixelSize: 13 }
                Repeater {
                    model: root.screens
                    ActionButton {
                        required property int index
                        required property var modelData
                        text: modelData.label
                        primary: root.targetIndex === index
                        onClicked: root.setTarget(index)
                    }
                }
                Item { Layout.preferredWidth: 12 }
                ActionButton {
                    text: "Repeat"
                    primary: root.layoutMode === "repeat"
                    onClicked: root.setLayout("repeat")
                }
                ActionButton {
                    text: "Span"
                    primary: root.layoutMode === "span"
                    enabled: root.canSpan
                    onClicked: root.setLayout("span")
                    ToolTip.visible: hovered && !enabled
                    ToolTip.text: "Select All screens to span across multiple monitors"
                }
            }

            Flickable {
                id: carousel
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 108 }
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
                            readonly property string previewPath: root.thumbnailSources[modelData.path]
                                ?? (modelData.thumbnailReady !== false ? modelData.thumbnail : "")
                            Component.onCompleted: if (nearby) root.requestThumbnail(modelData, index)
                            onNearbyChanged: if (nearby) root.requestThumbnail(modelData, index)

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
                                    source: card.nearby && card.previewPath ? "file://" + encodeURI(card.previewPath).replace(/#/g, "%23").replace(/\?/g, "%3F") : ""
                                    sourceSize { width: 360; height: 360 }
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    autoTransform: true
                                    opacity: 0.65 + 0.35 * card.emphasis
                                }
                                Rectangle {
                                    visible: card.modelData.video ?? false
                                    anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                                    width: 52; height: 22; radius: 7
                                    color: root.background
                                    Text {
                                        anchors.centerIn: parent
                                        text: "VIDEO"; color: root.accent; font { pixelSize: 10; bold: true }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.apply(card.index)
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
                text: root.applyError || (!root.ready ? "Loading wallpapers…" : root.filtered.length
                    ? (root.filtered[root.selected]?.name ?? "") + "    ·    " + (root.selected + 1) + " / " + root.filtered.length
                    : "No matching wallpapers")
                color: root.foreground
                font.pixelSize: 14
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
                text: "← → or scroll to browse    ·    ↑ Repeat / Span    ·    ↓ shuffle    ·    Enter or click to apply    ·    Esc to close"
                color: Qt.alpha(root.foreground, 0.55)
                font.pixelSize: 12
            }
        }
    }
}
