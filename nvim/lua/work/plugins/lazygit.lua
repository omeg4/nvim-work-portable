return {
  -- Requires the `lazygit` binary (installed to ~/.local/bin by install.sh).
  'kdheepak/lazygit.nvim',
  cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
  dependencies = {
    'nvim-lua/plenary.nvim',
  }
}
