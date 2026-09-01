-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()
  -- Export the compositor environment (WAYLAND_DISPLAY, etc.) into the systemd
  -- user manager and D-Bus so UWSM-managed graphical-session services see it.
  -- Must run before anything that relies on that environment.
  hl.exec_cmd("uwsm finalize")

  hl.exec_cmd("quickshell")

  hl.exec_cmd("pactl load-module module-combine-sink")
  hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 24")
end)
