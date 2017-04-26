#! /usr/bin/env hy

(import [copy]
        [helper [*]]
        [constants [*]]
        [globals [*]]
        [PyQt5.QtWidgets [QUndoCommand]])


;; =================
;; Objects
;; =================

(defclass Command-Paste [QUndoCommand]
  (defn --init-- [self table start-row start-col paste-list description]
    (.--init-- (super Command-Paste self) description)
    (setv self.table table
        self.start-row start-row
        self.start-col start-col
        self.paste-list (.deepcopy copy paste-list)
        self.undo-list (.deepcopy copy paste-list))
    (.gather-undo-information self))

  (defn redo [self]
    (.map-paste-list self.table self.paste-list  self.start-row self.start-col
      (fn [lst pl-rnr pl-cnr row col]
        (setv val (get (get self.paste-list pl-rnr) pl-cnr))
        (if (= val None)
          (setv item-text "")
          (setv item-text val))
        (debug item-text)
        (.setText (.item self.table row col) item-text))))

  (defn undo [self]
    (debug self.undo-list)
    (.map-paste-list self.table self.undo-list self.start-row self.start-col
      (fn [lst pl-rnr pl-cnr row col]
        (setv val (get (get self.undo-list pl-rnr) pl-cnr))
        (debug val)
        (if (= val None)
          (setv item-text "")
          (setv item-text val))
        (debug item-text)
        (.setText (.item self.table row col) item-text))))

  (defn gather-undo-information [self]
    (debug self.paste-list)
    (.map-paste-list self.table self.undo-list self.start-row self.start-col
      (fn [lst pl-rnr pl-cnr row col]
        (setv undo-row (get lst pl-rnr))
        (assoc undo-row pl-cnr (.text (.item self.table row col)))))
    (setv self.paste-list (.deepcopy copy self.paste-list))
    (log "GATHER-UNDO-INFORMATION")
    (debug self.undo-list)
    (debug self.paste-list)))
