" ============================================================================
" FILE: mozaicfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" CtrlP extension of vim-mozaicfm.
" CtrlP: https://github.com/ctrlpvim/ctrlp.vim
" }}}
" ============================================================================
if exists('g:loaded_ctrlp_mozaicfm') && g:loaded_ctrlp_mozaicfm
  finish
endif
let g:loaded_ctrlp_mozaicfm = 1
let s:ctrlp_builtins = ctrlp#getvar('g:ctrlp_builtins')

let s:mozaicfm_var = {
      \ 'init': 'ctrlp#mozaicfm#init()',
      \ 'accept': 'ctrlp#mozaicfm#accept',
      \ 'lname': 'mozaicfm',
      \ 'sname': 'mozaicfm',
      \ 'type': 'line',
      \ 'sort': 0,
      \ 'nolim': 1
      \}
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  call add(g:ctrlp_ext_vars, s:mozaicfm_var)
else
  let g:ctrlp_ext_vars = [s:mozaicfm_var]
endif

let s:id = s:ctrlp_builtins + len(g:ctrlp_ext_vars)
unlet s:ctrlp_builtins
function! ctrlp#mozaicfm#id() abort
  return s:id
endfunction

function! ctrlp#mozaicfm#init() abort
  let s:channel_list = mozaicfm#get_channel_list()
  return map(copy(s:channel_list), 'v:val.title')
endfunction

function! ctrlp#mozaicfm#accept(mode, str) abort
  call ctrlp#exit()
  for l:channel in s:channel_list
    if l:channel.title ==# a:str
      call mozaicfm#play(l:channel)
      call mozaicfm#show_info()
      return
    endif
  endfor
endfunction
