# Awesome Apps - Not only Linux

Those I install pretty early after a distro hop or hardware replacement

I omit the usual stuff like git, htop, tmux, ripgrep, fzf ...


- [edge](https://blogs.windows.com/msedgedev/2020/10/20/microsoft-edge-dev-linux/) Pretty well
  thought through browser, actually
- [gimp](https://www.gimp.org/)
- [lazygit](https://github.com/jesseduffield/lazygit) Perfect terminal git tool. Also for vim: No
  more fugitive, just open in vim-floatterm
- [miniconda](https://docs.conda.io/en/latest/miniconda.html) Tons of disposable distro independent
  apps, not only from the python world. Default python, ruby, npm and java env wrapper, for their
  subsequent tools landscape
- [simplescreenrecorder](https://www.maartenbaert.be/simplescreenrecorder/) with 

            ffmpeg -ss 0.0 -i "$fn" -filter_complex "[0:v] fps=12,scale=760:-1,split [a][b];[a] palettegen \
                        [p];[b][p] paletteuse" $fn.gif` also for animated gifs from the recordings.

- [vimium ](https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb?hl=en)
  Drives browsing via vim keys.

  ```
    unmap h
    unmap l
    map h goBack
    map l goForward
  ```
  Alternative vim-vixen
- [z.lua](https://github.com/skywind3000/z.lua) Perfect directory jumper
- zsh: Yes. It is better, especialy completion
