# qfctl

Neovim plugin for quickfix control: add, edit, remove, sort, save and load.

Does not modify the built-in quickfix in any way so plays nice with other
plugins. Personally use it in combination with
[nvim-bqf](https://github.com/kevinhwang91/nvim-bqf).

## Usage

```lua
vim.pack.add({ -- or other plugin manager
  "https://github.com/marcelbeumer/qfctl.nvim",
})

require('qfctl').setup() -- use default config
-- OR
require('qfctl').setup({ -- override defaults
  data_dir = vim.fn.stdpath("data") .. "/qfctl-lists",
  mappings = { -- leave any part nil to disable
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
  commands = true, -- add commands during setup
  notify = {
    enabled = true,
    level = vim.log.levels.INFO,
  },
})
```

- `:QFCtlAdd`: Add current line to quickfix.
- `:QFCtlAddPrompt`: Add entry to quickfix with prompt.
- `:QFCtlEdit`: Edit current quickfix entry.
- `:QFCtlRemove`: Remove current quickfix entry.
- `:QFCtlUp`: Move entry up.
- `:QFCtlDown`: Move entry down.
- `:QFCtlMoveTo`: Move entry to position.
- `:QFCtlSave`: Save quickfix list.
- `:QFCtlLoad`: Load quickfix list.
- `:QFCtlLoadAppend`: Append quickfix list.
- `:QFCtlSort`: Sort quickfix list. Optionally pass "desc" or "descending",
  defaults to ascending.

Also see the [helpfile](./doc/qfctl.txt).
