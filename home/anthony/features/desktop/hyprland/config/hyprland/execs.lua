-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd("mako")
  hl.exec_cmd("quickshell")

  hl.exec_cmd("pactl load-module module-combine-sink")
  hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 24")
end)
