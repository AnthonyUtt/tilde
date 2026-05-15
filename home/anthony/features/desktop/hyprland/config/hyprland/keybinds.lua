local mod = "SUPER + "
local modShift = mod .. "SHIFT + "

-- Mouse
hl.bind(mod.."mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move" })
hl.bind(mod.."mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize" })

-- Programs
hl.bind(mod.."Return", hl.dsp.exec_cmd("ghostty"))

-- Exits
hl.bind(modShift.."Q", hl.dsp.window.close())
hl.bind(modShift.."E", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Special Workspace
hl.bind(mod.."U", hl.dsp.workspace.toggle_special("magic"))
hl.bind(modShift.."U", hl.dsp.window.move({ workspace = "special:magic" }))

-- Windows
hl.bind(mod.."T", hl.dsp.layout("swapwithmaster auto"))
hl.bind(modShift.."T", hl.dsp.layout("focusmaster auto"))
-- move focus (vim motions)
hl.bind(mod.."H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod.."J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod.."K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod.."L", hl.dsp.focus({ direction = "right" }))

-- move window (vim motions)
hl.bind(modShift.."H", hl.dsp.window.move({ direction = "left" }))
hl.bind(modShift.."J", hl.dsp.window.move({ direction = "down" }))
hl.bind(modShift.."K", hl.dsp.window.move({ direction = "up" }))
hl.bind(modShift.."L", hl.dsp.window.move({ direction = "right" }))

-- Floating
hl.bind(modShift.."Space", hl.dsp.window.float({ action = "toggle" }))

-- Quickshell panels
hl.bind(mod.."Space",          hl.dsp.global("quickshell:overviewWorkspacesToggle"), { description = "Overview / launcher" })
hl.bind(mod.."A",              hl.dsp.global("quickshell:sidebarLeftToggle"),         { description = "AI sidebar" })
hl.bind(mod.."ALT + A",        hl.dsp.global("quickshell:sidebarLeftToggleDetach"),   { description = "Detach AI sidebar" })
hl.bind(mod.."N",              hl.dsp.global("quickshell:sidebarRightToggle"),        { description = "Control center" })
hl.bind(mod.."Tab",            hl.dsp.global("quickshell:overviewWorkspacesToggle"),  { description = "Overview" })
hl.bind(mod.."V",              hl.dsp.global("quickshell:overviewClipboardToggle"),   { description = "Clipboard history" })
hl.bind(mod.."Period",         hl.dsp.global("quickshell:overviewEmojiToggle"),       { description = "Emoji picker" })
hl.bind(mod.."Slash",          hl.dsp.global("quickshell:cheatsheetToggle"),          { description = "Cheatsheet" })
hl.bind(mod.."M",              hl.dsp.global("quickshell:mediaControlsToggle"),       { description = "Media controls" })
hl.bind(mod.."G",              hl.dsp.global("quickshell:overlayToggle"),             { description = "Widget overlay" })
hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:sessionToggle"),             { description = "Session menu" })

-- Wallpaper
hl.bind("CTRL + SUPER + T",       hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Wallpaper picker" })
hl.bind("CTRL + SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"), { description = "Random wallpaper" })

-- Screenshot / record (replaces flameshot)
hl.bind("Print",         hl.dsp.global("quickshell:regionScreenshot"), { description = "Region screenshot" })
hl.bind(modShift.."S",   hl.dsp.global("quickshell:regionScreenshot"))
hl.bind(modShift.."R",   hl.dsp.global("quickshell:regionRecord"),     { locked = true, description = "Region record" })
hl.bind(modShift.."A",   hl.dsp.global("quickshell:regionSearch"),     { description = "Region image search" })
hl.bind(modShift.."X",   hl.dsp.global("quickshell:regionOcr"),        { description = "OCR region" })

-- Welcome wizard (rebindable)
hl.bind("SUPER + SHIFT + ALT + Slash", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/welcome.qml"))

-- Restart shell
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall quickshell; quickshell &"), { description = "Restart shell" })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
