" ============================================================================
" FILE: mozaicfm.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" mozaic.fm client for Vim.
" mozaic.fm: http://mozaic.fm/
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


let g:mozaicfm#play_command = get(g:, 'mozaicfm#play_command', 'mplayer')
let g:mozaicfm#play_option = get(g:, 'mozaicfm#play_option', '-really-quiet -slave -cache 1024 -novideo')
let g:mozaicfm#cache_dir = get(g:, 'mozaicfm#cache_dir', expand('~/.cache/mozaicfm'))
let g:mozaicfm#verbose = get(g:, 'mozaicfm#verbose', 0)

let s:V = vital#of('mozaicfm')
let s:L = s:V.import('Data.List')
let s:CacheFile = s:V.import('System.Cache').new('file', {'cache_dir': g:mozaicfm#cache_dir})
let s:HTTP = s:V.import('Web.HTTP')
let s:XML = s:V.import('Web.XML')
let s:PM = s:V.import('ProcessManager')

let s:current_channel = {}
let s:MOZAICFM_FEEDS_URL = 'http://feeds.feedburner.com/mozaicfm'
let s:MOZAICFM_M4A_FILE_FORMAT = 'http://files.mozaic.fm/mozaic-ep%s.m4a'
let s:CACHE_NAME = 'channel'
let s:PROCESS_NAME = 'mozaicfm'
lockvar s:MOZAICFM_FEEDS_URL
lockvar s:MOZAICFM_M4A_URL_FORMAT
lockvar s:CACHE_NAME
lockvar s:PROCESS_NAME


function! mozaicfm#play(channel) abort
  let s:current_channel = a:channel
  call s:play(a:channel.enclosure)
endfunction

function! mozaicfm#play_by_number(str) abort
  let url = printf(s:MOZAICFM_M4A_FILE_FORMAT, a:str)
  for channel in mozaicfm#get_channel_list()
    if channel.enclosure ==# url
      let s:current_channel = channel
      call s:play(url)
      return
    endif
  endfor
  echoerr 'M4A file was Not Found'
endfunction

function! mozaicfm#show_info() abort
  if empty(s:current_channel) || !s:is_playing() | return | endif
  echo '[TITLE] ' s:current_channel.title
  echo '[PUBLISHED DATE] ' s:current_channel.pubDate
  echo '[FILE URL] ' s:current_channel.enclosure
  echo '[SUMMARY]'
  echo '  ' s:current_channel.summary
  echo '[NOTES]'
  for item in s:current_channel.note
    echo '  -' item.text
  endfor
endfunction

function! mozaicfm#toggle_pause() abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'pause')
  endif
endfunction

function! mozaicfm#toggle_mute() abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'mute')
  endif
endfunction

function! mozaicfm#set_volume(volume) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'volume ' . a:volume . ' 1')
  endif
endfunction

function! mozaicfm#set_speed(speed) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'speed_set ' . a:speed)
  endif
endfunction

function! mozaicfm#seek(pos) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos . ' 1')
  endif
endfunction

function! mozaicfm#rel_seek(pos) abort
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos)
  endif
endfunction

function! mozaicfm#stop() abort
  if s:is_playing()
    call s:PM.kill(s:PROCESS_NAME)
  endif
endfunction

function! mozaicfm#get_channel_list() abort
  let infos = s:CacheFile.get(s:CACHE_NAME)
  return empty(infos) ? mozaicfm#update_channel() : infos
endfunction

function! mozaicfm#update_channel() abort
  let start_time = reltime()
  let time = start_time
  let response = s:HTTP.get(s:MOZAICFM_FEEDS_URL)
  if response.status != 200
    echoerr 'Connection error:' '[' . response.status . ']' response.statusText
    return
  endif
  if g:mozaicfm#verbose
    echomsg '[HTTP request]:' reltimestr(reltime(time)) 's'
  endif

  let time = reltime()
  let dom = s:XML.parse(response.content)
  if g:mozaicfm#verbose
    echomsg '[parse XML]:   ' reltimestr(reltime(time)) 's'
  endif

  let time = reltime()
  let infos = s:parse_dom(dom)
  if g:mozaicfm#verbose
    echomsg '[parse DOM]:   ' reltimestr(reltime(time)) 's'
    echomsg '[total]:       ' reltimestr(reltime(start_time)) 's'
  endif

  call s:CacheFile.set(s:CACHE_NAME, infos)
  return infos
endfunction


function! s:parse_dom(dom) abort
  let items = a:dom.childNode('channel').childNodes('item')
  return filter(map(items, 's:make_info(v:val)'), 'len(v:val) == 5')
endfunction

function! s:make_info(item) abort
  let info = {}
  for c in filter(a:item.child, 'type(v:val) == 4')
    if c.name ==# 'title'
      let info.title = c.value()
    elseif c.name ==# 'description'
      let info.note = s:parse_description('<html>' . c.value() . '</html>')
    elseif c.name ==# 'pubDate'
      let info.pubDate = c.value()
    elseif c.name ==# 'itunes:summary'
      let info.summary = c.value()
    elseif c.name ==# 'enclosure'
      let info.enclosure = substitute(c.attr.url, '^https', 'http', '')
    endif
  endfor
  return info
endfunction

function! s:parse_description(xml) abort
  let lis = s:L.flatten(map(s:XML.parse(a:xml).childNodes('ul'), 'v:val.childNodes("li")'), 1)
  return map(map(filter(lis, '!empty(v:val.child) && type(v:val.child[0]) == 4'), 'v:val.child[0]'), '{
        \ "href": has_key(v:val.attr, "href") ? v:val.attr.href : "",
        \ "text": v:val.value()
        \}')
endfunction

function! s:play(url) abort
  if !executable(g:mozaicfm#play_command)
    echoerr 'Error: Please install mplayer'
    return
  endif
  if !s:PM.is_available()
    echoerr 'Error: vimproc is unavailable'
    return
  endif
  call mozaicfm#stop()
  call s:PM.touch(s:PROCESS_NAME, g:mozaicfm#play_command . ' ' . g:mozaicfm#play_option . ' ' . a:url)
endfunction

function! s:is_playing() abort
  let status = 'dead'
  try
    let status = s:PM.status(s:PROCESS_NAME)
  catch
  endtry
  return status ==# 'inactive' || status ==# 'active'
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
