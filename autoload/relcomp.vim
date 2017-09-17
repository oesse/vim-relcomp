
" === Public API =======================================================
function! relcomp#CompleteRelativePath(findstart, base)
  if a:findstart
    return relcomp#FindPathStart(line("."), col("."))
  endif

  let nosuf = v:false
  let return_list = v:true

  let file_dir = expand("%:h") 
  let file_list = globpath(file_dir, a:base . "*", nosuf, return_list)

  return relcomp#BuildCompletionList(a:base, file_list, function('isdirectory'))
endfunction


" === Helper Functions =================================================
function! relcomp#FindPathStart(line, column)
  let byte_offset = a:column - 1
  let result_column = s:FindClosestWordStart(a:line, byte_offset) + 1
  return result_column
endfunction

function! s:FindClosestWordStart(line, limit)
  let unix_path_pattern = '[-./[:alnum:]_~]\+'
  let [ignore, start, end] = matchstrpos(a:line, unix_path_pattern, 0)

  let is_empty_line = start == -1
  if is_empty_line
    return a:limit
  endif

  if end >= a:limit
    return start
  endif

  while end != -1 && end < a:limit
    let [ignore, start, end] = matchstrpos(a:line, unix_path_pattern, end + 1)
  endwhile

  return start
endfunction

function! relcomp#StripBaseFromPath(base, path)
  let base_tail = fnamemodify(a:base, ":t")
  let path_tail = fnamemodify(a:path, ":t")
  return strpart(path_tail, len(base_tail))
endfunction

function! relcomp#GetFileTypeIndicator(path, is_directory)
  if a:is_directory
    return "/"
  endif

  let ext = fnamemodify(a:path, ":e")
  if ext == ""
    return ""
  endif

  return "(" . ext . ")"
endfunction

function! relcomp#BuildCompletionList(base, paths, IsDirectory)
  let completion_list = map(
        \  copy(a:paths),
        \  {idx, path -> s:BuildCompletionEntry(path, a:base, a:IsDirectory)}
        \)

  if len(completion_list) == 1
    let [item] = completion_list

    if !has_key(item, "menu")
      return completion_list
    endif

    let type = item["menu"]
    let ext = "/"
    if type != "/"
      " strip parens
      let ext = "." . strpart(item["menu"], 1, len(item["menu"]) - 2)
    endif

    let completion_list += [{ "word": item["word"] . ext }]
  endif

  return completion_list
endfunction

function! s:BuildCompletionEntry(path, base, IsDirectory)
  let name = fnamemodify(a:base . relcomp#StripBaseFromPath(a:base, a:path), ":r")
  let type = relcomp#GetFileTypeIndicator(a:path, a:IsDirectory(a:path))

  if type == ""
    return { "word": name }
  endif

  return { "word": name, "menu": type }
endfunction
