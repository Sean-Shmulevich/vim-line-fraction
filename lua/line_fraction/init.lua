local M = {}
M._setup_called = false

-- Returns the 0-indexed byte column in `line` where cumulative display
-- width first reaches `target_display`. Handles multibyte / wide chars.
local function find_col(line, target_display)
  local nchars   = vim.fn.strchars(line)
  local cur_w    = 0
  local byte_pos = 0          -- bytes consumed so far

  for i = 0, nchars - 1 do
    if cur_w >= target_display then break end
    local ch   = vim.fn.strcharpart(line, i, 1)
    cur_w      = cur_w    + vim.fn.strdisplaywidth(ch)
    byte_pos   = byte_pos + #ch
  end

  -- byte_pos is the 0-indexed offset of the char *after* the last one we
  -- stepped through, which is exactly the column we want for nvim_win_set_cursor.
  -- Clamp to the last valid byte index so we never go past end-of-line.
  return math.min(byte_pos, math.max(0, #line - 1))
end

local function jump(count)
  local cfg    = require('line_fraction.config').get()
  local line   = vim.fn.getline('.')
  local total_w = vim.fn.strdisplaywidth(line)

  if total_w == 0 then
    vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), 0 })
    return
  end

  -- first_nonblank: 0-indexed byte offset of the first non-blank char
  local fnb = vim.fn.match(line, '\\S')
  if fnb == -1 then fnb = 0 end

  local frac = cfg.fractions[count]
  if frac == nil then frac = cfg.fractions[0] end

  if frac == 'first_nonblank' then
    vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), fnb })
    return
  end

  -- Display width of leading whitespace (handles tabs correctly)
  local lead_w = fnb > 0 and vim.fn.strdisplaywidth(line:sub(1, fnb)) or 0
  local eff_w  = total_w - lead_w
  local target = math.min(math.ceil(eff_w * frac) + lead_w, total_w)

  vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), find_col(line, target) })
end

-- Public: call from your own mappings if default_mappings = false
function M.jump(count)
  jump(count)
end

-- Call this in your lazy/packer config block, e.g.:
--   require('line_fraction').setup({ mapping = '<Space>' })
function M.setup(opts)
  M._setup_called = true
  local config = require('line_fraction.config')
  config.apply(opts)
  local cfg = config.get()

  if cfg.default_mappings then
    vim.keymap.set(cfg.modes, cfg.mapping, function()
      jump(vim.v.count)
    end, { noremap = true, silent = true, desc = 'Jump to line fraction' })
  end
end

-- Called from plugin/line_fraction.vim for non-lazy plugin managers.
-- Defers to VimEnter so user config runs first.
function M._auto_setup()
  vim.api.nvim_create_autocmd('VimEnter', {
    once     = true,
    callback = function()
      if not M._setup_called then
        M.setup()
      end
    end,
  })
end

return M
