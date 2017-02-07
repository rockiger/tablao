#! /usr/bin/env hy

(import [PyQt5.QtGui [QIcon]])

;; ============
;; Constants
;; ============
(def *col_headers* (.split "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"))
(def *rows* 99)
(def *cols* (len *col_headers*))
(def *width* 1200)
(def *height* 800)
(def *app_title* "Tablao")
(def *icon* (QIcon "../icon.svg"))
(def *ActiveWindowFocusReason* 3)
(def *untitled_path* "/tmp/tablao_untitled")
(def *previewHeader*
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
         </style>
       </head>
       <body>
       ")
(def *previewFooter*
     "  </body>
      </html>")
