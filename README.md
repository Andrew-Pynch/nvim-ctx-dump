# nvim-ctx-dump

A Neovim plugin for managing context collections of files that can be easily copied to the clipboard.

## Features

- Add files to a persistent context collection
- View and manage your context files in a floating window

![image](https://github.com/user-attachments/assets/c2792ae7-80ba-4a12-b047-79e5d1a9f42c)

- Remove individual files from the context
- Copy all context files (paths and contents) to the clipboard (copies with their full file path, makes it easier for ai's to understand file structure)
 
![image](https://github.com/user-attachments/assets/0be19875-123e-485a-b6cd-404fc139c278)

- Copy only the file paths to the clipboard (without file contents)
- Clear the entire context when needed
- Automatically saves context between Neovim sessions
- Project-scoped contexts (contexts are separate for each working directory)
- Open files directly from the context menu by pressing Enter

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'andrew-pynch/nvim-ctx-dump',
  config = function()
    require('nvim-ctx-dump').setup()
  end
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'andrew-pynch/nvim-ctx-dump',
  config = function()
    require('nvim-ctx-dump').setup()
  end
}
```

## Usage

### Default Keymaps

- `<leader>ca` - Add current file to context
- `<leader>cs` - Show context files
- `<leader>cc` - Copy context to clipboard
- `<leader>cp` - Copy context file paths to clipboard
- `<leader>cx` - Clear context

When viewing context files:

- `d` - Remove selected file from context
- `q` - Close context window
- `<Enter>` - Open selected file

### Configuration

You can customize the keybindings when setting up the plugin:

```lua
require('nvim-ctx-dump').setup({
  keymaps = {
    add = "<leader>ca",
    show = "<leader>cs",
    copy = "<leader>cc",
    copy_paths = "<leader>cp",
    clear = "<leader>cx",
  }
})
```

## How It Works

The plugin maintains a project-scoped collection of file paths that you've added to your context. Each working directory has its own separate context. When you copy the context to clipboard, it formats both the file paths and their contents into a single string, which is then placed in your clipboard.

The contexts are automatically saved when you exit Neovim and loaded when you restart, providing persistence between sessions.

## License

MIT

