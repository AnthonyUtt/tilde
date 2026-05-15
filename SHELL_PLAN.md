# Plan: New Quickshell + Hyprland Shell — Architectural Cheatsheet

## Context

This document is an architectural reference for building a **new, custom Quickshell + Hyprland desktop shell** (separate repo, NixOS host, declarative config) inspired by `end-4/dots-hyprland` (a.k.a. illogical-impulse). It is **not** a step-by-step build plan — most product decisions are deferred. Its purpose is to capture every clever implementation pattern, service shape, and cross-cutting concern from the reference codebase so a fresh agent can start coding the new shell without re-discovering the prior art.

**Reference source root:** `/home/anthony/source/scratch/dots-hyprland/dots/.config/quickshell/ii/` (file paths below are relative to that root unless absolute).

**Target stack:** Quickshell (Qt6/QML) + Hyprland (Lua-plugin config) + matugen + NixOS/home-manager.

---

## 1. High-Level Architecture

Quickshell runs as a single long-lived QML process. Everything is a `pragma Singleton` (services, global state) or a `PanelWindow`/`PopupWindow`/`FloatingWindow` (UI). There is **no shadow DOM, no React-like reconciliation** — QML's property bindings are the reactivity model, and `Loader { active: ... }` is how you mount/unmount panels.

Three orthogonal axes you'll set up early:

1. **Root entry** (`shell.qml`) — a `ShellRoot` that wires up startup tasks and mounts panels.
2. **Singletons** in `services/` and `modules/common/` — every cross-cutting concern (Config, Audio, Network, Notifications, Ai, HyprlandData, Theme, GlobalStates).
3. **Panels** in `modules/<area>/` — each panel owns one or more layer-shell windows, scoped to monitors via `Quickshell.Variants`.

### Process model

- `quickshell -c <configName>` runs `shell.qml`.
- The **settings app** is a *separate* process launched with `qs -p .../settings.qml`. Both processes read/write the same JSON config file; `FileView.watchChanges = true` makes them mutually reactive. This avoids embedding a "settings mode" in the main shell.

---

## 2. Repository Layout Pattern

```
.config/quickshell/<name>/
├── shell.qml                  # ShellRoot, panel mounting, panel-family selection
├── settings.qml               # Standalone settings app (separate qs process)
├── welcome.qml                # First-run wizard (separate qs process)
├── GlobalStates.qml           # Singleton: visibility flags for every panel
├── modules/
│   ├── common/                # Cross-area shared code
│   │   ├── Config.qml         # JSON-backed config singleton (HOT RELOAD)
│   │   ├── Appearance.qml     # Color tokens, sizes, animation curves
│   │   ├── Directories.qml    # Path constants (resolved from env)
│   │   ├── Persistent.qml     # Persistent UI state (not user config)
│   │   ├── widgets/           # Reusable QML widgets
│   │   ├── panels/            # Reusable building blocks for full panels
│   │   ├── models/            # ListModels (apps, workspaces)
│   │   └── functions/         # JS utility modules (ColorUtils, FileUtils, Fuzzy, ...)
│   └── <area>/                # Per-panel directories
├── services/                  # ~40 singletons
├── scripts/                   # Bash helpers invoked from QML Processes
├── translations/              # i18n JSON
├── assets/                    # icons, images
└── defaults/                  # default prompts, palettes
```

Rationale: every `import` path is short (`import qs.modules.common.widgets`, `import qs.services`); per-panel directories scope ownership; `common/` clearly separates *library code* from *application code*. If you ship a single visual style (likely), skip the `panelFamilies/` indirection from the reference repo — it's only useful when shipping multiple stylings.

---

## 3. Configuration System (THE most important pattern)

**File:** `modules/common/Config.qml`

```qml
Singleton {
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter   // Exposed to UI
    property bool ready: false
    property int readWriteDelay: 50

    FileView {
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()       // External edits → reload
        onAdapterUpdated: fileWriteTimer.restart()     // UI edits → write
        onLoadFailed: if (error == FileViewError.FileNotFound) writeAdapter()

        JsonAdapter {
            id: configOptionsJsonAdapter
            property JsonObject ai: JsonObject {
                property string systemPrompt: "..."
                property list<var> extraModels: [...]
            }
            property JsonObject bar: JsonObject { property bool bottom: false }
            // etc.
        }
    }
}
```

**Why this is clever:**

- `JsonAdapter` + `JsonObject` give you typed defaults, automatic serialization, and **two-way binding** to QML properties — UI components write `Config.options.bar.bottom = true` and the file updates after a 50ms debounce.
- `watchChanges: true` means the **settings app's writes are picked up by the running shell** with no IPC; both sides just observe the JSON file.
- `setNestedValue(path, value)` (Config.qml:16-44) parses dotted paths (e.g. `"bar.borderless"`), creating intermediate objects, coercing `"true"`/`"false"`/numerics via `JSON.parse`. This is how the AI's `set_shell_config` tool works AND how generic settings rows are wired.
- Debounce both directions: `fileReloadTimer` and `fileWriteTimer` with `readWriteDelay` prevent write-storms when users drag sliders.
- The settings app sets `Config.readWriteDelay = 0` since it changes one var at a time.
- A `blockWrites` flag lets you suspend persistence during migrations.

**Pitfall:** changing the JsonObject schema requires care — old keys remain in the file. The reference repo just lives with this; you may want a migration step on load.

**Persistent UI state** (chat scroll positions, last-used model) lives in a *separate* `Persistent.qml` singleton, also JSON-backed but in `$XDG_STATE_HOME` rather than `$XDG_CONFIG_HOME`. Keep these apart.

---

## 4. Panel Architecture

### 4.1 Layer-shell window mounting

Every panel is a `PanelWindow` from `Quickshell.Wayland`. Key properties:

- `WlrLayershell.namespace: "<name>"` — set this per panel for debuggability and for Hyprland window rules (`layerrule = ...`).
- `WlrLayershell.layer: WlrLayer.Top | Overlay` — overview/lock screens use `Top` or `Overlay`.
- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` — needed for text input; set conditionally on visibility so the panel doesn't grab focus globally.
- `anchors { top/left/right/bottom: true }` decides which edges.
- `exclusiveZone` — non-zero "pushes" tiled windows; toggle to 0 when hidden/floating.
- `exclusionMode: ExclusionMode.Normal | Ignore` — `Ignore` is critical for floating panels (dock, media controls) that should overlay rather than reserve space.
- `mask: Region { item: someChild }` — defines the **click-pass-through region**. Crucial pattern: the `PanelWindow` is fullscreen-ish but only the visible child accepts input. This is how the dock has a hover strip + reveal animation without blocking clicks elsewhere.

### 4.2 Per-monitor panels via `Variants`

```qml
Variants {
    model: Quickshell.screens.filter(...)   // or just Quickshell.screens
    LazyLoader {
        active: GlobalStates.barOpen && !GlobalStates.screenLocked
        required property ShellScreen modelData
        component: PanelWindow { screen: barLoader.modelData; ... }
    }
}
```

`LazyLoader` saves resources when the panel is hidden. `screenList` filtering (Bar.qml:19-25) lets users opt monitors out via config.

### 4.3 Conditional mounting

The reference uses a `PanelLoader { extraCondition: ...; component: Foo {} }` indirection so individual panels can be disabled via config without editing the family mount file (`panelFamilies/IllogicalImpulseFamily.qml`). Worth keeping even with one panel family — it's just a `Loader` with `active: Config.ready && extraCondition`.

### 4.4 Window detachment trick (sidebar / chat)

`SidebarLeft.qml` lets the user pop the AI chat into a `FloatingWindow`. The clever bit: the `SidebarLeftContent` Item is created **once at startup** and re-parented between a `Loader<PanelWindow>` and a `Loader<FloatingWindow>` (SidebarLeft.qml:62-81). Chat state survives detachment because no QML object is destroyed.

### 4.5 Pin-with-cursor-dodge workaround

`SidebarLeft.qml:22-58` — when "pinning" the sidebar (so it pushes windows), Hyprland would normally re-flow windows under the cursor, causing a phantom hover. The workaround: read cursor pos, dispatch the cursor to `(9999,9999)`, set the pin, then dispatch the cursor back. Note this for any panel that toggles `exclusiveZone` while the user's cursor is over a soon-to-move window.

---

## 5. Inter-Panel Communication

Four mechanisms, all important:

### 5.1 `GlobalStates` singleton

A flat `QtObject` with `sidebarLeftOpen`, `sidebarRightOpen`, `overviewOpen`, `mediaControlsOpen`, `sessionOpen`, `screenLocked`, `superDown`, `osdVolumeOpen`, etc. Any UI element sets/reads these; bindings propagate visibility everywhere. Cheap, debuggable, scales to ~50 flags. Consider a typed enum/event-bus if you want stricter discipline.

### 5.2 `IpcHandler` — CLI/script integration

```qml
IpcHandler {
    target: "sidebarLeft"
    function toggle(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
    function open(): void  { GlobalStates.sidebarLeftOpen = true }
    function close(): void { GlobalStates.sidebarLeftOpen = false }
}
```

Invoked via `qs ipc call sidebarLeft toggle` from anywhere (Hyprland binds, shell scripts, other tools). Adopt the `toggle/open/close` convention on every togglable panel.

### 5.3 `GlobalShortcut` — Hyprland binds

```qml
GlobalShortcut {
    name: "sidebarLeftToggle"
    description: "..."
    onPressed: GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
}
```

Hyprland binds with `hl.dsp.global("quickshell:sidebarLeftToggle")` (Lua) deliver the event with **no delay**. Use this instead of `exec`-ing shell scripts; keybinds become instant.

Subtle pattern: `searchToggleRelease` (Overview.qml:173-196) — distinguish *tap* vs *hold-and-release-without-other-key* by tracking `GlobalStates.superReleaseMightTrigger`. Required because `GlobalShortcut.onReleased` fires unconditionally; need a `binditn` submap that catches everything else and resets the flag.

### 5.4 `GlobalFocusGrab`

A singleton stack of "dismissable" panels. When the user clicks outside (or another panel takes focus), the topmost dismissable is dismissed. Wired with:

```qml
onVisibleChanged: visible ? GlobalFocusGrab.addDismissable(panel)
                          : GlobalFocusGrab.removeDismissable(panel)
Connections {
    target: GlobalFocusGrab
    function onDismissed() { panel.hide() }
}
```

Also `addPersistent` for the always-on bar. This is the single source of truth for "click-outside-to-close" — much cleaner than each panel implementing its own outside-click detection.

### 5.5 Hyprland Lua bind fallback pattern

Every shell-integrated bind in `keybinds.lua` chains a fallback: `qsIsAlive || pkill fuzzel || fuzzel`. If Quickshell crashed, the system stays usable. Adopt this pattern for everything.

---

## 6. Services — Singletons for Cross-Cutting State

Every service is `pragma Singleton` + `Singleton { ... }`. The singleton plus QML bindings means UI never has to subscribe/unsubscribe explicitly — declarative reactivity does it.

Categories to plan up front:

| Category | Likely services | Notes |
|---|---|---|
| Config & theme | `Config`, `Persistent`, `Appearance`, `MaterialThemeLoader` | Hot-reload from disk |
| WM data | `HyprlandData`, `HyprlandConfig`, `HyprlandXkb`, `HyprlandKeybinds` | Poll `hyprctl -j` (JSON) on socket events |
| Input/output | `Audio`, `Brightness`, `Battery`, `Network`, `BluetoothStatus` | Use Quickshell.Services.* where available |
| Apps | `LauncherApps`, `LauncherSearch`, `TaskbarApps`, `TrayService` | Group toplevels by `appId`; `.desktop` parsing |
| Productivity | `Notifications`, `Cliphist`, `Emojis`, `Todo`, `TimerService`, `Weather` | Persistent stores under `$XDG_STATE_HOME` |
| AI/integrations | `Ai`, `KeyringStorage`, `Translation`, `SongRec`, `LatexRenderer` | See §8 |
| Lifecycle | `GlobalFocusGrab`, `Idle`, `Privacy`, `Updates`, `ConflictKiller`, `FirstRunExperience` | One-shots on startup |
| Process glue | `Ydotool`, `PolkitService`, `Hyprsunset`, `EasyEffects` | Spawn/manage external daemons |

**Pattern: external daemon wrapping.** A service typically:
1. Spawns a `Process` with `running: true`.
2. Parses stdout via `SplitParser` (line-oriented) or `StdioCollector` (full-output).
3. Re-spawns on exit with backoff (`onExited: restartTimer.start()`).
4. Exposes `Q_PROPERTY`-style QML properties so UI can bind.

**Pattern: Hyprland data freshness.** `HyprlandData.qml` polls `hyprctl -j` on Hyprland socket events; expose `windowList`, `windowByAddress`, `addresses`, `monitors` as properties. UI reads them as plain JS objects.

---

## 7. Theming Pipeline (Material You / matugen)

This is the wallpaper-to-runtime-colors loop. Even if you diverge visually, the pipeline shape transfers.

1. **Wallpaper selection** writes path into `Config.options.background.wallpaperPath`.
2. **`scripts/colors/switchwall.sh`** invokes `matugen image <path>` with template config at `~/.config/matugen/config.toml`.
3. **matugen renders** Mustache-like templates from `~/.config/matugen/templates/` to multiple destinations:
   - `~/.local/state/quickshell/user/generated/colors.json` (shell)
   - `~/.config/hypr/hyprland/colors.lua` (Hyprland border colors)
   - `~/.config/hypr/hyprlock/colors.conf`, `fuzzel_theme.ini`, gtk-3.0/4.0 CSS, KDE color file, etc.
4. **`services/MaterialThemeLoader.qml`** owns a `FileView { watchChanges: true; path: ".../colors.json" }`; on change it parses JSON and writes into `Appearance.m3colors` properties. Every QML binding referencing those colors re-renders immediately.
5. **`Appearance.qml`** derives extras from the wallpaper (transparency curve from `ColorQuantizer { source: wallpaperPath }` saturation/lightness — Appearance.qml:23-35), so opacity adapts automatically per wallpaper.
6. **Light/dark inference**: `m3colors.darkmode = (m3background.hslLightness < 0.5)`.

**NixOS-relevant detail:** matugen templates and the resulting files **must be writable at runtime**. Place templates in `~/.config/matugen/templates/` (mutable home, perhaps managed by home-manager with `mkOutOfStoreSymlink` or `xdg.configFile."matugen/templates/foo".text`), and outputs under `~/.local/state/...` (always mutable). See §11.

**Snake_case→camelCase trick** (MaterialThemeLoader.qml:21-30): matugen emits keys like `primary_container`, the QML property is `m3primaryContainer`. A one-line regex bridges them.

**Wallpaper-change reset**: `resetFilePathNextWallpaperChange` (MaterialThemeLoader.qml:43-50) explicitly clears and re-sets `filePath` after wallpaper change, because matugen rewrites the file while `FileView` is watching — without this you get stale reads.

---

## 8. AI Chat Subsystem (Generic Streaming Pattern)

**Reference files:** `services/Ai.qml` (full impl), `services/ai/{ApiStrategy,GeminiApiStrategy,OpenAiApiStrategy,MistralApiStrategy,AiMessageData,AiModel}.qml`, `modules/<area>/aiChat/`.

### 8.1 Streaming via curl + Process + SplitParser

QML/Qt has no first-class SSE client, so:

```qml
Process {
    id: requester
    command: ["bash", scriptPath]   // Generated per-request
    stdout: SplitParser {
        onRead: data => {
            // Each `data` is one line of streamed JSON/SSE
            const result = currentStrategy.parseResponseLine(data, message)
            if (result.chunk) message.content += result.chunk
            if (result.functionCall) handleFunctionCall(...)
            if (result.finished) markDone()
        }
    }
    onExited: markDone()
}
```

The generated script is written by `FileView` to `/tmp/quickshell/ai/request.sh`:

```bash
#!/usr/bin/env bash
# optional file-attach setup here
curl --no-buffer "${endpoint}" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${API_KEY}" \
  --data '<single-quote-escaped JSON>'
```

API keys are injected via `requester.environment[apiKeyEnvVarName] = ...` so they don't appear in the script text. Single-quotes inside JSON are escaped with `CF.StringUtils.shellSingleQuoteEscape` (see `modules/common/functions/StringUtils.qml`).

**Why curl + bash and not `XMLHttpRequest`:**
- `--no-buffer` gives true streaming; QML's `XMLHttpRequest` buffers.
- bash lets the strategy add a multipart file-upload preamble for attachments.
- The script is the canonical request, so it's debuggable (re-run by hand from `/tmp`).

If you'd rather avoid the shell-script approach, Qt 6.5+ has `QNetworkAccessManager` streaming you can expose via a C++ plugin, but it's substantially more work.

### 8.2 Strategy pattern for providers

`ApiStrategy.qml` is an interface with: `buildEndpoint(model)`, `buildAuthorizationHeader(envVar)`, `buildRequestData(model, msgs, sys, temp, tools, attachedFile)`, `buildScriptFileSetup(filePath)`, `parseResponseLine(data, message) → {chunk, functionCall, tokenUsage, finished}`, `onRequestFinished(message)`, `finalizeScriptContent(script)`, `reset()`. Each provider implementation is ~150 lines. The dispatcher just picks `apiStrategies[model.api_format]`.

### 8.3 Tool / function calling

Each provider has a `tools` dict keyed by mode (`functions`/`search`/`none`) with provider-specific JSON shape. Built-in tools the reference ships:

- `get_shell_config` — returns `CF.ObjectUtils.toPlainObject(Config.options)` as JSON.
- `set_shell_config(key, value)` — calls `Config.setNestedValue` (see §3).
- `run_shell_command(command)` — sets `message.functionPending = true`, renders a confirmation UI; on user approval, runs via another `Process` and streams output back as a `<think>` block; on rejection, sends "Command rejected" back to the model.
- `switch_to_search_mode` (Gemini-only) — flips `currentTool = "search"`, registers a `postResponseHook` to flip back after the next response. Lets the model self-promote to web search when it realizes the user needs it.

**Confirmation-loop pattern** (Ai.qml:768-801):
```
Model emits function_call → UI shows pending bubble
  → User approves → child Process runs, stdout streams into message
  → Process exits → continueLoop() makes another request with the function output
```
This is the same pattern you'd use for any agentic loop. Note that `requester.makeRequest()` is called recursively after each tool output.

### 8.4 Chat persistence

Chats serialize to JSON (an array of message objects) in `Directories.aiChats`. A `lastSession` file auto-saves after every response. Loading restores `messageIDs`/`messageByID` by replaying the array. Each message has `{role, content, rawContent, model, functionCall, functionResponse, annotations, annotationSources, fileMimeType, fileUri, localFilePath, visibleToUser, ...}`.

### 8.5 Slash-command framework

`AiChat.qml` defines `allCommands: [{name, description, execute(args)}]`. Input parsing:
- Starts with `/` → split on space, find command, call `execute(args)`.
- Otherwise → `Ai.sendUserMessage(text)`.

Commands: `/model`, `/tool`, `/prompt`, `/key`, `/save`, `/load`, `/clear`, `/temp`, `/attach`, `/test`. Auto-completion uses **fuzzysort.js** (vendored at `modules/common/functions/fuzzysort.js`) — context-aware: typing `/model ` triggers model-name fuzzy match, `/prompt ` triggers prompt-file match, etc.

### 8.6 System prompt templating

Substitutions at send time: `{DISTRO}`, `{DE}`, `{DATETIME}`, `{WINDOWCLASS}` replaced from `SystemInfo`, `DateTime`, `ToplevelManager.activeToplevel.appId`. Trivial to extend.

### 8.7 Image paste from clipboard

`AiChat.qml:661-684` — intercepts Ctrl+V, inspects `Cliphist.entries[0]`. If it matches `binary data \d+x\d+`, pipes through `cliphist decode > /tmp/.../image` and attaches. If it starts with `file://`, attaches directly. Shift+Ctrl+V bypasses (plain text paste).

### 8.8 Local Ollama auto-discovery

A `Process { command: scripts/ai/show-installed-ollama-models.sh }` lists installed Ollama models on startup; they're added to the model registry with `endpoint: "http://localhost:11434/v1/chat/completions"`, `requires_key: false`. Model name and logo are inferred from the model string (Ai.qml:331-350).

### 8.9 Keyring storage

API keys live in `KeyringStorage.qml` (libsecret backed, with a `loaded` flag and async fetch). UI shows "missing key" state on `apiKeysLoaded && !apiKeys[model.key_id]`. Never write keys to the config JSON.

---

## 9. Notifications

**Reference files:** `services/Notifications.qml`, `modules/<area>/notificationPopup/`, `modules/common/widgets/Notification*.qml`.

### 9.1 Service shape

Wraps `Quickshell.Services.Notifications` and adds:
- **Persistence**: JSON file under `Directories.notificationsPath`.
- **Per-notification timeout `Timer`** child component (created on receive, destroys self on fire). The timer chooses **discard** for `hints.transient` notifications vs **timeout** for persistent ones — keeping non-transient in the history but removing the popup.
- **Popup list**: a `filter(n => n.popup)` derived property. UI binds to this for the stack.
- **`popupInhibited`** — suppresses popups while the right sidebar (notif center) is open or `silent` is set.
- **Per-app latest-time** tracking for group sorting.
- **`unread` counter** + `Notifications.silent` toggle.

### 9.2 Persistence trick

The list is serialized as JSON; on load, each entry resurrects as a `Notif` QtObject component **without an associated `Notification` instance** (you can't restore the live DBus handle). UI must handle `notification === null` gracefully — actions are no-ops on resurrected entries.

### 9.3 Center vs popup vs indicator

- **Popup**: top-corner stack with slide animation, auto-dismiss.
- **Center**: list inside a sidebar panel, grouped by app via shared `NotificationGroup`/`NotificationListView` widgets.
- **Bar indicator**: unread count badge (`NotificationUnreadCount.qml`).

All three views read the **same** `Notifications.list` — no duplication.

---

## 10. Workspace Switcher (Overview)

**Reference files:** `modules/<area>/overview/{Overview,OverviewWidget,OverviewWindow,SearchWidget,SearchBar,SearchItem}.qml`.

### 10.1 Architecture

A single fullscreen `PanelWindow` with `WlrLayer.Top` and `mask: Region { item: columnLayout }` (so clicks outside the actual widgets dismiss). Visible only when `GlobalStates.overviewOpen`.

Contents: `SearchWidget` (launcher / clipboard / emoji) stacked above `OverviewWidget` (workspace grid).

### 10.2 Workspace grid rendering

`OverviewWidget.qml`:
- A `Repeater` grid of `rows × columns` workspace cells (configurable).
- Workspaces are grouped: workspace IDs `1..rows*columns` are group 0, next batch is group 1, etc. `workspaceGroup = Math.floor((activeWorkspaceId - 1) / workspacesShown)`.
- Cell colors and corner radii adapt to position (rounded only at corners of the whole grid).
- A separate "windows" layer overlays the grid — each toplevel is rendered as a draggable rectangle scaled by `Config.options.overview.scale` and positioned proportionally to the real window's `at[0]/at[1]` relative to the monitor's reserved insets.

### 10.3 Window source

`ToplevelManager.toplevels.values` filtered to those whose Hyprland address matches `windowByAddress` (from `HyprlandData`). Hyprland addresses come from `HyprlandData`; toplevels come from Wayland — joining the two gives both the foreign-toplevel handle (for screencopy thumbnails) AND the Hyprland metadata (workspace, position, fullscreen flag).

### 10.4 Drag-to-move

Each `OverviewWindow` is `Drag.active = true` on press, with `DropArea` on each workspace cell tracking `draggingTargetWorkspace`. On release:
- If dropped on a different workspace → `Hyprland.dispatch("hl.dsp.window.move({workspace=N, follow=false, window='address:0x...'})")`.
- If dropped within the same workspace and the window is floating → compute percentage position and dispatch `hl.dsp.window.move({x, y, window=...})`.
- Else snap back via `updateWindowPosition.restart()`.

### 10.5 Click behaviors

- Left-click workspace → focus that workspace, close overview.
- Left-click window → focus that window, close overview.
- Middle-click window → close it.
- Right-click bar workspaces widget → toggle overview (BarContent.qml:138-149).

### 10.6 Combined search/launcher entry

Overview doubles as the launcher. Prefix-aware:
- No prefix → app fuzzy-search (`LauncherSearch` + `LauncherApps`).
- Config-defined prefixes: `>` (commands), `?` (web), `=` (math eval), `:emoji`, plus clipboard (`Super+V` opens overview pre-filled with the clipboard prefix) and emoji (`Super+.`).
- "Open with clipboard query" sets `dontAutoCancelSearch = true` so subsequent toggles don't reset the search text. (Overview.qml:106-124)

---

## 11. NixOS / Declarative Config Integration Notes

A NixOS shell config is partly read-only (the Nix store) and partly writable (user state). Plan for this from day one.

### 11.1 What must be writable at runtime

| Path | Why |
|---|---|
| `~/.config/illogical-impulse/config.json` (or your equivalent) | Users edit via settings app & AI tool call |
| `~/.local/state/<shell>/user/generated/colors.json` | matugen output |
| `~/.local/state/<shell>/user/generated/wallpaper/path.txt` | wallpaper pointer |
| `~/.local/state/<shell>/persistent.json` | UI state (last model, scroll positions) |
| `~/.local/state/<shell>/ai/chats/*.json` | AI chat history |
| `~/.local/state/<shell>/notifications.json` | notification persistence |
| `~/.local/state/<shell>/cliphist*` | clipboard cache |
| `~/.config/hypr/hyprland/colors.lua` | matugen output (or move to state) |
| `~/.config/gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` | matugen output |

### 11.2 What can live in the store

- QML files (`shell.qml`, modules, services, widgets).
- `matugen` template files.
- Default prompts / palettes.
- Static `assets/`.
- Translations.

### 11.3 Bridging patterns

- **`mkOutOfStoreSymlink`** in home-manager for files the shell rewrites (matugen templates if you want them under home-manager management, but they still need to render to writable outputs).
- **Bootstrap defaults**: on first run, `Config.qml` writes the JsonAdapter defaults if the file doesn't exist (`onLoadFailed: if (error == FileNotFound) writeAdapter()`). Pair this with `xdg.configFile."illogical-impulse/config.default.json".source = ...` and a `programs.<shell>.activation` snippet that copies the default if the user file is missing.
- **`Directories.qml` resolves all paths from env** (`$XDG_CONFIG_HOME`, `$XDG_STATE_HOME`, `$HOME`); don't hard-code paths anywhere else.
- **Scripts**: the reference shell calls bash scripts from `scripts/`. On NixOS, either:
  1. Vendor them in-store and reference via `Quickshell.shellPath("scripts/foo.sh")` — they're executable from the store.
  2. Or rewrite them as inline `Process` commands using nix-store-resolved binaries (`${pkgs.curl}/bin/curl`).
- **AI request script** at `/tmp/quickshell/ai/request.sh` — `/tmp` is fine on NixOS but consider `$XDG_RUNTIME_DIR` for security (only-owner-readable).

### 11.4 Hyprland config

The reference uses the **Lua plugin** for Hyprland (`hyprland.lua` + `general.lua`/`keybinds.lua`/`rules.lua`/`execs.lua`/`variables.lua`/`colors.lua`). This is much easier to merge with matugen output than the flat text format. On NixOS, the Lua plugin needs the matching Hyprland version — check `nixpkgs` for the `hyprland-plugins` package set. Alternatively, the standard `wayland.windowManager.hyprland.settings` home-manager option works fine if you don't want Lua.

### 11.5 Packaging Quickshell on NixOS

The `illogical-impulse-quickshell-git` distro package (see `sdata/dist-arch/illogical-impulse-quickshell-git/`) pins a specific Quickshell commit. On NixOS use `inputs.quickshell.packages.${system}.default` (the upstream flake) and pin the rev in `flake.lock`. Required Qt extras: `qt6-multimedia`, `qt6-imageformats`, `qt6-svg`, `qt6-shadertools`, plus `qmlls` if you want LSP.

### 11.6 Declarative-config-meets-AI-rewriting-config

The AI's `set_shell_config` tool writes to the JSON file. If you make that JSON Nix-managed (read-only symlink to store), the AI can't edit it. Solutions:
1. Keep config JSON fully user-managed (writable) — accept that some defaults are duplicated between Nix and the JSON.
2. Layered config: Nix manages a `defaults.json` (read-only), user file in `~/.config/.../overrides.json` (writable), `Config.qml` merges at load. AI writes to overrides only.

Option 2 is the right NixOS shape but adds complexity; defer until you have a real need.

---

## 12. Per-Panel Implementation Notes (Full Catalog)

### 12.1 Bar (`modules/<area>/bar/`, ~30 files)

- Per-monitor via `Variants` + `screenList` filter.
- Top/bottom/vertical via three orthogonal Config flags. Vertical bar is a *separate* component (`verticalBar/`) — don't try to share, the layout is too different.
- Auto-hide modes: always, never, super-to-reveal (`Config.options.bar.autoHide.showWhenPressingSuper` with a debounce timer).
- Two corner styles: `Hug` (rounded screen-corner decorators via `RoundCorner.qml`) vs `Floating` (margin + shadow + border).
- `FocusedScrollMouseArea` on the left half scrolls brightness, right half scrolls volume — useful UX pattern: scroll-on-bar gives system-wide volume/brightness with no menu.
- Bar content composition: three groups (left/center/right) of `BarGroup` containers, each filled with widgets (`Resources`, `Media`, `Workspaces`, `ClockWidget`, `BatteryIndicator`, `UtilButtons`, `SysTray`, `NotificationUnreadCount`, `HyprlandXkbIndicator`, `WeatherBar`). The right-half is a giant `MouseArea` that toggles the right sidebar on click — gives a big hit target without sacrificing the displayed indicators.
- "Verbose" vs "shortened" mode based on screen width — degrade gracefully on small displays.
- **`Quickshell.Services.UPower`** for battery; **`Quickshell.Services.SystemTray`** for tray.

### 12.2 Dock (`modules/<area>/dock/`, 5 files, ~540 lines)

- Pin button → app group → overview button.
- App group is `StyledListView` over `TaskbarApps.apps` (grouped toplevels).
- Hover-preview popup with **window thumbnails** for grouped windows — uses `ScreencopyView` / `Quickshell.Widgets`.
- Debounced reveal timer (100ms) on the preview so quick mouse passes don't flicker.
- Pin sets `exclusiveZone`; unpinned auto-hides on toplevel-activated.
- `requestDockShow` chained to preview popup so the dock doesn't auto-hide while a preview is open.

### 12.3 OSD (`modules/<area>/onScreenDisplay/`)

- Triggered by `Brightness`/`Audio` service value changes (with `onMovedAway: GlobalStates.osdVolumeOpen = false` from the bar scroll area).
- Auto-dismiss timer.
- Pluggable indicators: volume, mic, brightness, lock-key state (caps/num).

### 12.4 On-Screen Keyboard (`modules/<area>/onScreenKeyboard/`)

- Uses **`Ydotool`** service for synthetic input.
- Key layout defined as a 2D array in JSON; rendered by repeater of `KeyboardKey.qml`.
- Modifier-key state machine; long-press for variants.

### 12.5 Cheatsheet (`modules/<area>/cheatsheet/`)

- Reads `HyprlandKeybinds` service (parses Hyprland binds + descriptions).
- Renders as searchable grouped list.
- Bonus: a hidden periodic-table tab (`periodic_table.js`, `ElementTile.qml`) — pattern for ad-hoc "fun" content using `Repeater` over a JS data file.

### 12.6 Session Screen (`modules/<area>/sessionScreen/`)

- Power menu: lock, suspend, reboot, shutdown, logout.
- `SessionActionButton.qml` is the base widget; commands resolved from `Session.qml` utility.
- Wlogout is the fallback (Hyprland bind chains to `wlogout` if shell down).

### 12.7 Lock Screen (`modules/<area>/lock/`)

- Reuses `modules/common/panels/lock/` for the actual lock UI.
- Backed by `Quickshell.Services.SessionLock` or a custom PAM helper (`PolkitService` for auth flow).
- `GlobalStates.screenLocked` gates *every other panel's* visibility (`visible: !GlobalStates.screenLocked`).

### 12.8 Background (`modules/<area>/background/`)

- Layer-shell window at `Background` layer, anchored fullscreen on each monitor.
- Image wallpaper via `StyledImage`; video wallpaper via `mpv` IPC (handled by external `mpvpaper` or embedded `Video` element).
- Auto-detection: `wallpaperPath.endsWith(".mp4"|".webm"|".mkv"|".avi"|".mov")` (Appearance.qml:18).

### 12.9 Wallpaper Selector (`modules/<area>/wallpaperSelector/`)

- Browses `Wallpapers` service (a `FolderListModelWithHistory`).
- Click → writes path to Config → matugen → MaterialThemeLoader update — the whole pipeline kicks off automatically.
- "Random wallpaper" shortcut picks a random entry.

### 12.10 Notification Popup (`modules/<area>/notificationPopup/`)

- Top-right stack, slide-in/out animations.
- Filters `Notifications.list` to `popup === true`.
- Inhibited while notif center is open.

### 12.11 Polkit Dialog (`modules/<area>/polkit/`)

- Full-screen auth modal triggered by `PolkitService`.
- Username display, password input, retry counter.

### 12.12 Region Selector (`modules/<area>/regionSelector/`)

- Slurp-style region picker for screenshot/record/OCR/translate/Google-Lens.
- Each "mode" is a different post-selection action: pipe to `grim+wl-copy`, `tesseract`, `wf-recorder`, `snip_to_search.sh`.
- One UI, many backends — pattern: select region → resolve `action` → dispatch.

### 12.13 Screen Corners (`modules/<area>/screenCorners/`)

- Pure cosmetic anti-aliased corner masks. Tiny `RoundCorner.qml` widget anchored to screen corners.

### 12.14 Screen Translator (`modules/<area>/screenTranslator/`)

- Region selector → OCR → translation overlay positioned over original text.
- Translation backend in `services/Translation.qml`.

### 12.15 Overlay / Widget Canvas (`modules/<area>/overlay/`)

- Desktop-widget canvas for always-on extras (analog clock, calendar, system monitor).
- `modules/common/widgets/widgetCanvas/{AbstractWidget,AbstractOverlayWidget,WidgetCanvas}.qml` is the base library.
- Widgets drag-positioned, positions persisted to `Persistent`.

### 12.16 Media Controls (`modules/<area>/mediaControls/`)

- MPRIS via `MprisController` (singleton).
- Duplicate filtering: Plasma-browser-integration vs raw browser bus, playerctld exclusion, MPD non-instance bus exclusion (MprisController.qml:28-44).
- CAVA audio visualizer: spawn `cava -p raw_output_config.txt`, parse `;`-separated bars, render via `WaveVisualizer.qml`.
- Per-player card with album art, scrubber, transport controls, dominant-color background (extracted via `ColorQuantizer`).

### 12.17 Vertical Bar

Pure stylistic variant of the bar — entirely separate implementation. Skip unless you specifically want a side bar; if so, expect to duplicate ~70% of bar layout code.

### 12.18 Alternative Panel Family (Waffle)

The reference ships a *complete second visual style* (Windows-11-like) sharing only services and `modules/common/`. Don't do this unless your product needs theming-as-a-feature. Single visual style → drop the panel-family indirection from §4.3.

---

## 13. Widget Catalog (Names + Purpose Only)

From `modules/common/widgets/` — 113 widgets, grouped by category. Use as an inventory of what's typically needed; you'll diverge on visual style but the *set* of needed widgets is similar.

**Buttons / interactive:** `RippleButton`, `RippleButtonWithIcon`, `GroupButton`, `ButtonGroup`, `FloatingActionButton`, `IconToolbarButton`, `IconAndTextToolbarButton`, `MenuButton`, `DialogButton`, `SelectionGroupButton`, `FlowButtonGroup`, `VibrantToolbarButton`, `VerticalButtonGroup`, `SecondaryTabButton`, `ToolbarButton`, `ToolbarTabButton`, `ToolbarPairedFab`.

**Inputs:** `MaterialTextField`, `MaterialTextArea`, `StyledTextInput`, `StyledTextArea`, `StyledComboBox`, `StyledSlider`, `StyledSpinBox`, `StyledSwitch`, `StyledRadioButton`, `KeyboardKey`, `AddressBar`, `AddressBreadcrumb`.

**Display / typography:** `StyledText`, `SqueezedAnnotationStyledText`, `MaterialSymbol` (Material Icons font wrapper), `OptionalMaterialSymbol`, `MaterialShape`, `MaterialShapeWrappedMaterialSymbol`, `CustomIcon`, `DirectoryIcon`, `Favicon`, `StyledImage`, `ThumbnailImage`.

**Layout / containers:** `ContentPage`, `ContentSection`, `ContentSubsection`, `ContentSubsectionLabel`, `ConfigRow`, `Toolbar`, `ToolbarTabBar`, `SecondaryTabBar`, `NavigationRail`, `NavigationRailButton`, `NavigationRailExpandButton`, `NavigationRailTabArray`, `WindowDialog`, `WindowDialogTitle`, `WindowDialogParagraph`, `WindowDialogSectionHeader`, `WindowDialogSeparator`, `WindowDialogSlider`, `WindowDialogButtonRow`, `FullscreenPolkitWindow`.

**Scrolling / lists:** `StyledFlickable`, `StyledListView`, `StyledScrollBar`, `ScrollEdgeFade`, `FocusedScrollMouseArea`, `DialogListItem`.

**Progress / loading:** `MaterialLoadingIndicator`, `StyledProgressBar`, `StyledIndeterminateProgressBar`, `ClippedProgressBar`, `CircularProgress`, `ClippedFilledCircularProgress`, `Graph`.

**Effects / shapes:** `Circle`, `RoundCorner`, `DashedBorder`, `MaterialCookie` (squircle), `SineCookie`, `WavyLine`, `WaveVisualizer`, `MaskMultiEffect`, `StyledBlurEffect`, `StyledDropShadow`, `StyledRectangularShadow`, `ErrorShakeAnimation`, `Revealer`, `FadeLoader`, `PagePlaceholder`, `NoticeBox`, `PointingHandInteraction`, `PointingHandLinkHover`.

**Calendar:** `CalendarView`, `WeekRow`.

**Tooltips:** `StyledToolTip`, `StyledToolTipContent`, `PopupToolTip`.

**Dialogs:** `SelectionDialog`.

**Notifications (used by both popup and center):** `NotificationItem`, `NotificationGroup`, `NotificationGroupExpandButton`, `NotificationListView`, `NotificationAppIcon`, `NotificationActionButton`.

**Config UI (used by settings app):** `ConfigSwitch`, `ConfigSlider`, `ConfigSpinBox`, `ConfigSelectionArray`, `ConfigRow`.

**Other:** `CliphistImage`, `DragManager`.

The setting-app DSL — `ContentPage > ContentSection > ConfigRow > ConfigSwitch/Slider/Etc` — is worth copying verbatim. Wires straight into the `Config.options.*` properties; one line per setting.

---

## 14. Settings App Pattern

**Reference file:** `settings.qml` + `modules/settings/{Quick,General,Bar,Background,Interface,Services,Advanced,About}Config.qml`.

- Separate `qs -p settings.qml` process (see §1).
- `ApplicationWindow` with left `NavigationRail` and a `Loader` content area.
- Pages are *just QML files*; navigation is `pageLoader.source = pages[currentPage].component`.
- Animated page transitions: `SequentialAnimation` fades out, swaps `source`, fades in.
- One `FloatingActionButton` opens the raw JSON config in `$EDITOR` — useful escape hatch.
- The settings app sets `Config.readWriteDelay = 0` (no debounce) because it changes one var at a time.
- **No bespoke event wiring** between settings and shell — both observe the same JSON file.
- Pages use the `ContentPage > ContentSection > ConfigSwitch/Slider/SelectionArray` DSL — see BarConfig.qml for the canonical example. Each control's `checked`/`currentValue` binds to `Config.options.*`, and `onChanged` writes back.

For a custom shell, copy this whole-cloth and replace pages as your config schema grows.

---

## 15. Process Management Helpers

Patterns the reference uses repeatedly:

- **`SplitParser`** — line-buffered stdout parsing (use for SSE/JSON-stream/cava/notify-send tails).
- **`StdioCollector`** — full-output collection (use for `hyprctl -j`, `ls`, one-shot commands).
- **`FileView`** — declarative file IO with `watchChanges`, `onLoaded`, `onLoadFailed`, `JsonAdapter`. Cleaner than `Qt.openUrlExternally` + manual `XMLHttpRequest`.
- **`Process { running: ...; environment: {...}; command: [...] }`** — long-lived processes. `onExited: restart` pattern for daemons.
- **`Quickshell.execDetached(["cmd", ...])`** — fire-and-forget. Use for spawning the settings app or `hyprctl reload`.

---

## 16. Hyprland Integration Tricks

- **Lua-plugin Hyprland config** lets you `require("custom.variables")`, use real if-statements, loop over keybind directions (`for i = 1, 6 do ... end` in keybinds.lua:94-98), include generated `colors.lua` cleanly.
- **`hl.dsp.global("quickshell:<name>")`** dispatches a no-delay shell event via `GlobalShortcut`.
- **Bind fallback chain**: every shell-integrated bind has a `qsIsAlive || pkill fuzzel || fuzzel`-style fallback so the system stays usable when the shell is down. Adopt universally.
- **`HyprlandData`** polls `hyprctl -j` on socket events to expose typed window/monitor/workspace data. UI binds these without polling itself.
- **`Hyprland.dispatch("hl.dsp.window.move({...})")`** is the shell→Hyprland command channel. JSON-like args.
- **Cursor-dodge workaround** when toggling exclusiveZone (see §4.5).
- **Anti-flashbang shader** (`HyprlandAntiFlashbangShader.qml`) — overlay shader that smooths brightness on theme transitions. Optional but nice.

---

## 17. Gotchas / Anti-Patterns to Avoid

- **`schedule: replaceAll`** — QML JS doesn't support `String.prototype.replaceAll`. Use `split(key).join(val)` (Ai.qml:33-39).
- **Stale `FileView` after external rewrite** — sometimes you need to clear and re-set `filePath` after an external write to force a fresh read (MaterialThemeLoader.qml:43-50).
- **`GlobalShortcut.onReleased`** fires on key-up even if other keys were pressed in between. Use the `searchToggleRelease`/`searchToggleReleaseInterrupt` two-shortcut pattern with a `binditn` catchall submap if you need *tap-vs-hold* discrimination.
- **Race conditions on Hyprland window move** — there's a `Config.options.hacks.arbitraryRaceConditionDelay` for a reason. Window position updates after a Hyprland dispatch lag by ~50-100ms; use a Timer.
- **Workspace IDs leak large values** during lock screen (Hyprland uses `2147483647 - N` for temp lock workspaces). Clamp before rendering: `Math.max(1, Math.min(100, id))` (OverviewWidget.qml:20).
- **Schemas drift** — adding a new `JsonObject` property doesn't remove old keys from user files. Plan a migration step or accept stale keys.
- **`replaceAll` analog**: same goes for `Array.prototype.flat` in older Qt — check before using newer JS.
- **Touching the AI request script directly while running** — the `FileView` writes it, the `Process` runs it; if both fire in the same frame, you can race. The reference uses `requesterScriptFile.setText(content)` synchronously, then `requester.running = true`.

---

## 18. Verification (End-to-End)

When implementing the new shell, the following milestones are testable end-to-end:

1. **Boot up baseline**: `quickshell -c <name>` launches with no errors, empty `shell.qml` shows nothing. Add a `PanelWindow` with a colored rectangle; confirm it appears on every monitor.
2. **Config round-trip**: edit `config.json` externally → shell reflects the change. Click a `ConfigSwitch` in the settings app → file updates. Both shell and settings open simultaneously → both react.
3. **GlobalShortcut**: bind a Hyprland key to `hl.dsp.global("quickshell:test")`, listen with a `GlobalShortcut`, log on press. Confirm zero latency vs a `hl.dsp.exec_cmd` baseline.
4. **IPC**: `qs ipc call sidebarLeft toggle` toggles a panel from a shell prompt.
5. **Theme pipeline**: change wallpaper → run matugen manually → confirm `Appearance.m3primary` updates and bound UI re-colors.
6. **AI streaming**: send a message, watch `requester.stdout` lines arrive and `message.content` grow incrementally. Test with a slow local Ollama model to see chunks.
7. **Overview drag**: drag a window between workspaces, confirm Hyprland dispatch fires.
8. **Notifications**: `notify-send "test"` → popup appears with timeout. Open notif center → popup inhibited. Close center → popup resumes. Restart shell → persistent notification list survives.
9. **Settings app**: launch `qs -p settings.qml`, navigate pages, confirm modifications hit the JSON file and the running shell reacts.
10. **NixOS rebuild**: `home-manager switch` (or `nixos-rebuild switch --flake`) — the shell, scripts, and matugen templates should land in the right paths with the right permissions. Mutable state under `~/.local/state/` should survive rebuilds.

---

## 19. Critical Files Index (Reference Repo)

When you need to look something up, here are the highest-value files to read first in the reference:

- `shell.qml` — entry point, panel-family wiring (76 lines, read in full).
- `modules/common/Config.qml` — JSON config + hot reload (top 100 lines).
- `modules/common/Appearance.qml` — color tokens, sizes, transparency derivation.
- `services/Ai.qml` — AI subsystem (917 lines, the canonical example of streaming + tool calls).
- `services/Notifications.qml` — persistent notifications wrapper.
- `services/MprisController.qml` — duplicate filtering, active player tracking.
- `services/MaterialThemeLoader.qml` — theme hot-reload.
- `services/HyprlandData.qml` — Hyprland JSON polling.
- `services/TaskbarApps.qml` — toplevel grouping for dock/taskbar.
- `modules/ii/bar/{Bar,BarContent}.qml` — bar layout, per-monitor pattern.
- `modules/ii/dock/{Dock,DockApps,DockAppButton}.qml` — preview popups, hover reveal, masks.
- `modules/ii/overview/{Overview,OverviewWidget,OverviewWindow}.qml` — workspace switcher, drag-drop, search prefixes.
- `modules/ii/sidebarLeft/{SidebarLeft,SidebarLeftContent,AiChat}.qml` — detach pattern, tab UI, chat shell.
- `modules/ii/sidebarRight/SidebarRightContent.qml` — control center composition.
- `modules/ii/mediaControls/{MediaControls,PlayerControl}.qml` — MPRIS + visualizer.
- `settings.qml` — settings app shell.
- `modules/settings/BarConfig.qml` — canonical settings-page example.
- `dots/.config/matugen/config.toml` — matugen template wiring.
- `dots/.config/hypr/hyprland/keybinds.lua` — Hyprland → shell bind patterns.

---

## 20. What This Plan Does NOT Cover

Defer to future planning sessions:
- Visual design (you said you're diverging — start with a simple monochrome theme and add tokens as needed).
- Exact list of panels for v1 (likely a subset: bar + overview + notifs + sidebar/AI + settings).
- Which AI providers to ship (Ollama only? + one cloud? defer).
- Wallpaper selection UX (file picker? thumbnails? folder watch?).
- Whether to support the alternative panel family (recommended: no).
- Test framework (QML has no real unit test story — likely manual E2E + maybe scripted IPC smoke tests).
- Distribution (flake + home-manager module vs. plain `xdg.configFile`).

These should be addressed in follow-up plans once the architectural foundation is in.
