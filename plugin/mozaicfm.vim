" ============================================================================
" FILE: mozaicfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" mozaic.fm client for Vim.
" mozaic.fm: http://mozaic.fm/
" }}}
" ============================================================================
if exists('g:loaded_mozaicfm')
  finish
endif
let g:loaded_mozaicfm = 1
let s:save_cpo = &cpo
set cpo&vim


command! -bar -nargs=1 MozaicfmPlayByNumber call mozaicfm#play_by_number(<f-args>)
command! -bar -nargs=0 MozaicfmStop call mozaicfm#stop()
command! -bar -nargs=0 MozaicfmTogglePause call mozaicfm#toggle_mute()
command! -bar -nargs=0 MozaicfmToggleMute call mozaicfm#toggle_pause()
command! -bar -nargs=1 MozaicfmVolume call mozaicfm#set_volume(<f-args>)
command! -bar -nargs=1 MozaicfmSpeed call mozaicfm#set_speed(<f-args>)
command! -bar -nargs=1 MozaicfmSeek call mozaicfm#seek(<f-args>)
command! -bar -nargs=1 MozaicfmRelSeek call mozaicfm#rel_seek(<f-args>)
command! -bar -nargs=0 MozaicfmShowInfo call mozaicfm#show_info()
command! -bar -nargs=0 MozaicfmUpdateChannel call mozaicfm#update_channel()


augroup Mozaicfm
  autocmd!
  autocmd VimLeave * call mozaicfm#stop()
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
