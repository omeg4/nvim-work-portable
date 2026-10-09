return {
	"nvim-mini/mini.nvim", -- moved from echasnovski/mini.nvim
	version = false,
	config = function()
		require("mini.align").setup({
			mappings = {
				start = "ga",
				start_with_preview = "gA",
			},
		})
	end,
}
