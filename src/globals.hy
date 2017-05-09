#! /usr/bin/env hy

(import [PyQt5.QtCore [QSettings]])

;; ==================
;; Global State
;; ==================

(def globals {"header" True
              "preview" True
              "settings" (QSettings "Rockiger" "Tablao")
              "filepath" "./Welcome-To-Tablao.csv" ; TODO Change accordingly to location where file get's installed
              "filechanged" False
              "table" None     ; QTableWidget that holds the table
              "webview" None ; Webview for preview
              "clipboard" None
              "second-run" False})

;; ==============
;; Functions
;; ==============

(defn reset! [state key new_value]
  "Dict String Object -> Dict
   Consumes a state dictionary, a key and the new value for that key.
   Returns the new state object"
  (setv (get state key) new_value)
  state)
