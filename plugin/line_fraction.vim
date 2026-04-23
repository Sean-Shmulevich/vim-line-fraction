if exists('g:loaded_line_fraction') | finish | endif
let g:loaded_line_fraction = 1

" Neovim: hand off to Lua; setup() is called at VimEnter unless the user
" already called it explicitly (e.g. via lazy.nvim's config/opts).
if has('nvim')
  lua require('line_fraction')._auto_setup()
  finish
endif

" ── Pure Vimscript implementation (Vim 8+) ───────────────────────────────

" Returns the 1-based byte column in `line` where cumulative display width
" first reaches `target_display`.  Handles multibyte / wide characters.
function! s:FindCol(line, target_display) abort
  let l:nchars   = strchars(a:line)
  let l:cur_w    = 0
  let l:byte_pos = 0
  let l:i        = 0
  while l:i < l:nchars && l:cur_w < a:target_display
    let l:ch       = strcharpart(a:line, l:i, 1)
    let l:cur_w   += strdisplaywidth(l:ch)
    let l:byte_pos += len(l:ch)
    let l:i        += 1
  endwhile
  " byte_pos bytes have been consumed; in Vim's 1-based world that same
  " boundary is column byte_pos (it points to the char we just landed on).
  " Clamp to len(line) so we never go past end-of-line.
  return min([l:byte_pos, len(a:line)])
endfunction

function! s:Jump(count) abort
  let l:line    = getline('.')
  let l:total_w = strdisplaywidth(l:line)
  if l:total_w == 0 | return | endif

  " first_nonblank: 0-based byte offset of the first non-blank char
  let l:fnb = match(l:line, '\S')
  if l:fnb == -1 | let l:fnb = 0 | endif

  " count == 1 → jump to first non-blank (cursor() is 1-based)
  if a:count == 1
    call cursor(line('.'), l:fnb + 1)
    return
  endif

  " Map count → fraction; unknown counts fall back to 0.5 (middle)
  let l:fracs = get(g:, 'line_fraction_fractions',
        \ {0: 0.5, 2: 0.25, 3: 0.75, 4: 1.0})
  let l:frac  = get(l:fracs, a:count, 0.5)

  " Display width of leading whitespace (handles tabs correctly)
  let l:lead_w = l:fnb > 0 ? strdisplaywidth(l:line[:l:fnb - 1]) : 0
  let l:eff_w  = l:total_w - l:lead_w
  let l:target = min([float2nr(ceil(l:eff_w * l:frac)) + l:lead_w, l:total_w])

  call cursor(line('.'), s:FindCol(l:line, l:target))
endfunction

" ── <Plug> mappings (users can remap these to any key) ───────────────────
nnoremap <silent> <Plug>(LineFractionJump) :<C-u>call <SID>Jump(v:count)<CR>
xnoremap <silent> <Plug>(LineFractionJump) :<C-u>call <SID>Jump(v:count)<CR>

" ── Default mappings ─────────────────────────────────────────────────────
" Disable with:  let g:line_fraction_no_mappings = 1
" Change key with:  let g:line_fraction_mapping = '<Space>'
if !get(g:, 'line_fraction_no_mappings', 0)
  let s:map = get(g:, 'line_fraction_mapping', 'gm')
  if !hasmapto('<Plug>(LineFractionJump)', 'n')
    execute 'nmap <silent> ' . s:map . ' <Plug>(LineFractionJump)'
  endif
  if !hasmapto('<Plug>(LineFractionJump)', 'x')
    execute 'xmap <silent> ' . s:map . ' <Plug>(LineFractionJump)'
  endif
endif
