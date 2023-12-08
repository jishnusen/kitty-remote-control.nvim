--
-- KITTY RUNNER
--

local config = require("kitty-runner.config")
local fn = vim.fn

local M = {}

local whole_command
local runner_id
local runner_is_open = false

local function send_kitty_command(cmd_args, command)
  local match = { "--to=" .. config["kitty_port"], "--match=id:" .. runner_id }
  local kitten = { "kitty", "@" }
  for _, v in pairs(cmd_args) do
    table.insert(kitten, v)
  end
  for _, v in pairs(match) do
    table.insert(kitten, v)
  end
  table.insert(kitten, command)
  return vim.fn.jobstart(kitten)
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
    vim.fn.jobstart(
      {
        "kitty",
        "@",
        "launch",
        "--title=" .. config["runner_name"],
        "--keep-focus",
        "--cwd=" .. vim.fn.getcwd(),
        "--type=" .. config["type"],
        },
      {
        on_exit = function(_, c, _)
          if c > 0 then
            runner_is_open = false
            print(err)
          else
            runner_is_open = true
            if callback then
              callback()
            end
          end
        end,
        on_stdout = function (_, d)
          runner_id = tonumber(d[1])
        end,
        stdout_buffered = true,
        on_stderr = function (_, d)
          err = table.concat(d)
        end,
        stderr_buffered = true
      })
  end
end

function M.run_region(region)
  whole_command = prepare_command(region)
  -- delete visual selection marks
  vim.cmd([[delm <>]])
  open_and_or_send(whole_command)
end

function M.run_command(line)
  whole_command = line .. "\r"
  open_and_or_send(whole_command)
end

function M.prompt_run_command()
  fn.inputsave()
  local command = fn.input("Command: ")
  fn.inputrestore()
  M.run_command(command)
end

function M.re_run()
  if whole_command then
    open_and_or_send(whole_command)
  end
end

function M.kill_runner()
  if runner_is_open == true then
    send_kitty_command(config["kill_cmd"], nil)
    runner_is_open = false
  end
end

function M.kill_runner_sync()
  if runner_is_open == true then
    local id = send_kitty_command(config["kill_cmd"], nil)
    local wt = vim.fn.jobwait({ id }, 1000)
    if wt < 0 then
      error("failed to sync kill kitty!")
    end
    runner_is_open = false
  end
end

function M.clear_runner()
  if runner_is_open == true then
    send_kitty_command(config["run_cmd"], "\f")
  end
end

return M
