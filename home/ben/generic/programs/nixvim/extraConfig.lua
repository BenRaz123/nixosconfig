vim.cmd [[ color retrobox ]]

require("gitsigns").setup {
	signs = {
		add = { text = "+" },
		change = { text = "/" },
		delete = { text = "-" },
	},
	signs_staged = {
		add = { text = "+" },
		change = { text = "/" },
		delete = { text = "-" },
	}
}

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	update_in_insert = true,
	underline = true,
	severity_sort = false,
	float = true,
})

vim.api.nvim_set_hl(0, "CmpNormal", { link = "Normal" })
vim.api.nvim_set_hl(0, "CmpSecondary", { link = "Conceal" })
