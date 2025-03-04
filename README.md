# nvim-ctx-dump

A Neovim plugin for managing context collections of files that can be easily copied to the clipboard.

## Features

- Add files to a persistent context collection
- View and manage your context files in a floating window
- Remove individual files from the context
- Copy all context files (paths and contents) to the clipboard
- Clear the entire context when needed
- Automatically saves context between Neovim sessions

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
- `<leader>cx` - Clear context

When viewing context files:

- `d` - Remove selected file from context
- `q` - Close context window

### Configuration

You can customize the keybindings when setting up the plugin:

```lua
require('nvim-ctx-dump').setup({
  keymaps = {
    add = "<leader>ca",
    show = "<leader>cs",
    copy = "<leader>cc",
    clear = "<leader>cx",
  }
})
```

## How It Works

The plugin maintains an internal list of file paths that you've added to your context. When you copy the context to clipboard, it formats both the file paths and their contents into a single string, which is then placed in your clipboard.

The context is automatically saved when you exit Neovim and loaded when you restart, providing persistence between sessions.

## License

MIT

