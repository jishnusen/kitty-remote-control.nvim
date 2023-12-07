--
-- KITTY RUNNER
--

local config = require("kitty-runner.config")
local fn = vim.fn
local loop = vim.loop

local M = {}

local whole_command
local runner_is_open = false

local function send_kitty_command(cmd_args, command)
  local args = { "@", "--to=" .. config["kitty_port"] }
  for _, v in pairs(cmd_args) do
    table.insert(args, v)
  end
  table.insert(args, command)
  loop.spawn("kitty", {
    args = args,
  })
end

local function open_and_or_send(command)
  if runner_is_open == true then
    send_kitty_command(config["run_cmd"], command)
  else
    M.open_runner(function()
      send_kitty_command(config["run_cmd"], command)
    end)
  end
end

local function prepare_command(region)
  local lines
  if region[1] == 0 then
    lines = vim.api.nvim_buf_get_lines(
      0,
      vim.api.nvim_win_get_cursor(0)[1] - 1,
      vim.api.nvim_win_get_cursor(0)[1],
      true
    )
  else
    lines = vim.api.nvim_buf_get_lines(0, region[1] - 1, region[2], true)
  end
  local command = table.concat(lines, "\r")
  return "\\e[200~" .. command .. "\\e[201~" .. "\r"
end

function M.open_runner(callback)
  if runner_is_open == false then
    local on_exit = loop.spawn(
      "kitty",
      {
        args = {
          "@",
          "launch",
          "--title=" .. config["runner_name"],
          "--keep-focus",
          "--cwd=" .. vim.fn.getcwd()
        }
      },
      function(code, _)
        if code then
          runner_is_open = false
          error("Failed: check if allow_remote_control is enabled")
        else
          runner_is_open = true
          if callback then callback() end
        end
      end
    )

    vim.fn.printf(vim.inspect(on_exit))
  end
end

function M.run_command(region)
  whole_command = prepare_command(region)
  -- delete visual selection marks
  vim.cmd([[delm <>]])
  open_and_or_send(whole_command)
end

function M.re_run_command()
  if whole_command then
    open_and_or_send(whole_command)
  end
end

function M.prompt_run_command()
  fn.inputsave()
  local command = fn.input("Command: ")
  fn.inputrestore()
  whole_command = command .. "\r"
  open_and_or_send(whole_command)
end

function M.kill_runner()
  if runner_is_open == true then
    send_kitty_command(config["kill_cmd"], nil)
    runner_is_open = false
  end
end

function M.clear_runner()
  if runner_is_open == true then
    send_kitty_command(config["run_cmd"], "")
  end
end

return M
