local M = {}

-- Core data structure
M.context_files = {}

-- Add current file to context
function M.add_to_context()
  local current_file = vim.fn.expand('%:p')
  if not vim.tbl_contains(M.context_files, current_file) then
    table.insert(M.context_files, current_file)
    vim.notify("Added to context: " .. vim.fn.fnamemodify(current_file, ':~:.'))
  else
    vim.notify("File already in context")
  end
end

-- Show context files in a floating window
function M.show_context()
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Disable formatting for this buffer
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'nvim-ctx-dump')
  
  -- Fill buffer with context files
  local lines = {}
  for i, file in ipairs(M.context_files) do
    table.insert(lines, i .. ". " .. vim.fn.fnamemodify(file, ':~:.'))
  end
  
  if #lines == 0 then
    table.insert(lines, "No files in context")
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set up key mappings for the context buffer
  vim.api.nvim_buf_set_keymap(buf, 'n', 'd', 
    [[<cmd>lua require('nvim-ctx-dump').remove_selected_file()<CR>]], 
    {noremap = true, silent = true, desc = "Remove file from context"})
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', 
    [[<cmd>lua require('nvim-ctx-dump').close_context_window()<CR>]], 
    {noremap = true, silent = true, desc = "Close context window"})
    
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', 
    [[<cmd>lua require('nvim-ctx-dump').close_context_window()<CR>]], 
    {noremap = true, silent = true, desc = "Close context window"})
  
  -- Create floating window
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Set window title and options
  vim.api.nvim_buf_set_name(buf, "Context Files")
  vim.api.nvim_win_set_option(win, 'winblend', 10)
  
  -- Store buffer and window id for later use
  M.context_buf = buf
  M.context_win = win
end

-- Remove selected file from context
function M.remove_selected_file()
  local line_num = vim.fn.line('.')
  local line_content = vim.api.nvim_get_current_line()
  
  -- Extract the index from the line
  local index = tonumber(line_content:match("^(%d+)%."))
  
  if index and M.context_files[index] then
    local removed_file = vim.fn.fnamemodify(M.context_files[index], ':~:.')
    table.remove(M.context_files, index)
    M.show_context() -- Refresh window
    vim.notify("Removed file from context: " .. removed_file)
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
  if #M.context_files == 0 then
    vim.notify("No files in context to copy")
    return
  end
  
  local content = ""
  for i, file in ipairs(M.context_files) do
    -- Add file path with relative format
    local rel_path = vim.fn.fnamemodify(file, ':~:.')
    content = content .. "### " .. rel_path .. "\n\n"
    
    -- Try to determine file type for syntax highlighting in markdown
    local ext = vim.fn.fnamemodify(file, ':e')
    local lang = ''
    if ext and ext ~= '' then
      lang = ext
    end
    
    -- Add file content with language annotation for markdown
    local file_content = {}
    local success, err = pcall(function()
      file_content = vim.fn.readfile(file)
    end)
    
    if not success or (err and #err > 0) then
      content = content .. "Error reading file: " .. (err or "Unknown error") .. "\n\n"
    else
      content = content .. "```" .. lang .. "\n" .. table.concat(file_content, '\n') .. "\n```\n\n"
    end
  end
  
  vim.fn.setreg('+', content)
  vim.notify("Copied " .. #M.context_files .. " files to clipboard")
end

-- Clear all files from context
function M.clear_context()
  M.context_files = {}
  vim.notify("Context cleared")
end

-- Save context to a file
function M.save_context()
  local save_path = vim.fn.stdpath('data') .. '/nvim-ctx-dump.json'
  local file = io.open(save_path, 'w')
  if file then
    file:write(vim.fn.json_encode(M.context_files))
    file:close()
    vim.notify("Context saved to " .. save_path)
  else
    vim.notify("Failed to save context", vim.log.levels.ERROR)
  end
end

-- Load context from a file
function M.load_context()
  local save_path = vim.fn.stdpath('data') .. '/nvim-ctx-dump.json'
  local file = io.open(save_path, 'r')
  if file then
    local content = file:read('*a')
    file:close()
    if content and #content > 0 then
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and type(decoded) == 'table' then
        M.context_files = decoded
        vim.notify("Context loaded from " .. save_path)
      else
        vim.notify("Failed to decode context file", vim.log.levels.ERROR)
      end
    end
  else
    vim.notify("No saved context found", vim.log.levels.INFO)
  end
end

-- Customize the appearance of context window
function M.create_highlight_groups()
  -- Create highlight groups for the context buffer
  vim.api.nvim_create_augroup("NvimCtxDumpHighlight", { clear = true })
  
  -- Create filetype detection for nvim-ctx-dump
  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = "NvimCtxDumpHighlight",
    pattern = "nvim-ctx-dump",
    callback = function()
      -- Custom highlighting for context buffer
      vim.api.nvim_set_hl(0, "CtxDumpHeader", { link = "Title", default = true })
      vim.api.nvim_set_hl(0, "CtxDumpIndex", { link = "Number", default = true })
      vim.api.nvim_set_hl(0, "CtxDumpPath", { link = "Directory", default = true })
      
      -- Add other UI customizations here
      vim.opt_local.cursorline = true
      vim.opt_local.number = false
      vim.opt_local.signcolumn = "no"
      
      -- Prevent formatters from running on this buffer
      vim.b.conform_disable = 1
      vim.b.formatting_disabled = true
      vim.b.disable_autoformat = true
    end
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
    clear = "<leader>cx",
  }
  
  -- Override with user keymaps if provided
  if opts.keymaps then
    for k, v in pairs(opts.keymaps) do
      keymaps[k] = v
    end
  end
  
  -- Set up key mappings
  vim.keymap.set('n', keymaps.add, M.add_to_context, 
    {noremap = true, silent = true, desc = "Add current file to context"})
  
  vim.keymap.set('n', keymaps.show, M.show_context, 
    {noremap = true, silent = true, desc = "Show context files"})
  
  vim.keymap.set('n', keymaps.copy, M.copy_to_clipboard, 
    {noremap = true, silent = true, desc = "Copy context to clipboard"})
  
  vim.keymap.set('n', keymaps.clear, M.clear_context, 
    {noremap = true, silent = true, desc = "Clear context"})
  
  -- Save context when Neovim exits
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.save_context()
    end,
  })
end

return M