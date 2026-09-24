-- Neovim config, one file on purpose: read it top to bottom.
--
-- Space is the leader key. Press it and wait: which-key pops up the available
-- shortcuts. Plugins install on first start; :Lazy manages plugins, :Mason
-- manages language servers and formatters, :checkhealth diagnoses problems.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Home-row movement shifted one key right: j left, k down, l up, ; right, and
-- h takes over ;'s old job (repeat the last f/t). langmap translates keys before
-- Neovim reads them as commands, so counts (3k), operators (dk), text objects,
-- windows (<C-w>;) and plugin keys all follow; text you type (insert mode, the
-- character after f/t/r) is untouched. Keep h/j/k/l/; out of custom shortcuts:
-- keys inside a shortcut get translated too, which makes them confusing.
vim.o.langmap = [[jh,kj,lk,\;l,h\;]]

-- nvim-tree replaces the built-in file browser (netrw)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

local opt = vim.opt
opt.number = true -- line numbers
opt.mouse = "a" -- mouse works everywhere
opt.clipboard = "unnamedplus" -- yank/paste use the macOS clipboard
opt.ignorecase = true -- search ignores case...
opt.smartcase = true -- ...unless it has a capital letter
opt.inccommand = "split" -- preview :s/find/replace/ as you type
opt.undofile = true -- undo history survives closing the file
opt.confirm = true -- ask to save instead of refusing to quit
opt.signcolumn = "yes" -- keep the gutter so text doesn't shift
opt.cursorline = true
opt.scrolloff = 8 -- keep 8 lines visible above/below the cursor
opt.splitright = true
opt.splitbelow = true
opt.showmode = false -- the status line shows the mode
opt.updatetime = 250 -- faster diagnostics and git signs
opt.list = true -- show tabs and trailing spaces
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.expandtab = true -- spaces, 2 wide (Go overrides this below)
opt.shiftwidth = 2
opt.tabstop = 2
opt.breakindent = true

-- Go uses tabs (gofmt); show them 4 wide
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Neovim's built-in vim.notify shows every level, so plugins' debug chatter
-- (e.g. tobira listing remapped keys at startup) pops up. Drop debug/trace.
local notify = vim.notify
vim.notify = function(msg, level, opts)
  if level and level < vim.log.levels.INFO then return end
  return notify(msg, level, opts)
end

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank() end,
})

--------------------------------------------------------------------------------
-- Keymaps (plugin keymaps are with their plugins below)
--------------------------------------------------------------------------------

local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map({ "n", "v" }, "<C-s>", "<cmd>write<CR>", { desc = "Save" })
-- langmap doesn't cover Ctrl chords, so these follow the same shifted layout
map("n", "<C-j>", "<C-w>h", { desc = "Window left" })
map("n", "<C-k>", "<C-w>j", { desc = "Window down" })
map("n", "<C-l>", "<C-w>k", { desc = "Window up" })
map("n", "<C-;>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostic under cursor" })

-- Show diagnostics inline at the end of the line
vim.diagnostic.config({ virtual_text = true, severity_sort = true, float = { border = "rounded" } })

--------------------------------------------------------------------------------
-- Plugins (lazy.nvim). Versions are pinned in lazy-lock.json; update with :Lazy.
--------------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Theme: Monokai Pro Light, the same palette as Ghostty
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai-pro").setup({ filter = "light" })
      vim.cmd.colorscheme("monokai-pro-light")
    end,
  },

  -- Pop-up list of shortcuts after pressing a key like <Space>
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>c", group = "code" },
        { "<leader>g", group = "git" },
      },
    },
  },

  -- Suggests the next Vim command to learn, based on how you actually edit.
  -- :Tobira next tip, :TobiraGuide cheat sheet, :TobiraProgress skill tree.
  -- Its tips name standard keys; with the layout above, h/j/k/l/; are shifted.
  { "kamegoro/tobira.nvim", event = "VeryLazy", opts = {} },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "monokai-pro" } },
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", desc = "File tree" } },
    opts = {},
  },

  -- Fuzzy finding, using fzf like the shell does
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Grep text" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Open buffers" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<CR>", desc = "Recent files" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_document<CR>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", desc = "Symbols" },
      { "<leader>fH", "<cmd>FzfLua helptags<CR>", desc = "Help" },
      { "<leader>f?", "<cmd>FzfLua keymaps<CR>", desc = "Keymaps" },
    },
    opts = {},
  },

  -- Git changes in the gutter; ]c / [c jump between them
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function bmap(lhs, rhs, desc) map("n", lhs, rhs, { buffer = buf, desc = desc }) end
        bmap("]c", function() gs.nav_hunk("next") end, "Next git change")
        bmap("[c", function() gs.nav_hunk("prev") end, "Previous git change")
        bmap("<leader>gp", gs.preview_hunk, "Preview change")
        bmap("<leader>gs", gs.stage_hunk, "Stage change")
        bmap("<leader>gr", gs.reset_hunk, "Reset change")
        bmap("<leader>gb", gs.blame_line, "Blame line")
      end,
    },
  },

  -- Syntax highlighting via tree-sitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "bash", "go", "gomod", "gosum", "gowork", "javascript", "json", "lua",
        "markdown", "markdown_inline", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
      })
      -- Turn highlighting on for any filetype that has a parser
      vim.api.nvim_create_autocmd("FileType", {
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },

  -- Installs language servers and formatters (see :Mason)
  { "mason-org/mason.nvim", opts = {} },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "gopls", -- Go language server
        "vtsls", -- TypeScript/JavaScript language server
        "gofumpt", -- Go formatter (stricter gofmt)
        "goimports", -- adds/removes Go imports
        "prettierd", -- TypeScript/JavaScript/JSON formatter
      },
    },
  },

  -- Language servers: completion, go-to-definition, errors, rename, ...
  -- Neovim's defaults: K hover, grn rename, gra code action, grr references,
  -- gri implementation, [d / ]d previous/next diagnostic.
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
      vim.lsp.enable({ "gopls", "vtsls" })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local function bmap(lhs, rhs, desc) map("n", lhs, rhs, { buffer = args.buf, desc = desc }) end
          bmap("gd", vim.lsp.buf.definition, "Go to definition")
          bmap("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
          bmap("<leader>cR", "<cmd>FzfLua lsp_references<CR>", "References")
        end,
      })
    end,
  },

  -- Completion menu: <Enter> accepts, <C-n>/<C-p> or arrows move, <C-e> closes
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "enter" },
      completion = { documentation = { auto_show = true } },
      signature = { enabled = true },
    },
  },

  -- Format on save
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      { "<leader>cf", function() require("conform").format({ lsp_format = "fallback" }) end, desc = "Format file" },
    },
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        json = { "prettierd" },
      },
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
    },
  },
}, {
  install = { colorscheme = { "monokai-pro-light" } },
  checker = { enabled = false }, -- no background update checks; update from :Lazy
  change_detection = { notify = false },
})
