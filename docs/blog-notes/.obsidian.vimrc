" nmap j gj
" nmap k gk
" nmap 0 :g0
nmap gj J
nmap $ :gDollar
nmap [[ :pHead
nmap ]] :nHead

set clipboard=unnamed
set tabstop=4
imap jk <Esc> 

vmap j gj
vmap k gk


exmap back obcommand app:go-back
nmap <C-[> :back
