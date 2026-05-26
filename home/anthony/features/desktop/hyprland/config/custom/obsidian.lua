-- Obsidian setup
-- Pinned to dedicated workspace
-- Auto-opened on startup
-- Window/workspace rules for dedicated placement

hl.bind("SUPER + Y", hl.dsp.workspace.toggle_special("notes"))

hl.window_rule({
  match = { workspace = "special:notes" },
  float = true,
  size = { "monitor_w*0.3", "monitor_h*0.6" },
  move = { "monitor_w*0.6", "monitor_h*0.2" },
  stay_focused = true,
})

hl.workspace_rule({
  workspace = "special:notes",
  on_created_empty = "obsidian",
})
