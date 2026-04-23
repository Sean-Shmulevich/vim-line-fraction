# vim-line-fraction

Jump to a fraction of the current line with a single keypress. Works in normal and visual mode, handles multibyte / wide characters, and supports Vim 8+ and Neovim.

## What it does

| Key  | Jumps to                       |
|------|--------------------------------|
| `gm` | Middle of the line (50%)       |
| `1gm`| First non-blank character      |
| `2gm`| 25% of the line                |
| `3gm`| 75% of the line                |
| `4gm`| End of the line                |

Fractions are calculated over the non-blank content of the line (leading whitespace is excluded from the percentage, but the cursor lands in the correct absolute position).

In **visual mode** the same keys extend or shrink the selection.

## Installation

### lazy.nvim

```lua
{
  'seanshmulevich/vim-line-fraction',
  opts = {},   -- or pass a config table (see Configuration)
}
```

### packer.nvim

```lua
use {
  'seanshmulevich/vim-line-fraction',
  config = function()
    require('line_fraction').setup()
  end,
}
```

### vim-plug (Neovim or Vim)

```vim
Plug 'seanshmulevich/vim-line-fraction'
```

No extra configuration needed — mappings are set up automatically.

### Manual / pathogen

Clone into your `pack` or `bundle` directory:

```sh
git clone https://github.com/seanshmulevich/vim-line-fraction \
  ~/.vim/pack/plugins/start/vim-line-fraction
```

## Configuration

### Neovim (Lua)

Pass options to `setup()`:

```lua
require('line_fraction').setup({
  mapping          = 'gm',    -- key to use
  modes            = {'n','v'},
  default_mappings = true,    -- set false to define your own
  fractions = {
    [0] = 0.5,                -- gm      → 50%
    [1] = 'first_nonblank',   -- 1gm     → first non-blank
    [2] = 0.25,               -- 2gm     → 25%
    [3] = 0.75,               -- 3gm     → 75%
    [4] = 1.0,                -- 4gm     → end of line
  },
})
```

With **lazy.nvim** use the `opts` table directly:

```lua
{
  'seanshmulevich/vim-line-fraction',
  opts = { mapping = '<Space>' },
}
```

### Vim (Vimscript)

Set these globals **before** the plugin loads (e.g. in your `.vimrc`):

```vim
" Change the key (default: gm)
let g:line_fraction_mapping = 'gm'

" Example: use <Space> instead of gm
let g:line_fraction_mapping = '<Space>'

" Disable default mappings and define your own
let g:line_fraction_no_mappings = 1
nmap <silent> <Space> <Plug>(LineFractionJump)
xmap <silent> <Space> <Plug>(LineFractionJump)

" Override fractions
let g:line_fraction_fractions = {0: 0.5, 2: 0.25, 3: 0.75, 4: 1.0}
```

## Custom mappings (Neovim)

```lua
require('line_fraction').setup({ default_mappings = false })

vim.keymap.set({'n','v'}, '<Space>', function()
  require('line_fraction').jump(vim.v.count)
end, { noremap = true, silent = true })
```

## Reassigning count prefixes

Every count→fraction mapping is configurable. You can reassign the defaults,
add new slots, or remove ones you don't use:

```lua
-- Example: put first-nonblank on 4, shift everything else down,
-- and add a ⅓ slot on 5.
require('line_fraction').setup({
  fractions = {
    [0] = 0.5,              -- gm  → middle
    [1] = 0.25,             -- 1gm → 25%
    [2] = 0.5,              -- 2gm → middle (same as no-count)
    [3] = 0.75,             -- 3gm → 75%
    [4] = 'first_nonblank', -- 4gm → first non-blank
    [5] = 0.33,             -- 5gm → ⅓  (custom)
  },
})
```

In Vim:
```vim
let g:line_fraction_fractions = {0: 0.5, 1: 0.25, 3: 0.75, 4: 1.0, 5: 0.33}
```

## How fractions work

For a line with leading whitespace the percentage is applied to the
**non-blank** portion of the line, so `gm` always lands near the visual
centre of the content rather than the centre of the indented line.

Unknown count prefixes (e.g. `9gm`) fall back to 50% (middle) unless
you add them to the `fractions` table.

## Requirements

- **Neovim** 0.7+ **or** **Vim** 8.0+ (requires `strcharpart`, `strdisplaywidth`, `float2nr`)
