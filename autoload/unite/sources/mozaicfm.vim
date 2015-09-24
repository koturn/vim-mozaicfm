" ============================================================================
" FILE: mozaicfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Unite source of mozaicfm.vim
" unite.vim: https://github.com/Shougo/unite.vim
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


let s:source = {
      \ 'name': 'mozaicfm',
      \ 'description': 'candidates from Mozaic.fm numbers',
      \ 'hooks': {},
      \ 'action_table': {
      \   'play': {
      \     'description': 'Play this m4a',
      \   }
      \ },
      \ 'default_action': 'play',
      \}

function! unite#sources#mozaicfm#define() abort
  return s:source
endfunction


function! s:source.action_table.play.func(candidate) abort
  call mozaicfm#play(a:candidate.action__channel)
endfunction

function! s:source.gather_candidates(args, context) abort
  let l:channels = mozaicfm#get_channel_list()
  let a:context.source.unite__cached_candidates = []
  return map(l:channels, '{
        \ "word": v:val.title,
        \ "action__channel": v:val,
        \}')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
