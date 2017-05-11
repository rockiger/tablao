#! /usr/bin/env hy

(import [sys]
        [PyQt5.QtGui [QIcon]]
        [PyQt5.QtCore [QDir]])

;; ============
;; Constants
;; ============
(def *col_headers* (.split "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"))
(def *rows* 99)
(def *cols* (len *col_headers*))
(def *width* 1440)
(def *height* 800)
(def *app_title* "Tablao")
(def *icon* (QIcon "./icon.svg"))
(def *ActiveWindowFocusReason* 3)
(def *untitled_path* (+ (QDir.tempPath) "/tablao_untitled"))
(def *clipboard-mode-clipboard* 0)
(def *clipboard-mode-selection* 1)
(print sys.platform)
(def *previewHeader-first-part*
     "<!DOCTYPE html>
     <html>
       <head>
         <meta charset='utf-8'>
         <title></title>
         <!-- Latest compiled and minified CSS -->
         <style media='screen'>

           body {
             font-family: -apple-system, BlinkMacSystemFont,
                           'Segoe UI', 'Source Sans Pro', 'Roboto', 'Oxygen',
                           'Ubuntu', 'Cantarell', 'Fira Sans',
                           'Droid Sans', 'Helvetica Neue', sans-serif;
           }
           table-bordered {
               border: 1px solid #ddd;
           }
           table {
               width: 100%;
               max-width: 100%;
               margin-bottom: 20px;
           }
           table {
               background-color: transparent;
           }
           table {
               border-spacing: 0;
               border-collapse: collapse;
           }

           table>tbody>tr>td, table>tbody>tr>th, table>tfoot>tr>td, table>tfoot>tr>th, table>thead>tr>td, table>thead>tr>th {
               border: 1px solid #ddd;
           }

           table>tbody>tr>td, table>tbody>tr>th, table>tfoot>tr>td, table>tfoot>tr>th, table>thead>tr>td, table>thead>tr>th {
               padding: 5px;
               line-height: 1.42857143;
               vertical-align: top;
               border-top: 1px solid #ddd;
           }

           th {
               text-align: left;
           }
           ")
(def *previewHeader-breeze-scrollbar-style*
        (if (= "linux" sys.platform)
           "
           ::-webkit-scrollbar
            {
            	background: #eff0f1;
            	width: 6px;
            	height: 6px;
            }

            ::-webkit-scrollbar-button
            {
            	width: 0px;
            	height: 0px;
            }

            ::-webkit-scrollbar-thumb
            {
            	background: #3DAEE9;
            	border-radius: 50px;
            }

            ::-webkit-scrollbar-thumb:hover, ::-webkit-scrollbar-thumb:window-inactive:hover
            {
              	background: #93cee9;
            }

            ::-webkit-scrollbar-track
            {
            	background: #eff0f1;
            	border-radius: 50px;
            }

            ::-webkit-scrollbar-track:hover
            {
            	background: rgba(106, 110, 113, 0.3);
            }

            ::-webkit-scrollbar-corner
            {
              	background: transparent;
            }

            ::-webkit-scrollbar-thumb:window-inactive
            {
            	background: #909396;
            	border-radius: 50px;
            }
            "
            ""))

(def *previewHeader-last-part*
         "
         </style>
       </head>
       <body>
       ")
(def *previewHeader*
  (+   *previewHeader-first-part*
       *previewHeader-breeze-scrollbar-style*
       *previewHeader-last-part*))
(def *previewFooter*
     "  </body>
      </html>")
