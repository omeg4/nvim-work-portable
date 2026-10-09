return {
  -- NOTE: archived upstream (read-only). Pure Lua, no network access; pinned via lazy-lock.json.
  'ziontee113/icon-picker.nvim',
  cmd = { "IconPickerNormal", "IconPickerInsert", "IconPickerYank" },
  config = function()
    require("icon-picker").setup({
      disable_legacy_commands = true
    })
  end,
}
