local M = {}

-- Core data structure - folder-scoped contexts
M.contexts = {}

-- Get current working directory key with path normalization
function M.get_cwd_key()
	local cwd = vim.fn.resolve(vim.fn.getcwd())
	return cwd
end

-- Initialize context for current directory if needed
function M.ensure_context_exists()
	local cwd = M.get_cwd_key()
	if not M.contexts[cwd] then
		M.contexts[cwd] = {}
	end
	return M.contexts[cwd]
end

-- Get current context files
function M.get_context_files()
	return M.ensure_context_exists()
end

-- Add current file to context with resolved path
function M.add_to_context()
	local current_file = vim.fn.resolve(vim.fn.expand("%:p"))
	local context_files = M.get_context_files()

	if not vim.tbl_contains(context_files, current_file) then
		table.insert(context_files, current_file)
		vim.notify("Added to context: " .. vim.fn.fnamemodify(current_file, ":~:."), vim.log.levels.INFO)
	else
		vim.notify("File already in context", vim.log.levels.INFO)
	end
end

-- Show context files in a floating window
function M.show_context()
	local context_files = M.get_context_files()

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	-- Disable formatting for this buffer
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "filetype", "nvim-ctx-dump")

	-- Fill buffer with context files
	local lines = {}
	for i, file in ipairs(context_files) do
		table.insert(lines, i .. ". " .. vim.fn.fnamemodify(file, ":~:."))
	end

	if #lines == 0 then
		table.insert(lines, "No files in context")
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set up key mappings for the context buffer
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"d",
		[[<cmd>lua require('nvim-ctx-dump').remove_selected_file()<CR>]],
		{ noremap = true, silent = true, desc = "Remove file from context" }
	)

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"q",
		[[<cmd>lua require('nvim-ctx-dump').close_context_window()<CR>]],
		{ noremap = true, silent = true, desc = "Close context window" }
	)

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<Esc>",
		[[<cmd>lua require('nvim-ctx-dump').close_context_window()<CR>]],
		{ noremap = true, silent = true, desc = "Close context window" }
	)

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<CR>",
		[[<cmd>lua require('nvim-ctx-dump').open_selected_file()<CR>]],
		{ noremap = true, silent = true, desc = "Open selected file" }
	)

	-- Create floating window
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(#lines + 2, vim.o.lines - 4)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = (vim.o.lines - height) / 2,
		col = (vim.o.columns - width) / 2,
		style = "minimal",
		border = "rounded",
	})

	-- Set window title and options
	vim.api.nvim_buf_set_name(buf, "Context Files")
	vim.api.nvim_win_set_option(win, "winblend", 10)

	-- Store buffer and window id for later use
	M.context_buf = buf
	M.context_win = win
end

-- Remove selected file from context
function M.remove_selected_file()
	local line_num = vim.fn.line(".")
	local line_content = vim.api.nvim_get_current_line()
	local index = tonumber(line_content:match("^(%d+)%."))
	local context_files = M.get_context_files()

	if index and context_files[index] then
		local removed_file = vim.fn.fnamemodify(context_files[index], ":~:.")
		table.remove(context_files, index)

		-- Update the existing buffer with the new list of files
		local new_lines = {}
		for i, file in ipairs(context_files) do
			table.insert(new_lines, i .. ". " .. vim.fn.fnamemodify(file, ":~:."))
		end
		if #new_lines == 0 then
			table.insert(new_lines, "No files in context")
		end
		vim.api.nvim_buf_set_lines(M.context_buf, 0, -1, false, new_lines)
		vim.notify("Removed file from context: " .. removed_file, vim.log.levels.INFO)
	end
end

-- Open selected file
function M.open_selected_file()
	local line_num = vim.fn.line(".")
	local line_content = vim.api.nvim_get_current_line()
	local index = tonumber(line_content:match("^(%d+)%."))
	local context_files = M.get_context_files()

	if index and context_files[index] then
		local file_path = context_files[index]
		M.close_context_window()
		vim.cmd("edit " .. vim.fn.fnameescape(file_path))
	end
end

-- Close context window
function M.close_context_window()
	if M.context_win and vim.api.nvim_win_is_valid(M.context_win) then
		vim.api.nvim_win_close(M.context_win, true)
		M.context_win = nil
	end
	if M.context_buf and vim.api.nvim_buf_is_valid(M.context_buf) then
		vim.api.nvim_buf_delete(M.context_buf, { force = true })
		M.context_buf = nil
	end
end

-- Copy all context files and their contents to clipboard
function M.copy_to_clipboard()
	local context_files = M.get_context_files()
	if #context_files == 0 then
		vim.notify("No files in context to copy", vim.log.levels.WARN)
		return
	end

	local content = ""
	for i, file in ipairs(context_files) do
		local rel_path = vim.fn.fnamemodify(file, ":~:.")
		content = content .. "### " .. rel_path .. "\n\n"

		local ext = vim.fn.fnamemodify(file, ":e")
		local lang = ext ~= "" and ext or ""

		local file_content = {}
		local success, err = pcall(function()
			file_content = vim.fn.readfile(file)
		end)

		if not success then
			content = content .. "Error reading file: " .. (err or "Unknown error") .. "\n\n"
		else
			content = content .. "```" .. lang .. "\n" .. table.concat(file_content, "\n") .. "\n```\n\n"
		end
	end

	vim.fn.setreg("+", content)
	vim.notify("Copied " .. #context_files .. " files to clipboard", vim.log.levels.INFO)
end

-- Copy only the file paths to clipboard
function M.copy_paths_to_clipboard()
	local context_files = M.get_context_files()
	if #context_files == 0 then
		vim.notify("No files in context to copy", vim.log.levels.WARN)
		return
	end

	local content = ""
	for i, file in ipairs(context_files) do
		local rel_path = vim.fn.fnamemodify(file, ":~:.")
		content = content .. rel_path .. "\n"
	end

	vim.fn.setreg("+", content)
	vim.notify("Copied " .. #context_files .. " file paths to clipboard", vim.log.levels.INFO)
end

-- Clear all files from context
function M.clear_context()
	local cwd = M.get_cwd_key()
	M.contexts[cwd] = {}
	vim.notify("Context cleared", vim.log.levels.INFO)
end

-- Save context to a file
function M.save_context()
	local save_path = vim.fn.stdpath("data") .. "/nvim-ctx-dump.json"
	local file = io.open(save_path, "w")
	if file then
		file:write(vim.fn.json_encode(M.contexts))
		file:close()
		vim.notify("Contexts saved to " .. save_path, vim.log.levels.INFO)
		vim.notify("Saved contexts: " .. vim.inspect(M.contexts), vim.log.levels.DEBUG)
	else
		vim.notify("Failed to save contexts to " .. save_path, vim.log.levels.ERROR)
	end
end

-- Load context from a file
function M.load_context()
	local save_path = vim.fn.stdpath("data") .. "/nvim-ctx-dump.json"
	local file = io.open(save_path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		if content and #content > 0 then
			local ok, decoded = pcall(vim.fn.json_decode, content)
			if ok and type(decoded) == "table" then
				M.contexts = decoded
				-- vim.notify("Contexts loaded from " .. save_path, vim.log.levels.INFO)
				-- vim.notify("Loaded contexts: " .. vim.inspect(M.contexts), vim.log.levels.DEBUG)
			else
				vim.notify("Failed to decode context file: " .. tostring(decoded), vim.log.levels.ERROR)
				M.contexts = {} -- Reset to empty on failure
			end
		else
			vim.notify("Empty context file found at " .. save_path, vim.log.levels.INFO)
			M.contexts = {}
		end
	else
		vim.notify("No saved contexts found at " .. save_path, vim.log.levels.INFO)
		M.contexts = {}
	end
end

-- Customize the appearance of context window
function M.create_highlight_groups()
	vim.api.nvim_create_augroup("NvimCtxDumpHighlight", { clear = true })
	vim.api.nvim_create_autocmd({ "FileType" }, {
		group = "NvimCtxDumpHighlight",
		pattern = "nvim-ctx-dump",
		callback = function()
			vim.api.nvim_set_hl(0, "CtxDumpHeader", { link = "Title", default = true })
			vim.api.nvim_set_hl(0, "CtxDumpIndex", { link = "Number", default = true })
			vim.api.nvim_set_hl(0, "CtxDumpPath", { link = "Directory", default = true })
			vim.opt_local.cursorline = true
			vim.opt_local.number = false
			vim.opt_local.signcolumn = "no"
			vim.b.conform_disable = 1
			vim.b.formatting_disabled = true
			vim.b.disable_autoformat = true
		end,
	})
end

-- Setup the plugin
function M.setup(opts)
	opts = opts or {}

	-- Load previous context if it exists
	M.load_context()

	-- Create highlight groups
	M.create_highlight_groups()

	-- Create default keymaps
	local keymaps = {
		add = "<leader>ca",
		show = "<leader>cs",
		copy = "<leader>cc",
		copy_paths = "<leader>cp",
		clear = "<leader>cx",
	}

	-- Override with user keymaps if provided
	if opts.keymaps then
		for k, v in pairs(opts.keymaps) do
			keymaps[k] = v
		end
	end

	-- Set up key mappings
	vim.keymap.set(
		"n",
		keymaps.add,
		M.add_to_context,
		{ noremap = true, silent = true, desc = "Add current file to context" }
	)

	vim.keymap.set("n", keymaps.show, M.show_context, { noremap = true, silent = true, desc = "Show context files" })

	vim.keymap.set(
		"n",
		keymaps.copy,
		M.copy_to_clipboard,
		{ noremap = true, silent = true, desc = "Copy context to clipboard" }
	)
	
	vim.keymap.set(
		"n",
		keymaps.copy_paths,
		M.copy_paths_to_clipboard,
		{ noremap = true, silent = true, desc = "Copy context file paths to clipboard" }
	)

	vim.keymap.set("n", keymaps.clear, M.clear_context, { noremap = true, silent = true, desc = "Clear context" })

	-- Save context when Neovim exits
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			M.save_context()
		end,
	})
end

return M
