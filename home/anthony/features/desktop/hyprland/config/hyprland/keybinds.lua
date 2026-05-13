local mod = "SUPER + "
local modShift = mod .. "SHIFT + "

-- Mouse
hl.bind(mod.."mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move" })
hl.bind(mod.."mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize" })

-- Programs
hl.bind(mod.."Space", hl.dsp.exec_cmd("wofi"))
hl.bind(mod.."Return", hl.dsp.exec_cmd("ghostty"))
hl.bind("Print", hl.dsp.exec_cmd("flameshot gui"))

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
