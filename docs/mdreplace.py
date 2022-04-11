import time
from lcdoc.mkdocs.replace import css

# fmt:off
table = {
    ':head:'        :  css.fullwidth,
    'bash'        :  ':material-bash:',
    'chrome'      :  ':fontawesome-brands-chrome:',
    'cloud'       :  ':material-cloud-tags:',
    'ctime'       :  time.strftime('%a, %d %b %Y %Hh GMT', time.localtime()),
    'fe'          :  ':material-language-html5:',  # frontend
    'fences:all:' :  '```',
    'gh'          :  ':material-github:',
    'github'      :  ':material-github:',
    'iot'         :  ':material-z-wave:',
    'img'         :  ':material-image-edit:',
    'linux'       :  ':fontawesome-brands-linux:',
    'mkdocs'      :  ':material-language-markdown-outline:',
    'py'          :  ':material-language-python:',
    'python'      :  ':material-language-python:',
    'terminal'    :  ':octicons-terminal-24:',
    'tv'    :  ':fontawesome-solid-tv:',
    'vi'          :  ':fontawesome-brands-vimeo-v:',
    'vim'         :  ':fontawesome-brands-vimeo-v:',
    'web'         :  ':material-web:',
    'yt'         :  ':fontawesome-brands-youtube:',

}
# fmt:on
