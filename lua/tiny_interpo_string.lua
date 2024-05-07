local M = {}
local utils = require("utils")

local function need_to_replace_at_start(buf, interpo, at_start, node_type)
	if vim.v.char ~= interpo then
		return
	end

	-- Get node and return early if not in a string
	local node = vim.treesitter.get_node()

	if not node then
		return
	end
	if node:type() ~= node_type then
		node = node:parent()
	end
	if not node or node:type() ~= node_type then
		return
	end

	local row, col, _, _ = vim.treesitter.get_node_range(node)

	local first_char = vim.api.nvim_buf_get_text(buf, row, col, row, col + 1, {})[1]
	if first_char == at_start then
		return false, 0, 0
	end

	return true, row + 1, col + 1
end

M.setup = function(options)
	local default_opts = {
		python = {
			ftype = "*.py",
			at_start = "f",
			interpo = "{",
			node_type = "string",
		},
		cs = {
			ftype = "*.cs",
			at_start = "$",
			interpo = "{",
			node_type = "string_literal",
		},
	}

	M.opts = vim.tbl_deep_extend("force", default_opts, options or {})

	for _, v in pairs(M.opts) do
		local ftype = v.ftype
		local at_start = v.at_start
		local interpo = v.interpo
		local node_type = v.node_type
		local name = ftype:sub(2)

		utils.on_event("InsertCharPre", function(args)
			local need_to_replace, row, col = need_to_replace_at_start(args.buf, interpo, at_start, node_type)

			if need_to_replace then
				vim.api.nvim_input("<Esc>m'" .. row .. "gg" .. col .. "|i" .. at_start .. "<Esc>`'la}<Esc>ba")
			end
		end, { desc = "Auto interpo " .. name })
	end
end

return M