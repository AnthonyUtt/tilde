local M = {}

M.opts = {
  -- Build out-of-source into <project root>/build, matching the layout
  -- the project scripts use. clangd finds build/compile_commands.json on
  -- its own, so don't litter the project root with a link or copy of it.
  cmake_build_directory = "build",
  cmake_soft_link_compile_commands = false,
  cmake_compile_commands_from_lsp = false,
  cmake_regenerate_on_save = true,
  cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
}

M.mappings = {
  -- { mode, mapping, effect, options },
  { "n", "<leader>mg", "<cmd>CMakeGenerate<cr>", { desc = "CMake generate" } },
  { "n", "<leader>mb", "<cmd>CMakeBuild<cr>", { desc = "CMake build" } },
  { "n", "<leader>mr", "<cmd>CMakeRun<cr>", { desc = "CMake run" } },
  { "n", "<leader>mt", "<cmd>CMakeSelectBuildType<cr>", { desc = "CMake select build type" } },
  { "n", "<leader>ms", "<cmd>CMakeSelectLaunchTarget<cr>", { desc = "CMake select launch target" } },
  { "n", "<leader>mc", "<cmd>CMakeClean<cr>", { desc = "CMake clean" } },
  { "n", "<leader>mq", "<cmd>CMakeStopExecutor<cr>", { desc = "CMake stop build" } },
}

return M
