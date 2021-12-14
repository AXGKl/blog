import os
import sys
import time

from lcdoc.mkdocs.tools import srcref


table = {
    'ctime': time.strftime('%a, %d %b %Y %Hh GMT', time.localtime()),
    'srcref': srcref,
}
