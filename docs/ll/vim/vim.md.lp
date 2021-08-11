# (Neo)Vim

After a few intense rounds with emacs and vscode I'm back to vim, specifically NeoVim.

For publishing papers I'd stick to doom emacs and org -> latex -> pdf, but for the rest I'm in vim.

There are two game changers why I think: vim is not "better" than emacs - but there are no killer
features for normal text editing left, available only in emacs.

## Game Changers


### [fzf-vim](https://github.com/junegunn/fzf.vim)
![](img/fzf1.gif)
![](img/fzf2.gif)

fzf really simplifies tons of operations involving lists: Matching files, commits, colorschemes,
buffers, ripgrep results, whatever - it all is now at your fingertips in a convenient, lighting fast, fuzzy finding interface.

Meanwhile there is an alternative with Telescope - but for me FZF is still the better working tool.
Battle proven.

### [Lua](https://github.com/nanotee/nvim-lua-guide)

The big plus for emacs was that elisp >> vimscript. But now with lua that changed. We have a real
programming language now and integration with vim is first class!

## Hacks

I won't discuss all my config, just a few hacks of myself, maybe of interest to others.

### Python

```bash lp assert=except
bat -f --terminal-width=200 ~/.config/nvim/ftplugin/python.vim
```

Wrapping of code into try except blocks:
![](img/commae.gif)


### [(AX)Black](https://pypi.org/project/axblack/)

Simple running [axblack](https://pypi.org/project/axblack/) as external program on the current buffer, e.g. at save (`,w`) has a big
downside: All your jump marks are gone.

First I solved this by using [efm-lsp](https://github.com/mattn/efm-langserver) and [Lukas Reineke's approach](https://www.reddit.com/r/neovim/comments/jvisg5/lets_talk_formatting_again/).

But I found that [NeoFormat](https://github.com/sbdchd/neoformat) does the job quite well, they trick nvim into a line by line mode when
formatting - so all marks are preserved and single-transaction undos can also be made working via a
modified undojoin:

```lua
--vim.cmd [[autocmd BufWritePre * undojoin | Neoformat]] --but https://github.com/sbdchd/neoformat/issues/134
vim.cmd [[ au BufWritePre * try | undojoin | Neoformat | catch /^Vim\%((\a\+)\)\=:E790/ | finally | silent Neoformat | endtry ]]
```

Here I set a mark (`b`), show LSP completion, then write a double quoted value. Then reformat (on save), then jump back to the mark. Then I undo all
transactions:

![](img/black.gif)


Neoformat's approach also works for other language formatters, clear. See their [list](https://github.com/sbdchd/neoformat) of supported
formatters.

### Useful(?) in General

#### Color Picker

This is my version - scans all available colorschemes and toggles transparency as well:

![](img/colorpick.gif)

When set as default it writes a file which is sourced by `init.vim`.

```bash lp
bat -f  /home/gk/.config/nvim/lua/colorpicker.lua
```


#### Smart Goto

Example use case: We want to open the preprocessing source files for markdown, as soon as `,g` is
invoked on a link to its rendering result, e.g. in `mkdocs.yml`'s nav section. The file can be anywhere in the whole subtree, i.e. in
the docs folder...

When the selection is URL or a file not findable in the subtree we open in the browser:

![](img/smartgoto.gif)

- Cursor over word or visual selection
- `,g` => open in nvim or browser

!!! note "Functioning"

    Result: A python script gets the word under cursor or visual selection and can decide if to open the
    word as a new vim buffer or send it to the browser as URL or as google search string.

That can naturally be all done in lua but I wanted to quickly change the decisioning process - and
I'm not fit enough in lua to do that on the fly.

So there is the following lua python integration: In lua we use the vim api to get the current word
/ URL or vis selection, write that to a file, syncronously call a python  subprocess and read back
what it wrote into that file, than open it in vim. If there was nothing written, then we do nothing.
The latter happens, when python already calls the browser.


=== "vim hotkey"
    ```vim
    " Universal scriptable file or browser opener over word:
    nmap ,g viW"ay:lua require('utils').smart_open([[<C-R>a]])<CR><CR>
    vmap ,g :lua require('utils').smart_open([[visualsel]])<CR><CR>
    ```


=== "LUA"
    ```lua

    local function visual_selection_range()
        local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
        local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
        if csrow < cerow or (csrow == cerow and cscol <= cecol) then
            return csrow - 1, cscol - 1, cerow - 1, cecol
        else
            return cerow - 1, cecol - 1, csrow - 1, cscol
        end
    end

    M.smart_open = function(arg)
        -- gf opens anything openable. Calls a python app, which writes back if vim should open it
        -- we have a vmap of ,g to this with arg "visualsel" -> get that selection from the buffer:
        if arg == "visualsel" then
            local csrow, cscol, cerow, cecol = visual_selection_range()
            local l = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), csrow, csrow + 1, true)
            arg = l[1]
            arg = arg:sub(cscol, cecol)
        end
        local fn = "/tmp/smartopen"
        local file = io.open(fn, "w")
        io.output(file)
        io.write(arg)
        io.close(file)
        os.execute(os.getenv("HOME") .. "/.config/nvim/smart_vi_open")

        --local pth = arg --:gsub('"', "")
        --pth = pth:gsub("'", "")
        --pth = string.gsub(pth, "'", "")
        file = io.open(fn, "r")
        if file ~= nil then
            io.input(file)
            local s = io.read()
            io.close(file)
            os.execute("notify-send 'vi: " .. s .. "'")
            vim.cmd("edit " .. s)
        end
        return ""
    end
    ```

=== "Python"
    ```python lp mode=show_file fn=/home/gk/.config/nvim/smart_vi_open


    ```

Other use case:

When the word under cursor is "foo/bar" we search github for a repo and open in browser:

![](img/smartgoto2.gif)


## Favorite Plugins


| Tool | What
| - | -
| [folke/which-key.nvim](https://github.com/folke/which-key.nvim)                                                 | Absolutely amazing tool. Shows me all possible keybindings. Closes a huge gap to emacs.                                                    
| [voldikss/vim-floatterm](https://github.com/voldikss/vim-floaterm)                                              | Shell integration key.
| [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)                                             | Current Plugin Manager. Not sure if better than vim-plug. But as good.                                                 
| [liuchengxu/vista.vim](https://github.com/liuchengxu/vista.vim)                                                 | View and search LSP symbols, tags in Vim/NeoVim.                                                                       
| [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)                                               | LSP default, no more coc. Coc was good though.                                                                         
| [sbdchd/neoformat](https://github.com/sbdchd/neoformat)                                                         | Formatting via external tools but w/o breaking marks                                                                   
| [glepnir/lspsaga.nvim](https://github.com/glepnir/lspsaga.nvim)                                                 | LSP Features like rename and reference lookups                                                                         
| [nvim-treesitter/nvim-treesitter-refactor](https://github.com/nvim-treesitter/nvim-treesitter-refactor)         | --shows current scope usages and can rename symbol in buffer Not in use, breaks sometimes indentation. Waiting for fix.
| [vijaymarupudi/nvim-fzf](https://github.com/vijaymarupudi/nvim-fzf)                                             | --lua bindings.                                                                                                        
| [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim)                                               | lazygit integration                                                                                                    
| [tpope/vim-commentary](https://github.com/tpope/vim-commentary)                                                 |                                                                                                                        
| [tpope/vim-rhubarb](https://github.com/tpope/vim-rhubarb)                                                       | -- :Gbrowse -> open browser in current gh repo. also autocompletes issues ...                                          
| [tpope/vim-surround](https://github.com/tpope/vim-surround)                                                     | -- ysiw* -> foo -> *foo*                                                                                               
| [tpope/vim-repeat](https://github.com/tpope/vim-repeat)                                                         |                                                                                                                        
| [tpope/vim-eunuch](https://github.com/tpope/vim-eunuch)                                                         | --:Rename  :Move  :Delete                                                                                              
| [tpope/vim-obsession](https://github.com/tpope/vim-obsession)                                                   | -- :mksession                                                                                                          
| [tpope/vim-sleuth](https://github.com/tpope/vim-sleuth)                                                         | -- automatically adjusts 'shiftwidth' and 'expandtab' heuristically based on the current file,                         
| [krisajenkins/vim-projectlocal](https://github.com/krisajenkins/vim-projectlocal)                               | --project local .vimrc files                                                                                           
| [godlygeek/tabular](https://github.com/godlygeek/tabular)                                                       | Smart alignment                                                                                                        
| [dense-analysis/ale](https://github.com/dense-analysis/ale)                                                     | currently mainly for bash scripting, overwhelming in python, while coding                                              
| [folke/trouble.nvim](https://github.com/folke/trouble.nvim)                                                     | Fix all troubled code places.                                                                                          
| [folke/lsp-colors.nvim](https://github.com/folke/lsp-colors.nvim)                                               | Tons of new colors for LSP related situations                                                                          
| [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)                                 | Real time markdown previewer                                                                                           
| [farmergreg/vim-lastplace](https://github.com/farmergreg/vim-lastplace)                                         | Stores last edit location perfectly                                                                                    
Here all plugins in my nvim:



```bash lp lock_page
bat -f --terminal-width=200 /home/gk/.config/nvim/lua/plugins.lua
```




----
