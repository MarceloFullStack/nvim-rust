-- ╭─ LSP: inteligência de código (definições, refs, rename, erros) ─╮
return {

  -- ── Mason: instala LSPs, formatters e debuggers sem sudo ───
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
      ensure_installed = {
        "codelldb",      -- debugger pra Rust/C/C++
        "taplo",         -- LSP de TOML (Cargo.toml)
        "lua-language-server",
        "stylua",
        "shfmt",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      -- instala o que falta em background
      local reg = require("mason-registry")
      reg.refresh(function()
        for _, name in ipairs(opts.ensure_installed) do
          local ok, pkg = pcall(reg.get_package, name)
          if ok and not pkg:is_installed() then pkg:install() end
        end
      end)
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = { "lua_ls", "taplo" },
      automatic_enable = { exclude = { "rust_analyzer" } }, -- rustaceanvim cuida do Rust
    },
  },

  -- ── lazydev: autocomplete perfeito ao editar a config do nvim
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  -- ── Configuração central do LSP ────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
      -- capabilities do blink.cmp (diz ao servidor o que sabemos receber)
      local caps = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = caps })

      -- ── lua_ls ──
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            codeLens = { enable = true },
            hint = { enable = true, arrayIndex = "Disable" },
            diagnostics = { globals = { "vim", "Snacks" } },
          },
        },
      })

      -- ── taplo (TOML / Cargo.toml) ──
      vim.lsp.config("taplo", {})

      -- ── Atalhos que só existem quando há LSP no buffer ──
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end

          -- navegação (usa o picker do snacks pra listas)
          map("gd", function() Snacks.picker.lsp_definitions() end,      "Ir pra definição")
          map("gD", function() Snacks.picker.lsp_declarations() end,     "Ir pra declaração")
          map("gr", function() Snacks.picker.lsp_references() end,       "Referências")
          map("gI", function() Snacks.picker.lsp_implementations() end,  "Implementações")
          map("gy", function() Snacks.picker.lsp_type_definitions() end, "Definição do tipo")
          map("<leader>cs", function() Snacks.picker.lsp_symbols() end,  "Símbolos do arquivo")
          map("<leader>cS", function() Snacks.picker.lsp_workspace_symbols() end, "Símbolos do projeto")

          -- documentação
          map("K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Documentação (hover)")

          -- ações
          map("<leader>cr", vim.lsp.buf.rename, "Renomear símbolo")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<leader>cA", function() vim.lsp.buf.code_action({ context = { only = { "source" } } }) end, "Source action")

          -- diagnostics
          map("<leader>cd", vim.diagnostic.open_float, "Detalhe do erro na linha")

          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          -- inlay hints: mostra os tipos inferidos inline (ESSENCIAL em Rust)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            map("<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
            end, "Toggle inlay hints")
          end

          -- code lens (ex: "Run test" acima de #[test])
          -- enable() já cuida do refresh automático; não precisa de autocmd
          if client and client:supports_method("textDocument/codeLens") then
            vim.lsp.codelens.enable(true, { bufnr = buf })
            map("<leader>cl", vim.lsp.codelens.run, "Rodar code lens")
          end

          -- realça outras ocorrências do símbolo sob o cursor
          if client and client:supports_method("textDocument/documentHighlight") then
            local g = vim.api.nvim_create_augroup("lsp_highlight_" .. buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = buf, group = g, callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = buf, group = g, callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  -- ── conform: formatação (rustfmt, stylua...) ───────────────
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt", lsp_format = "fallback" },
        lua = { "stylua" },
        sh = { "shfmt" },
        toml = { "taplo" },
        json = { "jq" },
        ["_"] = { "trim_whitespace" }, -- fallback pra qualquer outro ft
      },
      format_on_save = function(bufnr)
        -- desliga globalmente com :FormatToggle ou por buffer
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
        return { timeout_ms = 3000, lsp_format = "fallback" }
      end,
      formatters = {
        rustfmt = { options = { default_edition = "2024" } },
      },
    },
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, mode = { "n", "v" }, desc = "Formatar" },
    },
    init = function()
      vim.api.nvim_create_user_command("FormatToggle", function(args)
        if args.bang then
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify("Autoformat do buffer: " .. tostring(not vim.b.disable_autoformat))
        else
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Autoformat global: " .. tostring(not vim.g.disable_autoformat))
        end
      end, { bang = true, desc = "Liga/desliga format-on-save (! = só este buffer)" })
    end,
  },

  -- ── fidget: mostra o progresso do rust-analyzer indexando ──
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      notification = { window = { winblend = 0 } },
      progress = { display = { done_ttl = 2 } },
    },
  },
}
