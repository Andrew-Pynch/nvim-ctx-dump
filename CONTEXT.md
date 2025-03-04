# nvim-ctx-dump: Context Management System

## Purpose

`nvim-ctx-dump` is a Neovim plugin designed to solve a common problem for developers: collecting and sharing context from multiple files. It addresses these key needs:

1. **Context Collection**: Easily gather files that are relevant to a particular task, bug, or feature
2. **Efficient Sharing**: Copy both file paths and contents to the clipboard in a nicely formatted way for sharing with others
3. **Persistent Storage**: Save your context between Neovim sessions
4. **Simple Interface**: Manage your context through an intuitive floating window UI

## Use Cases

- **Code Review**: Collect relevant files to share context with reviewers
- **Knowledge Sharing**: Gather related code examples to share with team members
- **Debugging**: Build a collection of files involved in a bug
- **Feature Development**: Keep track of all files being modified for a feature
- **Documentation**: Collect code examples needed for documentation
- **Pair Programming**: Share context with your programming partner
- **LLM Prompts**: Prepare context to send to an AI assistant for code analysis

## Technical Implementation

The plugin is implemented in Lua and uses:

1. **Core Neovim API**:
   - Buffer and window management for the UI
   - File reading with error handling
   - Clipboard integration

2. **Data Persistence**:
   - Saves context as JSON to `stdpath('data')/nvim-ctx-dump.json`
   - Automatically loads saved context on startup

3. **User Interface**:
   - Floating window with custom filetype and highlighting
   - Simple keybindings for navigation and actions
   - Formatter-aware implementation to avoid conflicts with tools like conform.nvim

## Future Enhancements

Possible future improvements:

- Multiple named contexts for different tasks
- Visual selection to add specific code snippets
- Integration with telescope.nvim for file selection
- Configurable output formats
- Preview of files in the context browser
- Support for adding code comments to context items