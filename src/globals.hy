#! /usr/bin/env hy

(import [PyQt5.QtCore [QSettings]])

;; ==================
;; Global State
;; ==================

(def globals {"header" true
              "settings" (QSettings "Rockiger" "Tablao")
              "filepath" ""
              "filechanged" false})

;; ==============
;; Functions
;; ==============

(defn reset! [state key new_value]
  "Dict String Object -> Dict
   Consumes a state dictionary, a key and the new value for that key.
   Returns the new state object"
  (setv (get state key) new_value)
  state)
