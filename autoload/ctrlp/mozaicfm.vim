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

let s:mozaicfm_var = {
      \ 'init':   'ctrlp#mozaicfm#init()',
      \ 'accept': 'ctrlp#mozaicfm#accept',
      \ 'lname':  'mozaicfm',
      \ 'sname':  'mozaicfm',
      \ 'type':   'line',
      \ 'sort':   0
      \}
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:mozaicfm_var)
else
  let g:ctrlp_ext_vars = [s:mozaicfm_var]
endif


function! ctrlp#mozaicfm#init()
  let s:channel_list = mozaicfm#get_channel_list()
  return map(copy(s:channel_list), 'v:val.title')
endfunction

function! ctrlp#mozaicfm#accept(mode, str)
  call ctrlp#exit()
  for l:channel in s:channel_list
    if l:channel.title ==# a:str
      call mozaicfm#play(l:channel)
      call mozaicfm#show_info()
      return
    endif
  endfor
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#mozaicfm#id()
  return s:id
endfunction
