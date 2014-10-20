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
let g:mozaicfm#play_option = get(g:, 'mozaicfm#play_option', '-really-quiet -slave -cache 1024 -vo NONE')
let g:mozaicfm#cache_dir = get(g:, 'mozaicfm#cache_dir', expand('~/.cache/mozaicfm'))
let g:mozaicfm#verbose = get(g:, 'mozaicfm#verbose', 0)

let s:V = vital#of('mozaicfm')
let s:PM = s:V.import('ProcessManager')
let s:CACHE = s:V.import('System.Cache')
let s:JSON = s:V.import('Web.JSON')
let s:HTTP = s:V.import('Web.HTTP')
let s:XML = s:V.import('Web.XML')

let s:current_channel = {}
let s:MOZAICFM_FEEDS_URL = 'http://feeds.feedburner.com/mozaicfm'
let s:MOZAICFM_M4A_FILE_FORMAT = 'http://files.mozaic.fm/mozaic-ep%s.m4a'
let s:CACHE_FILENAME = 'channel.json'
let s:PROCESS_NAME = 'mozaicfm'
lockvar s:MOZAICFM_FEEDS_URL
lockvar s:MOZAICFM_M4A_URL_FORMAT
lockvar s:CACHE_FILENAME
lockvar s:PROCESS_NAME


function! mozaicfm#play(channel)
  let s:current_channel = a:channel
  call s:play(a:channel.enclosure)
endfunction

function! mozaicfm#play_by_number(str)
  let l:url = printf(s:MOZAICFM_M4A_FILE_FORMAT, a:str)
  let l:channels = mozaicfm#get_channel_list()
  for l:channel in l:channels
    if l:channel.enclosure ==# l:url
      let s:current_channel = l:channel
      call s:play(l:url)
      return
    endif
  endfor
  echoerr 'M4A file was Not Found'
endfunction

function! mozaicfm#show_info()
  if empty(s:current_channel) || !s:is_playing() | return | endif
  echo '[TITLE] ' s:current_channel.title
  echo '[PUBLISHED DATE] ' s:current_channel.pubDate
  echo '[FILE URL] ' s:current_channel.enclosure
  echo '[SUMMARY]'
  echo '  ' s:current_channel.summary
  echo '[NOTES]'
  for l:item in s:current_channel.note
    echo '  -' l:item.text
  endfor
endfunction

function! mozaicfm#toggle_pause()
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'pause')
  endif
endfunction

function! mozaicfm#toggle_mute()
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'mute')
  endif
endfunction

function! mozaicfm#set_volume(volume)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'volume ' . a:volume . ' 1')
  endif
endfunction

function! mozaicfm#set_speed(speed)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'speed_set ' . a:speed)
  endif
endfunction

function! mozaicfm#seek(pos)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos . ' 1')
  endif
endfunction

function! mozaicfm#rel_seek(pos)
  if s:is_playing()
    call s:PM.writeln(s:PROCESS_NAME, 'seek ' . a:pos)
  endif
endfunction

function! mozaicfm#stop()
  if s:is_playing()
    call s:PM.kill(s:PROCESS_NAME)
  endif
endfunction

function! mozaicfm#get_channel_list()
  if s:CACHE.filereadable(g:mozaicfm#cache_dir, s:CACHE_FILENAME)
    return s:JSON.decode(s:CACHE.readfile(g:mozaicfm#cache_dir, s:CACHE_FILENAME)[0]).mozaicfm
  else
    return mozaicfm#update_channel()
  endif
endfunction

function! mozaicfm#update_channel()
  let l:start_time = reltime()
  let l:time = l:start_time
  let l:response = s:HTTP.get(s:MOZAICFM_FEEDS_URL)
  if l:response.status != 200
    echoerr 'Connection error:' '[' . l:response.status . ']' l:response.statusText
    return
  endif
  if g:mozaicfm#verbose
    echomsg '[HTTP request]:' reltimestr(reltime(l:time)) 's'
  endif

  let l:time = reltime()
  let l:dom = s:XML.parse(l:response.content)
  if g:mozaicfm#verbose
    echomsg '[parse XML]:   ' reltimestr(reltime(l:time)) 's'
  endif

  let l:time = reltime()
  let l:infos = s:parse_dom(l:dom)
  if g:mozaicfm#verbose
    echomsg '[parse DOM]:   ' reltimestr(reltime(l:time)) 's'
    echomsg '[total]:       ' reltimestr(reltime(l:start_time)) 's'
  endif

  let l:write_list = [s:JSON.encode({'mozaicfm': l:infos})]
  call s:CACHE.writefile(g:mozaicfm#cache_dir, s:CACHE_FILENAME, l:write_list)
  return l:infos
endfunction


function! s:parse_dom(dom)
  let l:channels = s:get_children_by_name(a:dom, 'channel')
  let l:items = s:get_children_by_name(l:channels, 'item')
  let l:infos = []
  for l:c1 in l:items
    let l:info = {}
    for l:c2 in l:c1.child
      if type(l:c2) == 4
        if l:c2.name ==# 'title'
          let l:info.title = l:c2.child[0]
        elseif l:c2.name ==# 'description'
          let l:info.note = s:parse_description('<html>' . l:c2.child[0] . '</html>')
        elseif l:c2.name ==# 'pubDate'
          let l:info.pubDate = l:c2.child[0]
        elseif l:c2.name ==# 'itunes:summary'
          let l:info.summary = l:c2.child[0]
        elseif l:c2.name ==# 'enclosure'
          let l:info.enclosure = substitute(l:c2.attr.url, '^https', 'http', '')
        endif
      endif
      unlet l:c2
    endfor
    if len(l:info) == 5
      call add(l:infos, l:info)
    endif
  endfor
  return l:infos
endfunction

function! s:parse_description(xml)
  let l:dom = s:XML.parse(a:xml)
  let l:uls = s:get_children_by_name(l:dom, 'ul')
  let l:lis = s:get_children_by_name(l:uls, 'li')
  let l:lis = filter(l:lis, '!empty(v:val.child) && type(v:val.child[0]) == 4')
  return map(l:lis, '{
        \ "href": v:val.child[0].attr.href,
        \ "text": v:val.child[0].child[0]
        \}')
endfunction

function! s:get_children_by_name(parents, child_name)
  let l:child_list = []
  if type(a:parents) == 4
    let l:child_list = filter(a:parents.child, 'type(v:val) == 4 && v:val.name ==# a:child_name')
  else
    let l:child_list = []
    for l:c1 in a:parents
      let l:child_list += filter(l:c1.child, 'type(v:val) == 4 && v:val.name ==# a:child_name')
      unlet l:c1 
    endfor
  endif
  return l:child_list
endfunction

function! s:play(url)
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

function! s:is_playing()
  let l:status = 'dead'
  try
    let l:status = s:PM.status(s:PROCESS_NAME)
  catch
  endtry
  return l:status ==# 'inactive' || l:status ==# 'active'
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
