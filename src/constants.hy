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
