# Markdown Presentations

Tpope's markdown-vim is integrated in neovim, here are the syntax rules: /home/gk/pds/bin/nvimfs/usr/share/nvim/runtime/syntax/markdown.vim
Example for addons: /home/gk/pds/bin/nvimfs/usr/share/nvim/runtime/syntax/lsp_markdown.vim


Better?
https://github.com/preservim/vim-markdown/blob/master/syntax/markdown.vim
or, forked: https://github.com/ixru/nvim-markdown

## Problem


WE FUCKING CANNOT CHANGE THE CHARS - EXCEPT VIA CONCEAL - BUT THEN THERE IS JUST ONE HILIGHT GROUP
(CONCEAL),
- i.e. no color control for changed chars
- only one char
- in folds it's a nightmare to get the concealed chars: https://stackoverflow.com/questions/18275527/combining-vims-fold-and-conceal-feature

In other words: We can conceal powerfully by regex. (:help conceal) or this https://github.com/alok/python-conceal/blob/master/after/syntax/python.vim

But no color control then.


https://github.com/dirkwallenstein/vim-match-control

This can color existing stuff:
https://github.com/dirkwallenstein/vim-match-control


Maybe .. don't use vim: https://github.com/d0c-s4vage/lookatme


Or Norg: https://github.com/nvim-neorg/neorg#-showcase

images?! https://github.com/edluffy/hologram.nvim

Wait:
https://github.com/nvim-zh/md-nanny
