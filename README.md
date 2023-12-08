# kitty-runner.nvim

My fork. Uses `kitty @ launch` for everything, and codes windows by kitty ID instead of generated UUID

Requires:
```
allow_remote_control socket-only
listen_on unix:/path/to/socket
```
in `kitty.conf`

# Functionality

The plugin implements the following commands:
- `:KittyOpenRunner`: Open a new kitty terminal (called a runner in the context of this plugin)
- `:KittySendLines`: Send the line at the current cursor position or the lines of current visual selection
- `:KittyRunCommand`: Prompt for a command and send it
- `:KittyReRunCommand`: Send the last command
- `:KittyClearRunner`: Clear the runner's screen
- `:KittyKillRunner`: Kill the runner

By default a number of keymaps are created (see below to turn this off):
- `<leader>to`: `:KittyOpenRunner`
- `<leader>tr`: `:KittyRunCommand`
- `<leader>ts`: `:KittySendLines`
- `<leader>tc`: `:KittyClearRunner`
- `<leader>tk`: `:KittyKillRunner`
- `<leader>tl`: `:KittyReRunCommand`

## Installation

Recommended setup (with Lazy):

```lua
return {
  'jishnusen/kitty-runner.nvim',
  config = function()
    require("kitty-runner").setup({
      type = "window"
    })
    vim.keymap.set("n", "<leader>ti",
      function()
        require("kitty-runner.kitty-runner").run_command("ipython")
      end
    )
    vim.api.nvim_create_autocmd({ "ExitPre" }, {
      pattern = { "*" },
      command = [[KittyKillRunner]],
    })
  end
}
```

## Configuration

The setup function allows adjusting various settings. By default it sets the following:
```lua
{
  runner_name = "kitty-runner",
  -- can pass flags as additional items in the list
  run_cmd = { "send-text" },
  kill_cmd = { "close-window" },
  use_keymaps = true,
  -- can specify your own socket here, we read from env by default
  kitty_port = os.getenv("KITTY_LISTEN_ON"),
  -- any window type supported by kitty, includes tab, os-window, etc.
  mode = "window"
}
```
