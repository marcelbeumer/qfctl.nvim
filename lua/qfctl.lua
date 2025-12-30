-- qfctl.nvim
-- Quickfix control: add, edit, remove, sort, save and load.
-- Initially written by AI then brushed up myself, did not have time yet to
-- properly do it myself from scratch.

local M = {}

local default_config = {
  data_dir = vim.fn.stdpath("data") .. "/qfctl-lists",

  mappings = {
    global = {
      add_current_line = "<leader>qa",
      add_prompt = "<leader>qA",
    },
    qf = {
      add_prompt = "<leader>qA",
      edit = "<leader>qe",
      remove = "<C-d>",
      move_up = "<C-k>",
      move_down = "<C-j>",
      move_to = "<leader>qm",
      save = "<leader>qs",
      load = "<leader>ql",
      load_append = "<leader>qL",
      sort_asc = "<leader>q<",
      sort_desc = "<leader>q>",
    },
  },
  commands = true,
  notify = {
    enabled = true,
    level = vim.log.levels.INFO,
  },
}

local config = {}

local function notify(msg, level)
  if config.notify.enabled then
    vim.notify(msg, level or config.notify.level)
  end
end

local function ensure_data_dir()
  vim.fn.mkdir(config.data_dir, "p")
end

-- Add current line to quickfix.
function M.add(opts)
  opts = opts or {}
  local file = opts.filename or vim.fn.expand("%:p")
  local line = opts.lnum or vim.fn.line(".")
  local col = opts.col or vim.fn.col(".")
  local text = opts.text or vim.fn.getline(".")

  if file == "" then
    notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  vim.fn.setqflist({ {
    filename = file,
    lnum = line,
    col = col,
    text = text,
  } }, "a")

  notify("Added to quickfix")
end

-- Add entry with prompts for missing fields.
function M.add_prompt(opts)
  opts = opts or {}
  local file = opts.filename or vim.fn.expand("%:p")
  local line = opts.lnum or vim.fn.line(".")
  local col = opts.col or vim.fn.col(".")

  local function prompt_file(callback)
    if opts.filename then
      callback(opts.filename)
    else
      vim.ui.input({
        prompt = "File: ",
        default = file,
        completion = "file",
      }, callback)
    end
  end

  local function prompt_line(callback)
    if opts.lnum then
      callback(tostring(opts.lnum))
    else
      vim.ui.input({ prompt = "Line: ", default = tostring(line) }, callback)
    end
  end

  local function prompt_col(callback)
    if opts.col then
      callback(tostring(opts.col))
    else
      vim.ui.input({ prompt = "Column: ", default = tostring(col) }, callback)
    end
  end

  local function prompt_text(callback)
    if opts.text then
      callback(opts.text)
    else
      vim.ui.input({ prompt = "Text: " }, callback)
    end
  end

  prompt_file(function(file)
    if not file or file == "" then
      return
    end

    prompt_line(function(line)
      if not line or line == "" then
        return
      end

      prompt_col(function(col)
        if not col or col == "" then
          return
        end

        prompt_text(function(text)
          if not text then
            return
          end

          vim.fn.setqflist({
            {
              filename = file,
              lnum = tonumber(line) or 1,
              col = tonumber(col) or 1,
              text = text,
            },
          }, "a")

          notify("Added to quickfix")
        end)
      end)
    end)
  end)
end

-- Edit current quickfix entry.
function M.edit(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()
  local idx = opts.index or vim.fn.line(".")

  if idx < 1 or idx > #qf then
    notify("Invalid quickfix entry", vim.log.levels.WARN)
    return
  end

  local entry = qf[idx]
  local current_file = vim.fn.bufname(entry.bufnr)
  local current_line = tostring(entry.lnum or 1)
  local current_col = tostring(entry.col or 1)
  local current_text = entry.text or ""

  vim.ui.input({
    prompt = "File: ",
    default = current_file,
    completion = "file",
  }, function(file)
    if not file then
      return
    end

    vim.ui.input({ prompt = "Line: ", default = current_line }, function(line)
      if not line then
        return
      end

      vim.ui.input({ prompt = "Column: ", default = current_col }, function(col)
        if not col then
          return
        end

        vim.ui.input({ prompt = "Text: ", default = current_text }, function(text)
          if not text then
            return
          end

          entry.filename = file
          entry.bufnr = 0 -- will be resolved by setqflist
          entry.lnum = tonumber(line) or 1
          entry.col = tonumber(col) or 1
          entry.text = text

          qf[idx] = entry
          vim.fn.setqflist(qf, "r")
          vim.fn.cursor(idx, 1)
          notify("Entry updated")
        end)
      end)
    end)
  end)
end

-- Remove entry.
function M.remove(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()
  local idx = opts.index or vim.fn.line(".")

  if idx < 1 or idx > #qf then
    notify("Invalid quickfix entry", vim.log.levels.WARN)
    return
  end

  table.remove(qf, idx)
  vim.fn.setqflist(qf, "r")

  -- Keep cursor position.
  if idx <= #qf then
    vim.fn.cursor(idx, 1)
  elseif #qf > 0 then
    vim.fn.cursor(#qf, 1)
  end

  notify("Entry removed")
end

-- Move entry up.
function M.move_up(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()
  local idx = opts.index or vim.fn.line(".")

  if idx <= 1 then
    notify("Already at top", vim.log.levels.WARN)
    return
  end

  qf[idx], qf[idx - 1] = qf[idx - 1], qf[idx]
  vim.fn.setqflist(qf, "r")

  if idx - 1 >= 0 then
    vim.fn.cursor(idx - 1, 1)
  else
    vim.fn.cursor(0, 1)
  end
end

-- Move entry down.
function M.move_down(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()
  local idx = opts.index or vim.fn.line(".")

  if idx >= #qf then
    notify("Already at bottom", vim.log.levels.WARN)
    return
  end

  qf[idx], qf[idx + 1] = qf[idx + 1], qf[idx]
  vim.fn.setqflist(qf, "r")

  if idx + 1 <= #qf then
    vim.fn.cursor(idx + 1, 1)
  else
    vim.fn.cursor(#qf, 1)
  end
end

-- Move entry to position.
function M.move_to(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()
  local idx = opts.from or vim.fn.line(".")

  if idx < 1 or idx > #qf then
    notify("Invalid quickfix entry", vim.log.levels.WARN)
    return
  end

  local function do_move(target)
    if not target or target < 1 or target > #qf then
      notify("Invalid position", vim.log.levels.WARN)
      return
    end

    local entry = table.remove(qf, idx)
    table.insert(qf, target, entry)
    vim.fn.setqflist(qf, "r")
    notify("Entry moved to position " .. target)
  end

  if opts.to then
    do_move(opts.to)
  else
    vim.ui.input({
      prompt = "Move to position: ",
      default = tostring(idx),
    }, function(pos)
      if pos then
        do_move(tonumber(pos))
      end
    end)
  end
end

-- Save quickfix list to file.
function M.save(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()

  if #qf == 0 then
    notify("Quickfix list is empty", vim.log.levels.WARN)
    return
  end

  ensure_data_dir()

  local function do_save(filename)
    if not filename or filename == "" then
      return
    end

    local filepath = config.data_dir .. "/" .. filename

    -- Convert to serializable format
    local data = {}
    for _, item in ipairs(qf) do
      table.insert(data, {
        filename = vim.fn.bufname(item.bufnr),
        lnum = item.lnum,
        col = item.col,
        text = item.text,
        type = item.type,
      })
    end

    local json = vim.json.encode(data)
    local file = io.open(filepath, "w")
    if file then
      file:write(json)
      file:close()
      notify("Saved to " .. filepath)
    else
      notify("Failed to save file", vim.log.levels.ERROR)
    end
  end

  if opts.filename then
    do_save(opts.filename)
  else
    vim.ui.input({
      prompt = "Save as: ",
      default = "qflist.json",
    }, do_save)
  end
end

-- Load quickfix list from file.
function M.load(opts)
  opts = opts or {}
  ensure_data_dir()
  local files = vim.fn.globpath(config.data_dir, "*.json", false, true)

  if #files == 0 then
    notify("No saved quickfix lists found", vim.log.levels.WARN)
    return
  end

  local filenames = {}
  for _, filepath in ipairs(files) do
    table.insert(filenames, vim.fn.fnamemodify(filepath, ":t"))
  end

  local function do_load(filename)
    if not filename then
      return
    end

    local filepath = config.data_dir .. "/" .. filename
    local file = io.open(filepath, "r")

    if not file then
      notify("Failed to open file", vim.log.levels.ERROR)
      return
    end

    local content = file:read("*a")
    file:close()

    local ok, data = pcall(vim.json.decode, content)
    if not ok or not data then
      notify("Failed to parse file", vim.log.levels.ERROR)
      return
    end

    local action = opts.append and "a" or "r"
    vim.fn.setqflist(data, action)

    if not opts.append then
      vim.cmd("copen")
    end

    local verb = opts.append and "Appended" or "Loaded"
    notify(verb .. " " .. filename)
  end

  if opts.filename then
    do_load(opts.filename)
  else
    local prompt = opts.append and "Append quickfix list:" or "Load quickfix list:"
    vim.ui.select(filenames, { prompt = prompt }, do_load)
  end
end

-- Sort quickfix list.
function M.sort(opts)
  opts = opts or {}

  local qf = vim.fn.getqflist()

  if #qf == 0 then
    notify("Quickfix list is empty", vim.log.levels.WARN)
    return
  end

  local descending = opts.descending or false

  table.sort(qf, function(a, b)
    local file_a = vim.fn.bufname(a.bufnr)
    local file_b = vim.fn.bufname(b.bufnr)

    if file_a ~= file_b then
      return descending and (file_a > file_b) or (file_a < file_b)
    end
    return descending and (a.lnum > b.lnum) or (a.lnum < b.lnum)
  end)

  vim.fn.setqflist(qf, "r")
  vim.fn.cursor(1, 1)

  local direction = descending and "descending" or "ascending"
  notify("Sorted " .. direction)
end

-- Setup keymaps.
local function setup_keymaps()
  local map = vim.keymap.set
  local global_maps = config.mappings.global
  local qf_maps = config.mappings.qf

  if global_maps.add_current_line and global_maps.add_current_line ~= "" then
    map("n", global_maps.add_current_line, function()
      M.add()
    end, { silent = true, desc = "QFCtl: Add current line" })
  end

  if global_maps.add_prompt and global_maps.add_prompt ~= "" then
    map("n", global_maps.add_prompt, function()
      M.add_prompt()
    end, { silent = true, desc = "QFCtl: Add with prompt" })
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function(ev)
      local buf_opts = { buffer = ev.buf, silent = true }

      if qf_maps.add_prompt and qf_maps.add_prompt ~= "" then
        map("n", qf_maps.add_prompt, M.add_prompt, buf_opts)
      end

      if qf_maps.edit and qf_maps.edit ~= "" then
        map("n", qf_maps.edit, M.edit, buf_opts)
      end

      if qf_maps.remove and qf_maps.remove ~= "" then
        map("n", qf_maps.remove, M.remove, buf_opts)
      end

      if qf_maps.move_up and qf_maps.move_up ~= "" then
        map("n", qf_maps.move_up, M.move_up, buf_opts)
      end

      if qf_maps.move_down and qf_maps.move_down ~= "" then
        map("n", qf_maps.move_down, M.move_down, buf_opts)
      end

      if qf_maps.move_to and qf_maps.move_to ~= "" then
        map("n", qf_maps.move_to, M.move_to, buf_opts)
      end

      if qf_maps.save and qf_maps.save ~= "" then
        map("n", qf_maps.save, M.save, buf_opts)
      end

      if qf_maps.load and qf_maps.load ~= "" then
        map("n", qf_maps.load, M.load, buf_opts)
      end

      if qf_maps.load_append and qf_maps.load_append ~= "" then
        map("n", qf_maps.load_append, function()
          M.load({ append = true })
        end, buf_opts)
      end

      if qf_maps.sort_asc and qf_maps.sort_asc ~= "" then
        map("n", qf_maps.sort_asc, M.sort, buf_opts)
      end

      if qf_maps.sort_desc and qf_maps.sort_desc ~= "" then
        map("n", qf_maps.sort_desc, function()
          M.sort({ descending = true })
        end, buf_opts)
      end
    end,
  })
end

local function setup_commands()
  if not config.commands then
    return
  end

  vim.api.nvim_create_user_command("QFCtlAdd", function(cmd)
    M.add()
  end, { desc = "Add current line to quickfix" })

  vim.api.nvim_create_user_command("QFCtlAddPrompt", function(cmd)
    M.add_prompt()
  end, { desc = "Add entry to quickfix with prompt" })

  vim.api.nvim_create_user_command("QFCtlEdit", function(cmd)
    M.edit()
  end, { desc = "Edit current quickfix entry" })

  vim.api.nvim_create_user_command("QFCtlRemove", function(cmd)
    M.remove()
  end, { desc = "Remove current quickfix entry" })

  vim.api.nvim_create_user_command("QFCtlUp", function(cmd)
    M.move_up()
  end, { desc = "Move entry up" })

  vim.api.nvim_create_user_command("QFCtlDown", function(cmd)
    M.move_down()
  end, { desc = "Move entry down" })

  vim.api.nvim_create_user_command("QFCtlMoveTo", function(cmd)
    local to = cmd.args ~= "" and tonumber(cmd.args) or nil
    M.move_to({ to = to })
  end, { nargs = "?", desc = "Move entry to position" })

  vim.api.nvim_create_user_command("QFCtlSave", function(cmd)
    local filename = cmd.args ~= "" and cmd.args or nil
    M.save({ filename = filename })
  end, { nargs = "?", desc = "Save quickfix list" })

  vim.api.nvim_create_user_command("QFCtlLoad", function(cmd)
    local filename = cmd.args ~= "" and cmd.args or nil
    M.load({ filename = filename })
  end, { nargs = "?", desc = "Load quickfix list" })

  vim.api.nvim_create_user_command("QFCtlLoadAppend", function(cmd)
    local filename = cmd.args ~= "" and cmd.args or nil
    M.load({ filename = filename, append = true })
  end, { nargs = "?", desc = "Append quickfix list" })

  vim.api.nvim_create_user_command("QFCtlSort", function(cmd)
    local desc = cmd.args == "desc" or cmd.args == "descending"
    M.sort({ descending = desc })
  end, {
    nargs = "?",
    complete = function()
      return { "asc", "desc" }
    end,
    desc = "Sort quickfix list",
  })
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
  setup_keymaps()
  setup_commands()
end

return M
