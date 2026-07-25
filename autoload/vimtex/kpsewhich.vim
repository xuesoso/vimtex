" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#kpsewhich#find(file) abort " {{{1
  let l:cache = vimtex#cache#open('kpsewhich', {'default': []})

  let l:root = exists('b:vimtex.root') ? b:vimtex.root : getcwd()
  let l:current = l:cache.get(a:file)

  " Check cache for result
  try
    for [l:result, l:result_root] in l:current
      if empty(l:result_root) || l:result_root ==# l:root
        return l:result
      endif
    endfor
  catch
    " The cache is in an outdated/invalid format. This happens e.g. when
    " upgrading from an old VimTeX whose kpsewhich cache stored plain strings
    " instead of [result, root] pairs. Self-heal by clearing the stale cache so
    " subsequent lookups rebuild it automatically, instead of failing on every
    " lookup and nagging the user to clear it by hand. We clear the cache object
    " directly (rather than via vimtex#cache#clear) to reset its in-memory data
    " and delete the file without depending on the global cache registry.
    call l:cache.clear()
    return ''
  endtry

  " Perform search -> [result, result_root]
  let l:result = get(vimtex#kpsewhich#run(vimtex#util#shellescape(a:file)), 0, '')
  if !vimtex#paths#is_abs(l:result)
    let l:result = empty(l:result) ? '' : simplify(l:root . '/' . l:result)
    call add(l:current, [l:result, l:root])
  else
    call add(l:current, [l:result, ''])
  endif

  " Write cache to file
  let l:cache.modified = 1
  call l:cache.write()

  return l:result
endfunction

" }}}1
function! vimtex#kpsewhich#run(args) abort " {{{1
  " kpsewhich should be run at the project root directory
  if exists('b:vimtex.root')
    call vimtex#paths#pushd(b:vimtex.root)
  endif
  let l:output = vimtex#jobs#capture('kpsewhich ' . a:args)
  if exists('b:vimtex.root')
    call vimtex#paths#popd()
  endif

  " Remove warning lines from output
  call filter(l:output, {_, x -> stridx(x, 'kpsewhich: warning: ') == -1})

  return l:output
endfunction

" }}}1
