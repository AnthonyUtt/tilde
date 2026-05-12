local M = {}

M.opts = {
  -- Command line arguments passed to aider
  args = {
    "--model openai/o4-mini",
    "--no-auto-commits",
    "--pretty",
    "--stream",
    "--vim",
  },
  -- Theme colors (automatically uses Catppuccin flavor if available)
  theme = {
    user_input_color = "#a6da95",
    tool_output_color = "#8aadf4",
    tool_error_color = "#ed8796",
    tool_warning_color = "#eed49f",
    assistant_output_color = "#c6a0f6",
    completion_menu_color = "#cad3f5",
    completion_menu_bg_color = "#24273a",
    completion_menu_current_color = "#181926",
    completion_menu_current_bg_color = "#f4dbd6",
  },
  -- snacks.picker.layout.Config configuration
  picker_cfg = {
    preset = "vscode",
  },
  -- Other snacks.terminal.Opts options
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  win = {
    wo = { winbar = "Aider" },
    style = "nvim_aider",
    position = "right",
  },
}

M.keys = {
  -- { key, cmd, ...options }
  { "<leader>ct", "<cmd>Aider toggle<CR>", desc = "Aider: Toggle" },
  { "<leader>cs", "<cmd>Aider send<CR>", desc = "Aider: Send to Aider", mode = { "n", "v" } },
  { "<leader>cc", "<cmd>Aider command<CR>", desc = "Aider: Commands" },
  { "<leader>cb", "<cmd>Aider buffer<CR>", desc = "Aider: Add Current Buffer" },
  { "<leader>cp", "<cmd>Aider add<CR>", desc = "Aider: Add File" },
  { "<leader>cd", "<cmd>Aider drop<CR>", desc = "Aider: Remove File" },
  { "<leader>cr", "<cmd>Aider add readonly<CR>", desc = "Aider: Add File (Read-Only)" },
  { "<leader>cp", "<cmd>AiderTreeAddFile<CR>", desc = "Aider: Add File (NvimTree)", ft = "NvimTree" },
  { "<leader>cd", "<cmd>AiderTreeDropFile<CR>", desc = "Aider: Remove File (NvimTree)", ft = "NvimTree" },
}

return M
