local M = {}

local defaults = {
  mapping          = 'gm',
  modes            = { 'n', 'v' },
  default_mappings = true,
  -- What each count prefix does.
  -- Keys are v:count values; missing keys fall back to [0].
  fractions = {
    [0] = 0.5,              -- gm      → middle (50%)
    [1] = 'first_nonblank', -- 1gm     → first non-blank character
    [2] = 0.25,             -- 2gm     → 25%
    [3] = 0.75,             -- 3gm     → 75%
    [4] = 1.0,              -- 4gm     → end of line
  },
}

local current = nil

function M.get()
  if not current then
    current = vim.deepcopy(defaults)
  end
  return current
end

function M.apply(opts)
  current = vim.tbl_deep_extend('force', M.get(), opts or {})
end

return M
