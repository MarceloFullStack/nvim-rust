-- ╭─ Debugger (DAP) ─╮
-- Breakpoints reais, step, inspeção de variáveis — dentro do editor.
-- Em Rust: <leader>rd escolhe o alvo (bin/test) e já inicia o codelldb.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = {},
        config = function(_, opts)
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup(opts)
          -- abre/fecha a UI automaticamente com a sessão
          dap.listeners.after.event_initialized["dapui"] = function() dapui.open({}) end
          dap.listeners.before.event_terminated["dapui"] = function() dapui.close({}) end
          dap.listeners.before.event_exited["dapui"] = function() dapui.close({}) end
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text", -- valores das variáveis inline
        opts = { virt_text_pos = "eol", commented = true },
      },
    },
    config = function()
      local dap = require("dap")

      -- adaptador codelldb (instalado pelo Mason)
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = mason_path .. "adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }

      -- ícones
      vim.fn.sign_define("DapBreakpoint",          { text = "", texthl = "DiagnosticError", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn",  numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "", texthl = "DiagnosticInfo",  numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "", texthl = "DiagnosticOk",
                                                     linehl = "Visual", numhl = "" })
    end,
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Breakpoint (liga/desliga)" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condição: ")) end, desc = "Breakpoint condicional" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continuar / iniciar" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL do debugger" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Rodar último" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Encerrar sessão" },
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Toggle UI do debugger" },
      { "<leader>de", function() require("dapui").eval(nil, { enter = true }) end, mode = { "n", "v" }, desc = "Avaliar expressão" },
    },
  },
}
