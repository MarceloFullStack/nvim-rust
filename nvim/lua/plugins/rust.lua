-- ╭─ Rust ─╮
-- rustaceanvim é o padrão atual (sucessor do rust-tools). Ele NÃO usa
-- lspconfig: configura o rust-analyzer sozinho e adiciona recursos que
-- o protocolo LSP não cobre — expandir macros, ver o HIR/MIR, runnables,
-- integração com o debugger, `cargo` como first-class.
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- o próprio plugin já se auto-lazy-loada por filetype
    ft = { "rust" },
    opts = {
      server = {
        on_attach = function(_, bufnr)
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = "Rust: " .. desc })
          end
          -- <leader>r = tudo que é Rust-específico
          map("<leader>ra", function() vim.cmd.RustLsp("codeAction") end,       "Code action (agrupada)")
          map("<leader>rr", function() vim.cmd.RustLsp("runnables") end,        "Runnables (run/test/bench)")
          map("<leader>rR", function() vim.cmd.RustLsp({ "runnables", bang = true }) end, "Repetir último runnable")
          map("<leader>rd", function() vim.cmd.RustLsp("debuggables") end,      "Debuggables")
          map("<leader>rL", function() vim.cmd.RustLsp({ "debuggables", bang = true }) end, "Repetir último debuggable")
          map("<leader>rt", function() vim.cmd.RustLsp("testables") end,        "Testables")
          map("<leader>re", function() vim.cmd.RustLsp("expandMacro") end,      "Expandir macro sob o cursor")
          map("<leader>rc", function() vim.cmd.RustLsp("openCargo") end,        "Abrir Cargo.toml")
          map("<leader>rp", function() vim.cmd.RustLsp("parentModule") end,     "Ir pro módulo pai")
          map("<leader>rj", function() vim.cmd.RustLsp("joinLines") end,        "Join lines (smart)")
          map("<leader>rm", function() vim.cmd.RustLsp("view", "mir") end,      "Ver MIR")
          map("<leader>rh", function() vim.cmd.RustLsp("view", "hir") end,      "Ver HIR")
          map("<leader>ro", function() vim.cmd.RustLsp("openDocs") end,         "Abrir docs.rs do item")
          map("<leader>rE", function() vim.cmd.RustLsp("explainError") end,     "Explicar erro (rustc --explain)")
          map("<leader>rg", function() vim.cmd.RustLsp("crateGraph") end,       "Grafo de crates")
          map("<leader>rs", function() vim.cmd.RustLsp("ssr") end,              "Structural search & replace")
          -- K em Rust vira "hover com ações" (pode navegar pros tipos)
          map("K", function() vim.cmd.RustLsp({ "hover", "actions" }) end,      "Hover com ações")
        end,

        default_settings = {
          ["rust-analyzer"] = {
            -- ── Cargo / check ──
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = { enable = true },
            },
            -- clippy em vez de `cargo check`: MUITO mais útil, custo similar
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" }, -- não roda clippy nas dependências
            },

            -- ── Procedural macros (serde, tokio, etc.) ──
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },

            -- ── Inlay hints: os tipos que o compilador inferiu ──
            inlayHints = {
              bindingModeHints = { enable = false },
              chainingHints = { enable = true },
              closingBraceHints = { enable = true, minLines = 25 },
              closureReturnTypeHints = { enable = "always" },
              lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
              maxLength = 25,
              parameterHints = { enable = true },
              reborrowHints = { enable = "never" },
              renderColons = true,
              typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
            },

            -- ── Melhorias de produtividade ──
            completion = {
              callable = { snippets = "fill_arguments" }, -- completa fn(args)
              postfix = { enable = true },                 -- `x.ok` -> `Ok(x)`
              fullFunctionSignatures = { enable = true },
            },
            lens = {
              enable = true,
              implementations = { enable = true },
              references = { adt = { enable = true }, trait = { enable = true } },
            },
            imports = {
              granularity = { group = "module" },
              prefix = "self",
            },
            diagnostics = {
              enable = true,
              experimental = { enable = true }, -- diagnostics nativos do r-a (mais rápidos)
              styleLints = { enable = true },
            },
            files = {
              excludeDirs = { ".git", "target", ".direnv", "node_modules" },
            },
            semanticHighlighting = {
              operator = { specialization = { enable = true } },
            },
          },
        },
      },

      -- integração com o debugger (usa o codelldb do Mason)
      dap = {
        autoload_configurations = true,
      },

      tools = {
        float_win_config = { border = "rounded" },
        test_executor = "background",
        enable_clippy = true,
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
    end,
  },

  -- ── crates.nvim: gerencia dependências no Cargo.toml ────────
  -- Mostra a versão mais recente ao lado de cada dep, autocompleta
  -- nomes/versões/features e abre a doc da crate.
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    keys = {
      { "<leader>rcu", function() require("crates").upgrade_all_crates() end, desc = "Crates: upgrade todas" },
      { "<leader>rcv", function() require("crates").show_versions_popup() end, desc = "Crates: versões" },
      { "<leader>rcf", function() require("crates").show_features_popup() end, desc = "Crates: features" },
      { "<leader>rcd", function() require("crates").open_documentation() end, desc = "Crates: abrir docs" },
      { "<leader>rcr", function() require("crates").open_repository() end, desc = "Crates: abrir repo" },
    },
  },
}
