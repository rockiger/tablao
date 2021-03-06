#! /usr/bin/env hy

(import [os]
        [csv]
        [helper [*]]
        [constants [*]]
        [globals [*]]
        [ext [htmlExport]]
        [commands [Command-Paste Command-Delete Command-Cell-Edit]]
        [PyQt5.QtWidgets [QTableWidget QTableWidgetItem QFileDialog QAction
                          QTableWidgetSelectionRange QUndoStack QUndoCommand]]
        [PyQt5.QtCore [QEvent Qt]])

;; =================
;; Objects
;; =================

(defclass Table [QTableWidget]
  (defn --init-- [self r c set_title]
      (.--init-- (super) r c)
      (setv self.set_title set_title
            self.check_change True
            self.header_bold False

            ;; undo/redo
            self.undo-stack (QUndoStack self))

      (.init-cells self)
      (.init_ui self)
      (.installEventFilter self self)
      (.init-undo-cell-edits self))

  (defn init-cells [self]
    (for [row (range (.rowCount self))]
      (for [col (range (.columnCount self))]
        (when (= (.item self row col) None)
          (.setItem self row col (QTableWidgetItem))))))

  (defn init_ui [self]
    ;(.connect self.cellChanged self.c_current)
    (.connect self.cellChanged self.update_preview)
    (.connect self.cellChanged self.set_changed)
    (.connect self.cellChanged (fn []
                                (if (get globals "header")
                                  (.set_header_style self True))))
    (.connect self.cellChanged self.on-cell-changed)
    (.connect self.itemSelectionChanged self.set_selection)
    (.connect self.cellActivated (fn [] (log "CELLACTIVATED")))
    (.show self))

  ;; =======================
  ;; START undo-cell-edits
  ;; =======================
  (defn init-undo-cell-edits [self]
    "undo/redo of edits
    The whole thing is very complicated and dirty, because we can't
    use the standard way of using the QUndoCommand.
    We use 2 state variables, one that carries the current cell content
    and one that determines, if the current cell was changed.
    Every time we enter a cell, the content is written to open-editor-content
    and open-editor-content-changed is set to False. This is done in
    reimplemented function self.edit. If the user changes the cell content
    on-cell-changed is called and sets self.open-editor-content-changed
    to true. When the user leaves the cell self.closeEditor is called.
    If self.open-editor-content-changed is True it creates a QUndoCommand."

    ;; TODO find a better way for that :)
    (setv
      self.open-editor-content
      {:old "" :new "" :row 0 :col 0} ; {:text Str :row Int :col Int}
      self.open-editor-content-changed False))

  (defn edit [self index tmp1 tmp2]
    (log "OPENEDITOR")
    (setv item (.currentItem self)
          txt (if item (.text item) "")
          self.open-editor-content
          {:old txt :row (.currentRow self) :col (.currentColumn self)}
          self.open-editor-content-changed False)
    (.edit QTableWidget self index tmp1 tmp2))

  (defn on-cell-changed [self row col]
    (log "OnCELLCHANGED")
    (setv self.open-editor-content-changed True
          (:new self.open-editor-content)
          (-> self
              (.item (:row self.open-editor-content) (:col self.open-editor-content))
              .text))
    (debug self.open-editor-content))

  (defn closeEditor [self editor hint]
    (log "CLOSEPERSISTANTEDITOR")
    (when self.open-editor-content-changed
      (log "DO EDIT-COMMAND")
      (setv command (Command-Cell-Edit self self.open-editor-content "Edit Cell"))
      (.push self.undo-stack command))
    (.closeEditor QTableWidget self editor hint))

  ;; =======================
  ;; END undo-cell-edits
  ;; =======================

  (defn range-content [self selection-range]
    (setv rows [])
    (for [row (range (.topRow selection-range) (inc (.bottomRow selection-range)))]
      (setv cols [])
      (for [col (range (.leftColumn selection-range) (inc (.rightColumn selection-range)))]
        (setv item (.item self row col))
        (.append cols item))
      (.append rows cols))
    rows)

  (defn undo [self]
    "Undo changes to table"
    (log "UNDO")
    ;; TODO set menu for undo and redo
    (.undo self.undo-stack))

  (defn redo [self]
    "Redo changes to table"
    (log "REDO")
    ;; TODO set menu for undo and redo
    (.redo self.undo-stack))

  (defn set_selection [self]
    "Void -> Void
    Inserts the selection to the primary clipboard. http://doc.qt.io/qt-5/qclipboard.html#Mode-enum"
    (when (pos? (.selectionMode self))
      (.copy-selection self :clipboard-mode *clipboard-mode-selection*)))

  (defn paste [self &key {clipboard-mode *clipboard-mode-clipboard*}]
    "Void (Enum(0-2)) -> Void
    Inserts the clipboard, at the upper left corner of the current selection"
    (if (> (len (.selectedRanges self)) 1)
      (log "WARNING: Paste only works on first selection"))
    (setv r (first (.selectedRanges self)))
    (setv paste-list (.parse-for-paste self (first (.text (get globals "clipboard") "plain" clipboard-mode))))
    (if (= r None)
      (do
        (setv start-row (.currentRow self))
        (setv start-col (.currentColumn self)))
      (do
        (setv start-col (.leftColumn r))
        (setv start-row (.topRow r))))
    (setv command (Command-Paste self start-row start-col paste-list "Paste"))
    (.push self.undo-stack command))

  (defn copy-selection [self &key {clipboard-mode *clipboard-mode-clipboard*}]
    "Int(0,2) -> Void
    Copies the current selection to the clipboard. Depending on the clipboard-mode to define which clipboard system is used
    QClipboard::Clipboard	0	indicates that data should be stored and retrieved from the global clipboard.
    QClipboard::Selection	1	indicates that data should be stored and retrieved from the global mouse selection. Support for Selection is provided only on systems with a global mouse selection (e.g. X11).
    QClipboard::FindBuffer	2	indicates that data should be stored and retrieved from the Find buffer. This mode is used for holding search strings on macOS.
    http://doc.qt.io/qt-5/qclipboard.html#Mode-enum"
    (if (> (len (.selectedRanges self)) 1)
      (log "WARNING: Copy only works on first selection"))
    (setv r (first (.selectedRanges self)))
    (setv copy-content "")
    (try
      (do
        (for [row (range (.topRow r) (inc (.bottomRow r)))]
          (for [col (range (.leftColumn r) (inc (.rightColumn r)))]
            (setv item (.item self row col))
            (when (!= item None)
              (setv copy-content (+ copy-content (.text item)))
              (if-not (= col (.rightColumn r))
                (setv copy-content (+ copy-content "\t")))))
          (if-not (= row (.bottomRow r))
            (setv copy-content (+ copy-content "\n"))))
        (.setText (get globals "clipboard") copy-content clipboard-mode))
      (except [e AttributeError]
        (log "WARING: No selection available"))))

  (defn delete-selection [self]
    "Void -> Void
    Deletes the current selection."
    (log "DELETE-SELECTION")
    (setv command (Command-Delete self "Delete"))
    (.push self.undo-stack command))

  (defn cut-selection [self]
    (.copy-selection self)
    (.delete-selection self))

  (defn c_current [self]
    (when self.check_change
        (setv row (.currentRow self)
              col (.currentColumn self)
              value (try
                      (.text (.item self row col))
                      (except [e AttributeError] "")))
        (log "The current cell is " row " " col)
        (log "In this cell we have: " value)))

  (defn update_preview [self]
    (if self.check_change
      (.setHtml (get globals "webview") (htmlExport.create_preview self (get globals "header") *previewHeader* *previewFooter*))))

  (defn new_sheet [self]
    (if (and (= (get globals "filepath") *untitled_path*)
             (pos? (.used_row_count self)))
      (.save_sheet_csv self)
      (.save_sheet_csv self (get globals "filepath")))
    (reset! globals "filepath" *untitled_path*)
    (.clear self)
    (.save_sheet_csv self (get globals "filepath"))
    (.clear self.undo-stack)
    (.update_preview self))

  (defn open_sheet [self &optional defpath]
    (.blockSignals self True)
    (setv path
          (if defpath ; if defpath is not none, it mean we don't need to ask for a path
            [defpath] ; put defpath in a dict, to simulate QFileDialog
            (.getOpenFileName QFileDialog self "Open CSV"
                                  (.getenv os "Home") "CSV(*.csv)")))
    (reset! globals "filepath" (first path))
    (setv self.check_change False)
    (if (!= (first path) "")
      (with [csv_file (open (first path) "r" :newline "")]
        (.setRowCount self 0)
        (setv my_file (.reader csv csv_file :dialect "excel"))
        (for [row_data my_file]
          (setv row (.rowCount self))
          (.insertRow self row)
          (if (> (len row_data) *cols*)
              (.setColumnCount self (len row_data)))
          (for [[column stuff] (enumerate row_data)]
            (setv item (QTableWidgetItem stuff))
            (.setItem self row column item)))
        (.setRowCount self *rows*)))
    (.init-cells self)
    ;; set style for table header, if header is activated
    (if (get globals "header") (.set_header_style self True))
    (debug (.used_row_count self))
    (setv self.check_change True)
    (reset! globals "filechanged" False)
    (.set_title self)
    (.update_preview self)
    (.clear self.undo-stack)
    (.blockSignals self False))
    ;; TODO reset redo-stack

  (defn save_sheet_csv [self &optional defpath]
    (setv path
          (if defpath ; if defpath is not none, it mean we don't need to ask for a path
            [defpath] ; put defpath in a dict, to simulate QFileDialog
            (.getSaveFileName QFileDialog self "Save CSV"
                                 (.getenv os "Home") "CSV(*.csv)")))
    (if (!= (first path) "")
      (with [csv_file (open (first path) "w" :newline "")]
        (setv writer (.writer csv csv_file :dialect "excel"))
        (for [row (range (inc (.used_row_count self)))]
          (setv row_data [])
          (for [col (range (inc (.used_column_count self)))]
            (setv item (.item self row col))
            (if (!= item None)
              (.append row_data (.text item))
              (.append row_data "")))
          (.writerow writer row_data))))
    (reset! globals "filepath" (first path))
    (reset! globals "filechanged" False)
    (.set_title self))

  (defn save_sheet_html [self]
    (setv path (.getSaveFileName QFileDialog self "Save HTML"
                                 (.getenv os "Home") "HTML(*.html)"))
    (if (!= (first path) "")
      (with [file (open (first path) "w")]
        (.write file (htmlExport.qtable-to-html self (get globals "header")))
        (.close file))))

  (defn used_column_count [self]
    "Returns the number of the last column with content, starts with 0 if none is used"
    (setv ucc 0)
    (for [r (range (.rowCount self))]
      (for [c (range (.columnCount self))]
        (setv item (.item self r c))
        (if (and (!= item None)
                 (pos? (len (.text item)))
                 (>= c ucc))
          (setv ucc (inc c)))))
    ucc)

  (defn used_row_count [self]
    "Returns the number of the last row with content, starts with 0 if none is used"
    (setv urc 0)
    (for [r (range (.rowCount self))]
      (for [c (range (.columnCount self))]
        (setv item (.item self r c))
        (if (and (!= item None)
                 (pos? (len (.text item)))
                 (>= r urc))
          (setv urc (inc r)))))
    urc)

  (defn set_header_style [self bold]
    "Bool -> Bool
     Consumes the if style of header is bold or not
     returns global state"
    (for [col (range (.columnCount self))]
     (setv item (.item self 0 col))
     (when (!= item None)
       (setv font (.font item))
       (.setBold font bold)
       (.setFont item font)))
    globals)

  (defn eventFilter [self object ev]
    (when (and (= (.type ev) QEvent.FocusOut) (= (.reason ev) *ActiveWindowFocusReason*))
      (debug "QtCore.QEvent.FocusOut")
      (debug (.lostFocus ev))
      (debug (.reason ev))
      (.on_focus_lost self ev))
    False)

  (defn on_focus_lost [self ev]
    (.save_sheet_csv self (get globals "filepath"))
    (.set_title self))

  (defn set_changed [self]
    (reset! globals "filechanged" True)
    (.set_title self)
    (log "set_changed"))

  (defn clear [self]
    (.blockSignals self True)
    ;(.setRowCount self 0)
    ;(.setRowCount self *rows*)))
    (.clearContents self)
    (.init-cells self)
    (.blockSignals self False))

  (defn parse-for-paste [self clipboard-text]
    "String -> List[][]
    Consumes a String clipboard-text and produces a 2-dimensional list with
    lines and columns. Example:
    'Test\tTest\tTest\n1\t1\t2\t3' -> [['Test', 'Test', 'Test'], ['1', '2', '3']]"
    (setv paste-list [])
    (setv row [])
    (setv lns (.split (.strip clipboard-text) "\n"))
    (debug lns)
    (for [ln lns]
      (debug ln)
      (.append paste-list (.split ln "\t")))
    paste-list)

  (defn map-paste-list [self lst start-row start-col func]
    "list function -> Void
    Cycles through a paste-list and uses function func on each cell"
    (setv pl-rnr 0) ; row number in the paste-list
    (for [row (range start-row (+ start-row (len lst)))]
      (setv pl-cnr 0) ; col number in the paste-list
      (for [col (range start-col (+ start-col (len (get lst pl-rnr))))]
        (.blockSignals self True)
        (func lst pl-rnr pl-cnr row col)
        (.blockSignals self False)
        (setv pl-cnr (inc pl-cnr)))
      (.update_preview self)
      (.set_changed self)
      (setv pl-rnr (inc pl-rnr)))))
