-- =====================================================================
-- Neovim für Python | Arch Linux | benötigt Neovim >= 0.11
-- Speichern als: ~/.config/nvim/init.lua
-- =====================================================================

vim.g.mapleader = " "

-- ---------------------------------------------------------------------
-- 1. Grundeinstellungen
-- ---------------------------------------------------------------------
local opt = vim.opt
opt.number = true              -- Zeilennummern links
opt.cursorline = true          -- aktuelle Zeile leicht hervorheben
opt.signcolumn = "yes"         -- feste Spalte für Fehlersymbole (Text springt nicht)
opt.termguicolors = true
opt.mouse = "a"                -- Maus: klicken, markieren, scrollen
opt.clipboard = "unnamedplus"  -- y/p benutzen die System-Zwischenablage
opt.expandtab = true           -- Tab = Leerzeichen (Python-Standard)
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.wrap = false
opt.scrolloff = 8
opt.undofile = true           -- Rückgängig-Verlauf bleibt nach Neustart erhalten
opt.updatetime = 250
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.pumheight = 12
opt.completeopt = { "menu", "menuone", "noselect" }

-- Python: Hilfslinie bei 88 Zeichen (Standard von Ruff/Black)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function() vim.opt_local.colorcolumn = "88" end,
})

-- ---------------------------------------------------------------------
-- 2. Tastenkürzel (wie in VS Code)
-- ---------------------------------------------------------------------
local map = vim.keymap.set

-- Strg+S: speichern (Normal-, Insert- und Visual-Modus)
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR>", { desc = "Speichern" })

-- Strg+Z: rückgängig, Strg+Y: wiederholen
map("n", "<C-z>", "u", { desc = "Rückgängig" })
map("i", "<C-z>", "<C-o>u", { desc = "Rückgängig" })
map("v", "<C-z>", "<Esc>u", { desc = "Rückgängig" })
map("n", "<C-y>", "<C-r>", { desc = "Wiederholen" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Wiederholen" })

-- Strg+C: kopieren (ohne Markierung: ganze Zeile, wie VS Code)
map("v", "<C-c>", "y", { desc = "Kopieren" })
map("n", "<C-c>", "yy", { desc = "Zeile kopieren" })

-- Strg+V: einfügen (bei Markierung wird diese ersetzt)
map("n", "<C-v>", '"+P', { desc = "Einfügen" })
map("i", "<C-v>", "<C-r><C-p>+", { desc = "Einfügen" })
map("x", "<C-v>", '"+P', { desc = "Einfügen (ersetzt Markierung)" })
map("c", "<C-v>", "<C-r>+", { desc = "Einfügen" })

-- Strg+V war der Block-Modus, jetzt auf Strg+Q verschoben
map("n", "<C-q>", "<C-v>", { desc = "Visueller Blockmodus" })

-- ---------------------------------------------------------------------
-- 3. Farben: Dunkel mit leichter Transparenz, Hell mit Strg+Super+H
--    Kommentare sind orange.
-- ---------------------------------------------------------------------
local ORANGE_DARK = "#ff9e3b"   -- Kommentarfarbe im dunklen Modus
local ORANGE_LIGHT = "#c25e00"  -- dunkleres Orange, damit es auf Weiß lesbar bleibt
local theme_mode = "dark"

local function apply_theme(mode)
  theme_mode = mode
  local dark = (mode == "dark")
  require("tokyonight").setup({
    style = "night",
    light_style = "day",
    transparent = dark,  -- dunkel: Hintergrund wird "durchsichtig" (Terminal scheint durch)
    styles = {
      comments = { italic = false },
      sidebars = dark and "transparent" or "dark",
      floats = "dark",   -- Popups bleiben undurchsichtig und gut lesbar
    },
    on_highlights = function(hl, _)
      local orange = dark and ORANGE_DARK or ORANGE_LIGHT
      hl.Comment = { fg = orange, italic = false }
      hl["@comment"] = { fg = orange, italic = false }
      -- Optional: Docstrings (""" ... """) ebenfalls orange:
      -- hl["@string.documentation"] = { fg = orange }
    end,
  })
  vim.o.background = dark and "dark" or "light"
  vim.cmd.colorscheme(dark and "tokyonight-night" or "tokyonight-day")
end

local function toggle_theme()
  apply_theme(theme_mode == "dark" and "light" or "dark")
end

-- Strg+Super+H (nur in Terminals mit Kitty-Tastaturprotokoll und wenn der
-- Fenstermanager die Taste nicht selbst belegt). Zuverlässiger: <Leader>th
map({ "n", "i", "v" }, "<C-D-h>", toggle_theme, { desc = "Hell/Dunkel umschalten" })
map("n", "<leader>th", toggle_theme, { desc = "Hell/Dunkel umschalten" })

-- ---------------------------------------------------------------------
-- 4. Python starten: F5
-- ---------------------------------------------------------------------
map({ "n", "i" }, "<F5>", function()
  vim.cmd("write")
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  vim.cmd("botright 12split")
  vim.cmd("terminal python3 " .. file)
end, { desc = "Python-Datei ausführen" })

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(ev)
    map("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = ev.buf })      -- Terminal-Modus verlassen
    map("n", "q", "<cmd>close<CR>", { buffer = ev.buf })           -- Ausgabefenster schließen
  end,
})

-- ---------------------------------------------------------------------
-- 5. Fehleranzeige (Diagnose) wie in VS Code
-- ---------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },  -- Fehlertext hinter der Zeile
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN] = "▲",
      [vim.diagnostic.severity.INFO] = "●",
      [vim.diagnostic.severity.HINT] = "➤",
    },
  },
  underline = true,               -- Wellenlinie unter dem Fehler
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- Wird aktiv, sobald ein Language-Server an eine Datei angehängt wird
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    -- Ruff nur für Lint/Format, Hover-Infos kommen von Pyright
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    -- Parameter-Hinweise beim Tippen eines Funktionsaufrufs
    local ok, sig = pcall(require, "lsp_signature")
    if ok then
      sig.on_attach({ bind = true, hint_enable = false, handler_opts = { border = "rounded" } }, ev.buf)
    end

    local function lmap(lhs, rhs, desc)
      map("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    lmap("K", vim.lsp.buf.hover, "Dokumentation anzeigen")
    lmap("gd", vim.lsp.buf.definition, "Zur Definition springen")
    lmap("<F2>", vim.lsp.buf.rename, "Umbenennen")
    lmap("<leader>ca", vim.lsp.buf.code_action, "Code-Aktionen")
    lmap("<leader>e", vim.diagnostic.open_float, "Fehlertext anzeigen")
    lmap("<leader>dl", vim.diagnostic.setloclist, "Alle Fehler der Datei auflisten")
  end,
})

-- Beim Speichern automatisch mit Ruff formatieren (zum Abschalten: Block löschen)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function(ev)
    if #vim.lsp.get_clients({ bufnr = ev.buf, name = "ruff" }) > 0 then
      vim.lsp.buf.format({ bufnr = ev.buf, async = false, name = "ruff" })
    end
  end,
})

-- ---------------------------------------------------------------------
-- 6. Plugins (lazy.nvim installiert sich beim ersten Start selbst)
-- ---------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Farbschema (dunkel + hell)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function() apply_theme("dark") end,
  },

  -- Syntax-Highlighting (Treesitter, "main"-Zweig; braucht tree-sitter-cli + gcc)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({ "python", "lua", "vim", "vimdoc", "markdown" })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "lua", "markdown" },
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },

  -- Language-Server: Pyright (Typen/Fehler) + Ruff (Stil/Lint/Format)
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })
      vim.lsp.enable({ "pyright", "ruff" })
    end,
  },

  -- Parameter-Hinweise beim Funktionsaufruf (wird in LspAttach geladen)
  { "ray-x/lsp_signature.nvim", lazy = true },

  -- Autovervollständigung mit Popup und Snippets (wie IntelliSense)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",   -- fertige Python-Snippets (def, for, class, ...)
      { "windwp/nvim-autopairs", opts = {} },  -- schließt Klammern/Anführungszeichen automatisch
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      -- nach Funktionsvorschlag automatisch "()" einfügen
      cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = {
          ["<C-Space>"] = cmp.mapping.complete(),                  -- Vorschläge erzwingen
          ["<Down>"] = cmp.mapping.select_next_item(),
          ["<Up>"] = cmp.mapping.select_prev_item(),
          ["<C-e>"] = cmp.mapping.abort(),                         -- Popup schließen
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          -- Tab übernimmt den Vorschlag (Enter bleibt normaler Zeilenumbruch)
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Statuszeile unten (Modus, Datei, Fehleranzahl)
  {
    "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "auto", icons_enabled = false } },
  },
}, {
  change_detection = { notify = false },
})
