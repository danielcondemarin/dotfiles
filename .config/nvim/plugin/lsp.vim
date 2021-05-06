lua << EOF
  local nvim_lsp = require'lspconfig'

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true;

  local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[g', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']g', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

    -- Set some keybinds conditional on server capabilities
    if client.resolved_capabilities.document_formatting then
      buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
    end
    if client.resolved_capabilities.document_range_formatting then
      buf_set_keymap("v", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
    end

    -- Set autocommands conditional on server_capabilities
    if client.resolved_capabilities.document_highlight then
      -- vim.api.nvim_exec([[
      --   hi LspReferenceText guifg=NONE guibg=#444444 guisp=NONE gui=bold,italic cterm=bold,italic
      --   hi LspReferenceRead guifg=NONE guibg=#444444 guisp=NONE gui=bold,italic cterm=bold,italic
      --   hi LspReferenceWrite guifg=NONE guibg=#444444 guisp=NONE gui=bold,italic cterm=bold,italic
      --   augroup lsp_document_highlight
      --     autocmd! * <buffer>
      --     autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      --     autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      --   augroup END
      -- ]], false)
    end
 
    require'completion'.on_attach(client, bufnr)
  end

  -- Use a loop to conveniently both setup defined servers 
  -- and map buffer local keybindings when the language server attaches
  local servers = { "gopls", "rust_analyzer", "tsserver", "jsonls", "html" }
  for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup { on_attach = on_attach, capabilities = capabilities, init_options = { usePlaceholders = true, completeUnimported = true } }
  end

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      -- Enable underline, use default values
      underline = true,
      -- Enable virtual text, override spacing to 4
      virtual_text = {
        spacing = 4,
        prefix = '●'
      },
      -- Use a function to dynamically turn signs off
      -- and on, using buffer local variables
      signs = function(bufnr, client_id)
        local ok, result = pcall(vim.api.nvim_buf_get_var, bufnr, 'show_signs')
        -- No buffer local variable set, so just enable by default
        if not ok then
          return true
        end

        return result
      end,
    }
  )
EOF

" Signs
call sign_define('LspDiagnosticsSignError',       { 'text': '',       'texthl': 'LspDiagnosticsSignError'       })
call sign_define('LspDiagnosticsSignWarning',     { 'text': '',       'texthl': 'LspDiagnosticsSignWarning'     })
call sign_define('LspDiagnosticsSignInformation', { 'text': '', 'texthl': 'LspDiagnosticsSignInformation' })
call sign_define('LspDiagnosticsSignHint',        { 'text': '',        'texthl': 'LspDiagnosticsSignHint'        })
