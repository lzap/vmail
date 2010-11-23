" read the mailboxes list

let s:messagebufnr = -1

function! s:CreateWindowA()
  let l:res = system("ruby bin/mailboxes.rb") 
  put =res
  1delete
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nowrap
  setlocal nonumber
  setlocal foldcolumn=0
  setlocal nospell
  setlocal nobuflisted
  setlocal textwidth=0
  setlocal noreadonly
  setlocal cursorline
  let s:mailboxesbufnr = bufnr('%')
  let s:dataDir = expand('%:h')
endfunction

call s:CreateWindowA()
let s:currentBox = getline('.')

function! s:CreateWindowB()
  split List
  setlocal bufhidden=delete
  setlocal buftype=nofile
  " setlocal nomodifiable
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nowrap
  setlocal nonumber
  setlocal foldcolumn=0
  setlocal nospell
  setlocal nobuflisted
  setlocal textwidth=0
  setlocal noreadonly
  " hi CursorLine cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white 
  setlocal cursorline
  let s:listbufnr = bufnr('%')
endfunction

" the message display buffer window
function! s:CreateWindowC() 
  bot vne Message
  setlocal buftype=nofile
  setlocal noswapfile
  let s:messagebufnr = bufnr('%')
endfunction

call s:CreateWindowC()
call s:CreateWindowB()

" switch to WindowA
1 wincmd w
vertical resize 20
2 wincmd w

function! s:ListMessages()
  " load mailbox TOC
  1 wincmd w
  let s:selected_mailbox = getline(".") 
  2 wincmd w  " window 2 is the List
  " fetch data
  call s:refresh_message_list()
  1 wincmd w
endfunction


function! s:ShowMessage()
  " assume we're in window 2
  let line = getline(line("."))
  let l:uid = matchstr(line, '^\d\+')

  let s:uid = l:uid

  3 wincmd w
  1,$delete
  " fetch data
  let l:res = system("ruby bin/message.rb " . shellescape(s:selected_mailbox) . " " . shellescape(s:uid))
  put =res

  1delete
  normal 1
  normal jk
  wincmd p
endfunction

1 wincmd w


function! s:UpdateMailbox() 
  echo "Updating ". s:selected_mailbox
  let res =  system("ruby bin/update.rb " . shellescape(s:selected_mailbox) . " >> update.log 2>&1 &")
endfunction

function! s:refresh_message_list() 
  " assume we're in the message list window
  2 wincmd w
  let l:res = system("ruby bin/messages.rb " . shellescape(s:selected_mailbox))
  setlocal modifiable
  1,$delete
  put =res
  1delete
  setlocal nomodifiable
  normal G
  wincmd p
endfunction


" can map number keys to focus windows and also to alter layout

noremap <Leader>1 :execute "1wincmd w"<CR>
noremap <Leader>2 :execute "2wincmd w"<CR>
noremap <Leader>3 :execute "3wincmd w"<CR>

2 wincmd w
autocmd CursorMoved <buffer> call <SID>ShowMessage()
noremap <silent> <buffer> u :call <SID>UpdateMailbox()<CR> 
noremap <silent> <buffer> r :call <SID>refresh_message_list()<CR> 

1 wincmd w
autocmd CursorMoved <buffer> call <SID>ListMessages()
noremap <silent> <buffer> u :call <SID>UpdateMailbox()<CR> 
noremap <silent> <buffer> r :call <SID>refresh_message_list()<CR> 

finish


function! s:GotoMessageWindow()
  let currentbufnr = bufnr('%')
  if bufwinnr(s:messagebufnr) != -1
    wincmd w
    while bufnr('%') != s:messagebufnr && bufnr('%') != currentbufnr
      wincmd w
    endwhile
  endif
  if bufnr('%') != s:messagebufnr
    call s:CreateWindowC()
  end
endfunction
function! s:GmailVimPageMessageDown()
  call s:GotoMessageWindow()
  exe "normal \<c-f>"

endfunction

noremap <silent> <buffer> <CR> :call <SID>GmailVimShowMessage()<CR> 


noremap <silent> <buffer> <space> :call <SID>GmailVimPageMessageDown()<CR> 


