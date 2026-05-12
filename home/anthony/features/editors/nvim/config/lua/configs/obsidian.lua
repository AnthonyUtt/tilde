return {
  workspaces = {
    {
      name = "notes",
      path = "~/source/notes",
    }
  },
  notes_subdir = "00_Fleeting_Notes",
  completion = {
    nvim_cmp = true,
    min_chars = 2,
  },
  new_notes_location = "notes_subdir",
}
