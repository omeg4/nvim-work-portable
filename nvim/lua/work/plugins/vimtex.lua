-- Only loaded when a TeX distribution is on PATH (e.g. a per-user MiKTeX install, no admin needed).
return {
  'lervag/vimtex',
  cond = vim.fn.executable("latexmk") == 1,
  ft = { "tex", "bib" },
  dependencies = { "micangl/cmp-vimtex" },
  init = function()
    vim.g['vimtex_version_check'] = 0
    if vim.fn.executable("SumatraPDF") == 1 then
      vim.g['vimtex_view_method'] = 'sumatrapdf'
    elseif vim.fn.executable("zathura") == 1 then
      vim.g['vimtex_view_method'] = 'zathura'
    else
      vim.g['vimtex_view_method'] = 'general'
    end
    vim.g['vimtex_quickfix_mode'] = 0
    vim.g['vimtex_mappings_enabled'] = 1
    vim.g['vimtex_mappings_prefix'] = "<LocalLeader>l"
    vim.g['vimtex_indent_enabled'] = 0
    vim.g['vimtex_syntax_enabled'] = 0 -- Treesitter does this already
    vim.g['vimtex_log_ignore'] = ({
      'Underfull',
      'Overfull',
      'specifier changed to',
      'Token not allowed in a PDF string',
    })
    vim.g['vimtex_compiler_method'] = 'latexmk'
    vim.g['vimtex_compiler_latexmk'] = ({
      executable = 'latexmk', -- from PATH instead of /usr/bin/latexmk
      continuous = 1,
      callback = 1,
      options = {
        '-verbose',
        '-synctex=1',
        '-interaction=nonstopmode',
      }
    })
    vim.g['vimtex_compiler_latexmk_engines'] = ({
      _ = '-xelatex'
    })
  end,
  config = function()
    require("cmp").setup.filetype("tex", {
      sources = {
        { name = "vimtex" },
        { name = "buffer" },
      },
    })
  end,
}
