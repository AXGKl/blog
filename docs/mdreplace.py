import os
import sys
import time

from lcdoc.mkdocs.tools import srcref


# fmt:off
table = {
    'bash'        :  ':material-bash:',
    'chrome'      :  ':fontawesome-brands-chrome:',
    'cloud'       :  ':material-cloud-tags:',
    'ctime'       :  time.strftime('%a, %d %b %Y %Hh GMT', time.localtime()),
    'fe'          :  ':material-language-html5:',  # frontend
    'fences:all:' :  '```',
    'gh'          :  ':material-github:',
    'iot'         :  ':material-z-wave:',
    'linux'       :  ':fontawesome-brands-linux:',
    'mkdocs'      :  ':material-language-markdown-outline:',
    'py'          :  ':material-language-python:',
    'python'      :  ':material-language-python:',
    'srcref'      :  srcref,
    'terminal'    :  ':octicons-terminal-24:',
    'vi'          :  ':fontawesome-brands-vimeo-v:',
    'vim'         :  ':fontawesome-brands-vimeo-v:',
    'web'         :  ':material-web:',

}
# fmt:on
