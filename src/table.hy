#! /usr/bin/env hy

(import [os]
        [csv]
        [constants [*]]
        [globals [*]]
        [ext [htmlExport]]
        [PyQt5.QtWidgets [QTableWidget QTableWidgetItem QFileDialog]]
        [PyQt5.QtCore [QEvent]])

;; =================
;; Objects
;; =================

(defclass Table [QTableWidget]
  (defn --init-- [self r c set_title]
      (.--init-- (super) r c)
      (setv self.set_title set_title)
      (setv self.check_change True)
      (setv self.header_bold False)
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
      (.show self))

  (defn set_selection [self]
    (.copy-selection self :clipboard-mode *clipboard-mode-selection*))

  (defn copy-selection [self &key {clipboard-mode *clipboard-mode-clipboard*}]
    (print "copy-selection")
    (if (> (len (.selectedRanges self)) 1)
      (print "WARNING: Copy only work on first selection"))
    (setv r (first (.selectedRanges self)))
    (setv copy-content "")
    (for [row (range (.topRow r) (inc (.bottomRow r)))]
      (for [col (range (.leftColumn r) (inc (.rightColumn r)))]
        (setv item (.item self row col))
        (if (!= item None)
          (do
            (setv copy-content (+ copy-content (.text item)))
            (if-not (= col (.rightColumn r))
              (setv copy-content (+ copy-content "\t"))))))
      (if-not (= row (.bottomRow r))
        (setv copy-content (+ copy-content "\n"))))
    (.setText (get globals "clipboard") copy-content clipboard-mode)
    (print "clipboard mode")
    (print (. (get globals "clipboard") Clipboard))
    (print "START copy-content")
    (print copy-content)
    (print "STOP copy-content"))

  (defn c_current [self]
    (if self.check_change
        (let [row (.currentRow self)
              col (.currentColumn self)
              value (try
                      (.text (.item self row col))
                      (except [e AttributeError] ""))]
          (print "The current cell is " row " " col)
          (print "In this cell we have: " value))))

  (defn update_preview [self]
    (if self.check_change
      (.setHtml (get globals "webview") (htmlExport.->preview self (get globals "header") *previewHeader* *previewFooter*))))

  (defn new_sheet [self]
    (if (and (= (get globals "filepath") *untitled_path*)
             (> (.used_row_count self) 0))
      (.save_sheet_csv self)
      (.save_sheet_csv self (get globals "filepath")))
    (reset! globals "filepath" *untitled_path*)
    (.clear self)
    (.save_sheet_csv self (get globals "filepath"))
    (.update_preview self))

  (defn open_sheet [self &optional defpath]
    (let [path
          (if defpath ; if defpath is not none, it mean we don't need to ask for a path
            [defpath] ; put defpath in a dict, to simulate QFileDialog
            (.getOpenFileName QFileDialog self "Open CSV"
                                  (.getenv os "Home") "CSV(*.csv)"))]
      (reset! globals "filepath" (first path))
      (setv self.check_change False)
      (if (!= (first path) "")
        (with [csv_file (open (first path) :newline "")]
          (.setRowCount self 0)
          (let [my_file (.reader csv csv_file :dialect "excel")]
            (for [row_data my_file]
              (let [row (.rowCount self)]
                (.insertRow self row)
                (if (> (len row_data) *cols*)
                    (.setColumnCount self (len row_data)))
                (for [[column stuff] (enumerate row_data)]
                  (let [item (QTableWidgetItem stuff)]
                    (.setItem self row column item)))))
            (.setRowCount self *rows*))))
      ;; set style for table header, if header is activated
      (if (get globals "header") (.set_header_style self True))
      ;(print (.used_row_count self))
      (setv self.check_change True)
      (reset! globals "filechanged" False)
      (.set_title self)
      (.update_preview self)))

  (defn save_sheet_csv [self &optional defpath]
    (let [path
          (if defpath ; if defpath is not none, it mean we don't need to ask for a path
            [defpath] ; put defpath in a dict, to simulate QFileDialog
            (.getSaveFileName QFileDialog self "Save CSV"
                                 (.getenv os "Home") "CSV(*.csv)"))]
      (if (!= (first path) "")
        (with [csv_file (open (first path) "w")]
          (let [writer (.writer csv csv_file :dialect "excel")]
            (for [row (range (inc (.used_row_count self)))]
              (let [row_data []]
                (for [col (range (inc (.used_column_count self)))]
                  (let [item (.item self row col)]
                    (if (!= item None)
                      (.append row_data (.text item))
                      (.append row_data ""))))
                (.writerow writer row_data))))))
      (reset! globals "filepath" (first path))
      (reset! globals "filechanged" False)
      (.set_title self)))

  (defn save_sheet_html [self]
    (let [path (.getSaveFileName QFileDialog self "Save HTML"
                                 (.getenv os "Home") "HTML(*.html)")]
      (if (!= (first path) "")
        (with [file (open (first path) "w")]
          (.write file (htmlExport.qtable->html self (get globals "header")))
          (.close file)))))

  (defn used_column_count [self]
    "Returns the number of the last column with content, starts with 0 if none is used"
    (setv ucc 0)
    (for [r (range (.rowCount self))]
      (for [c (range (.columnCount self))]
        (setv item (.item self r c))
        (if (and (!= item None)
                 (> (len (.text item)) 0)
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
                 (> (len (.text item)) 0)
                 (>= r urc))
          (setv urc (inc r)))))
    urc)

  (defn set_header_style [self bold]
    "Bool -> Bool
     Consumes the if style of header is bold or not
     returns global state"
    (for [col (range (.columnCount self))]
     (setv item (.item self 0 col))
     (if (!= item None)
       (do
         (setv font (.font item))
         (print (.setBold font bold))
         (print (.setFont item font)))))
    globals)

  (defn eventFilter [self object ev]
    (if (and (= (.type ev) QEvent.FocusOut) (= (.reason ev) *ActiveWindowFocusReason*))
      (do
        (print "QtCore.QEvent.FocusOut")
        (print (.lostFocus ev))
        (print (.reason ev))
        (.on_focus_lost self ev)))
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
    (.clearContents self)))
