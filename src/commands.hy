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

(defclass Command-Delete [QUndoCommand]
  (defn --init-- [self table description]
    (.--init-- (super Command-Delete self) description)
    (setv self.table table)
    (.gather-undo-information self))

  (defn redo [self]
    (for [item (.selectedItems self.table)]
      (.blockSignals self.table True)
      (.setText item "")
      (.blockSignals self.table True)
      (.update_preview self.table)
      (.set_changed self.table)))

  (defn undo [self]
    (for [r self.undo-ranges]
      (.map-paste-list self.table (:undo-list r) (:start-row r) (:start-col r)
        (fn [lst pl-rnr pl-cnr row col]
          (setv val (get (get (:undo-list r) pl-rnr) pl-cnr))
          (debug val)
          (if (= val None)
            (setv item-text "")
            (setv item-text val))
          (debug item-text)
          (.setText (.item self.table row col) item-text)))))

  (defn gather-undo-information [self]
    (setv self.undo-ranges [])
    (for [r (.selectedRanges self.table)]
      (setv row-list [])
      (for [row (range (.topRow r) (inc (.bottomRow r)))]
        (setv col-list [])
        (for [col (range (.leftColumn r) (inc (.rightColumn r)))]
          (setv item (.text (.item self.table row col)))
          (.append col-list item))
        (.append row-list col-list))
      (.append self.undo-ranges
               {:undo-list row-list
                :start-row (.topRow r)
                :start-col (.leftColumn r)}))))

(defclass Command-Cell-Edit [QUndoCommand]
    (defn --init-- [self table cell description]
      (.--init-- (super Command-Cell-Edit self) description)
      (setv self.table table
            self.cell (.deepcopy copy cell)))

    (defn redo [self]
      (debug self.cell)
      (.setText (.item self.table (:row self.cell) (:col self.cell)) (:new self.cell)))

    (defn undo [self]
      (debug self.cell)
      (.setText (.item self.table (:row self.cell) (:col self.cell)) (:old self.cell))))
