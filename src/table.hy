#! /usr/bin/env hy

(import [os]
        [csv]
        [constants [*]]
        [globals [*]]
        [ext [htmlExport]]
        [PyQt5.QtWidgets [QTableWidget QTableWidgetItem QFileDialog QAction
                          QTableWidgetSelectionRange]]
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


            self.current-cell-content None
            self.last-edit-content None
            self.history []
            self.hist-counter -1
            self.future [])
      (.init_ui self)
      (.installEventFilter self self))

  (defn init_ui [self]
    (.connect self.cellChanged self.c_current)
    (.connect self.cellChanged self.update_preview)
    (.connect self.cellChanged self.set_changed)
    (.connect self.cellChanged (fn []
                                (if (get globals "header")
                                  (.set_header_style self True))))
    (.connect self.itemSelectionChanged self.set_selection)
    (.connect self.cellChanged self.on-cell-changed)
    (.connect self.currentCellChanged self.push-current-cell-content)
    (.show self))

  ;; Undo
  ;; * check for currentItemChanged -> put on undo stack
  ;; * onDelete -> blockSignals -> delete -> put whole delete on undo stack
  ;;   -> blockSignals false
  ;; * onPaste -> blockSignals -> paste -> put whole paste on undo stack
  ;;   -> blockSignals False
  ;; * onloadFile or New File -> create new undoStack or clear undoStack
  ;; history record is a dict {:cells :range}

  (defn on-cell-changed [self row col]
    (print "OnCELLCHANGED")
    (.push-history self (QTableWidgetSelectionRange row col row col)))
    ;; TODO

  (defn range-content [self selection-range]
    (setv rows [])
    (for [row (range (.topRow selection-range) (inc (.bottomRow selection-range)))]
      (setv cols [])
      (for [col (range (.leftColumn selection-range) (inc (.rightColumn selection-range)))]
        (setv item (.item self row col))
        (.append cols item))
      (.append rows cols))
    rows)

  (defn push-timeline [self selection-range timeline]
    (setv cells (.range-content self selection-range))
    (print "CELLS:" cells)
    (print (first (first cells)))
    (when (and (= (len cells) 1) (= (len (first cells)) 1))
      (setv cells [[self.current-cell-content]]))
    (.append timeline {:cells cells :range selection-range}) ; range of cells
    (setv self.hist-counter (inc self.hist-counter))
    (print "HISTORY: " self.history)
    (print "HIST-COUNTER: " self.hist-counter)
    (.push-current-cell-content self (.currentRow self) (.currentColumn self)))

  (defn push-history [self selection-range]
    (.push-timeline self selection-range self.history))

  (defn push-future [self selection-range]
    (setv cells (.range-content self selection-range))
    (print "SELECTION-RANGE: " selection-range)
    (when (and (= (len cells) 1) (= (len (first cells)) 1))
      (setv cells [[(.text (first (first cells)))]]))
    (.append self.future {:cells cells
                          :range selection-range})

    (.push-current-cell-content self (.currentRow self) (.currentColumn self)))

  (defn push-current-cell-content [self row col]
    (print "push-current-cell-content")
    (setv ccl (.item self row col))
    (if ccl ; set text of current if any, or None
      (setv self.current-cell-content (.text ccl))
      (setv self.current-cell-content ccl))
    (print self.current-cell-content))

  (defn set-cells-from-time-entry [self time-entry]
    "Consumes an Entry from the time-line (history or future) and
    set this entry as the current state of the table."
    (.blockSignals self True)
    (setv cells (get time-entry :cells))
    (setv top-row (.topRow (get time-entry :range)))
    (setv bottom-row (.bottomRow (get time-entry :range)))
    (setv left-col (.leftColumn (get time-entry :range)))
    (setv right-col (.rightColumn (get time-entry :range)))
    (setv row-count (.rowCount (get time-entry :range)))
    (setv col-count (.columnCount (get time-entry :range)))
    (setv i 0)
    (for [row (range top-row (+ top-row row-count))]
      (setv j 0)
      (for [col (range left-col (+ left-col col-count))]
        (setv cell (get (get cells j) i))
        (setv item (QTableWidgetItem cell))
        (.setItem self row col item)
        (setv j (inc j)))
      (setv i (inc i)))
    (.blockSignals self False))

  (defn undo [self]
    "Undo changes to table"
    (print "UNDO")
    ;(print self.history)
    (setv hist-entry (get self.history self.hist-counter))
    (print hist-entry)
    (.set-cells-from-time-entry self hist-entry)
    (setv self.hist-counter (dec self.hist-counter))
    (print "FUTURE: " self.history)
    (print "HIST-Counter: " self.hist-counter))
    ;; TODO set menu for undo and redo

  (defn redo [self]
    "Redo changes to table"
    (print "REDO"))

  (defn set_selection [self]
    "Void -> Void
    Inserts the selection to the primary clipboard. http://doc.qt.io/qt-5/qclipboard.html#Mode-enum"
    (when (pos? (.selectionMode self))
      (.copy-selection self :clipboard-mode *clipboard-mode-selection*)))

  (defn paste [self &key {clipboard-mode *clipboard-mode-clipboard*}]
    "Void (Enum(0-2)) -> Void
    Inserts the clipboard, at the upper left corner of the current selection"
    (if (> (len (.selectedRanges self)) 1)
      (print "WARNING: Paste only works on first selection"))
    (setv r (first (.selectedRanges self)))
    (setv paste-list (.parse-for-paste self (first (.text (get globals "clipboard") "plain" clipboard-mode))))
    (if (= r None)
      (do
        (setv start-row (.currentRow self))
        (setv start-col (.currentColumn self)))
      (do
        (setv start-col (.leftColumn r))
        (setv start-row (.topRow r))))
    (setv pl-rnr 0)
    (for [row (range start-row (+ start-row (len paste-list)))]
      (setv pl-cnr 0)
      (for [col (range start-col (+ start-col (len (get paste-list pl-rnr))))]
        (setv item (QTableWidgetItem (get (get paste-list pl-rnr) pl-cnr)))
        (.setItem self row col item)
        (setv pl-cnr (inc pl-cnr)))
      (setv pl-rnr (inc pl-rnr))))

  (defn copy-selection [self &key {clipboard-mode *clipboard-mode-clipboard*}]
    "Int(0,2) -> Void
    Copies the current selection to the clipboard. Depending on the clipboard-mode to define which clipboard system is used
    QClipboard::Clipboard	0	indicates that data should be stored and retrieved from the global clipboard.
    QClipboard::Selection	1	indicates that data should be stored and retrieved from the global mouse selection. Support for Selection is provided only on systems with a global mouse selection (e.g. X11).
    QClipboard::FindBuffer	2	indicates that data should be stored and retrieved from the Find buffer. This mode is used for holding search strings on macOS.
    http://doc.qt.io/qt-5/qclipboard.html#Mode-enum"
    (if (> (len (.selectedRanges self)) 1)
      (print "WARNING: Copy only works on first selection"))
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
        (print "WARING: No selection available"))))

  (defn delete-selection [self]
    "Void -> Void
    Deletes the current selection."
    (print "DELETE-SELECTION")
    (for [item (.selectedItems self)]
      (.setText item "")))

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
        (print "The current cell is " row " " col)
        (print "In this cell we have: " value)))

  (defn update_preview [self]
    (if self.check_change
      (.setHtml (get globals "webview") (htmlExport.->preview self (get globals "header") *previewHeader* *previewFooter*))))

  (defn new_sheet [self]
    (if (and (= (get globals "filepath") *untitled_path*)
             (pos? (.used_row_count self)))
      (.save_sheet_csv self)
      (.save_sheet_csv self (get globals "filepath")))
    (reset! globals "filepath" *untitled_path*)
    (.clear self)
    (.save_sheet_csv self (get globals "filepath"))
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
      (with [csv_file (open (first path) :newline "")]
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
    ;; set style for table header, if header is activated
    (if (get globals "header") (.set_header_style self True))
    ;(print (.used_row_count self))
    (setv self.check_change True)
    (reset! globals "filechanged" False)
    (.set_title self)
    (.update_preview self)
    (.blockSignals self False))

  (defn save_sheet_csv [self &optional defpath]
    (setv path
          (if defpath ; if defpath is not none, it mean we don't need to ask for a path
            [defpath] ; put defpath in a dict, to simulate QFileDialog
            (.getSaveFileName QFileDialog self "Save CSV"
                                 (.getenv os "Home") "CSV(*.csv)")))
    (if (!= (first path) "")
      (with [csv_file (open (first path) "w")]
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
        (.write file (htmlExport.qtable->html self (get globals "header")))
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
      (print "QtCore.QEvent.FocusOut")
      (print (.lostFocus ev))
      (print (.reason ev))
      (.on_focus_lost self ev))
    False)

  (defn on_focus_lost [self ev]
    (.save_sheet_csv self (get globals "filepath"))
    (.set_title self))

  (defn set_changed [self]
    (reset! globals "filechanged" True)
    (.set_title self)
    (print "set_changed"))

  (defn clear [self]
    ;(.setRowCount self 0)
    ;(.setRowCount self *rows*)))
    (.clearContents self))

  (defn parse-for-paste [self clipboard-text]
    "String -> List[][]
    Consumes a String clipboard-text and produces a 2-dimensional list with
    lines and columns. Example:
    'Test\tTest\tTest\n1\t1\t2\t3' -> [['Test', 'Test', 'Test'], ['1', '2', '3']]"
    (setv paste-list [])
    (setv row [])
    (setv lns (.split (.strip clipboard-text) "\n"))
    (print lns)
    (for [ln lns]
      (print ln)
      (.append paste-list (.split ln "\t")))
    paste-list))



  ;; BUG This primary clipboard is not working as it should, feature suspended
  ; (defn mousePressEvent [self event]
  ;   (when (= (.button event) Qt.MidButton)
  ;     (print "PASTE")
  ;     (setv item (.itemAt self (.pos event)))
  ;     (setv tmp (.selectionMode self))
  ;     (.setSelectionMode self 0)
  ;     (.setCurrentItem self item)
  ;     (.paste self *clipboard-mode-selection*)
  ;     (.setSelectionMode self tmp)
  ;     (print (.itemAt self (.pos event))))
  ;   (.mousePressEvent (super) event))
