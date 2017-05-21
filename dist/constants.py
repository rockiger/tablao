import sys
from PyQt5.QtGui import QIcon
from PyQt5.QtCore import QDir
COL_HEADERS = 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z'.split()
ROWS = 99
COLS = len(COL_HEADERS)
WIDTH = 1440
HEIGHT = 800
APP_TITLE = 'Tablao'
ICON = QIcon('./icon.svg')
ACTIVEWINDOWFOCUSREASON = 3
UNTITLED_PATH = (QDir.tempPath() + '/tablao_untitled')
CLIPBOARD_MODE_CLIPBOARD = 0
CLIPBOARD_MODE_SELECTION = 1
print(sys.platform)
PREVIEWHEADER_FIRST_PART = "<!DOCTYPE html>\n     <html>\n       <head>\n         <meta charset='utf-8'>\n         <title></title>\n         <!-- Latest compiled and minified CSS -->\n         <style media='screen'>\n\n           body {\n             font-family: -apple-system, BlinkMacSystemFont,\n                           'Segoe UI', 'Source Sans Pro', 'Roboto', 'Oxygen',\n                           'Ubuntu', 'Cantarell', 'Fira Sans',\n                           'Droid Sans', 'Helvetica Neue', sans-serif;\n           }\n           table-bordered {\n               border: 1px solid #ddd;\n           }\n           table {\n               width: 100%;\n               max-width: 100%;\n               margin-bottom: 20px;\n           }\n           table {\n               background-color: transparent;\n           }\n           table {\n               border-spacing: 0;\n               border-collapse: collapse;\n           }\n\n           table>tbody>tr>td, table>tbody>tr>th, table>tfoot>tr>td, table>tfoot>tr>th, table>thead>tr>td, table>thead>tr>th {\n               border: 1px solid #ddd;\n           }\n\n           table>tbody>tr>td, table>tbody>tr>th, table>tfoot>tr>td, table>tfoot>tr>th, table>thead>tr>td, table>thead>tr>th {\n               padding: 5px;\n               line-height: 1.42857143;\n               vertical-align: top;\n               border-top: 1px solid #ddd;\n           }\n\n           th {\n               text-align: left;\n           }\n           "
PREVIEWHEADER_BREEZE_SCROLLBAR_STYLE = ('\n           ::-webkit-scrollbar\n            {\n            \tbackground: #eff0f1;\n            \twidth: 6px;\n            \theight: 6px;\n            }\n\n            ::-webkit-scrollbar-button\n            {\n            \twidth: 0px;\n            \theight: 0px;\n            }\n\n            ::-webkit-scrollbar-thumb\n            {\n            \tbackground: #3DAEE9;\n            \tborder-radius: 50px;\n            }\n\n            ::-webkit-scrollbar-thumb:hover, ::-webkit-scrollbar-thumb:window-inactive:hover\n            {\n              \tbackground: #93cee9;\n            }\n\n            ::-webkit-scrollbar-track\n            {\n            \tbackground: #eff0f1;\n            \tborder-radius: 50px;\n            }\n\n            ::-webkit-scrollbar-track:hover\n            {\n            \tbackground: rgba(106, 110, 113, 0.3);\n            }\n\n            ::-webkit-scrollbar-corner\n            {\n              \tbackground: transparent;\n            }\n\n            ::-webkit-scrollbar-thumb:window-inactive\n            {\n            \tbackground: #909396;\n            \tborder-radius: 50px;\n            }\n            ' if ('linux' == sys.platform) else '')
PREVIEWHEADER_LAST_PART = '\n         </style>\n       </head>\n       <body>\n       '
PREVIEWHEADER = ((PREVIEWHEADER_FIRST_PART + PREVIEWHEADER_BREEZE_SCROLLBAR_STYLE) + PREVIEWHEADER_LAST_PART)
PREVIEWFOOTER = '  </body>\n      </html>'
