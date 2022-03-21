# Astro Vim

[2022-03-20 18:58]

This weekend I tested [Astro Vim][av], which is a pretty well tuned (and good looking) LSP configuration bundle for nvim.

I like

- the idea of having

  - LSP
  - treesitter
  - telescope
  - floatterm
  - (...)

  ...out of the box, in order to throw it also on servers with colleagues and
  point them to an "official" repo with docs and stuff. Those are not easy to
  get right with so many variants.

- the full lua approach (but I'll have to have vim lang stuff, see below)
- Also, while mine became a bit laggy on big files, this one is still pretty
  fast, _with_ all the LSP goodies.

Here my notes about the conversion:

## Cleaning Up

- Backup and Remove:

  - `$HOME/.config/nvim`
  - `$HOME/.cache/nvim`
  - `$HOME/.local/share/nvim`

## Install

```
git clone https://github.com/kabinspace/AstroVim ~/.config/nvim
nvim +PackerSync # nice
```

then e.g.

```
:LspInstall pyright
:TSInstall python # treesitter
```

!!! note

    All user config is in `.config/nvim/lua/user`, from `init.lua` there.

## Conventional Folders: ftplugin and spell: Symlinked

Put my old ones into `lua/user/<ftplugin|spell>` and symlinked 2 directories up. Worked.

## Own Lua and Own Vimscript

Besides a few declarative config possibilities, for own plugins, in init.lua
there is a lua polish function, loaded at the end.

There you hook in your stuff like this:

```lua
    require('user.mymodule')
    -- and vimscript like this:
    vim.cmd('source $HOME/.config/nvim/lua/user/polish.vim')
```

and in vimscript then back to lua in user folder like this: `nmap ,g viW"ay:lua require('user.utils').smart_open([[<C-R>a]])<CR>`

## Colors

The declarative approach with colorscheme via lua failed, loading it in my .vim file at the end.

## Spell

It did not ask me to download german at `set spelllang=de`, so:

```bash
mkdir .config/nvim/spell && cd $_` && wget 'http://ftp.vim.org/pub/vim/runtime/spell/de.utf-8.spl'
```

## Telescope

- AstroVim Config: https://github.com/kabinspace/AstroVim/issues/141
- Generic Telescope Tuning: https://github-wiki-see.page/m/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes

## LSP

Pretty straight forward, via their [null_ls](https://github.com/jose-elias-alvarez/null-ls.nvim) LSP
"hub", where nvim is the direct server for all languages and calls the actual programs behind the
scenes.

That way one can pick from a [huge](./astro_vim_null_ls_builtins.md) list of features and just
install the binaries if required (`command`), done.

LSP log as always in `$HOME/.cache/nvim/`, file `null_ls.log`.

### axblack

`null_ls` calls black with their `--stdin-filename` parameter. Had to [add][axb] that to axblack so that
single quote formatting works, as a no op (not in use anyway for stdin/stdout based formatting).

[axb]: https://github.com/axiros/axblack/commit/30f19e3ae7c10dfd995bd6fb1b031000282e6af7
[av]: https://github.com/kabinspace/AstroVim
