#! /usr/bin/env hy

(import [sys]
        [os]
        [csv]
        [ext [htmlExport]]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          QTableWidget QTableWidgetItem QFileDialog
                          qApp QAction]]
        [PyQt5.QtGui [QIcon]])

;; ============
;; Constants
;; ============
(def *col_headers* (.split "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"))
(def *rows* 99)
(def *cols* (len *col_headers*))
(def *width* 1200)
(def *height* 800)
(def *window_title* "Tablao")
(def *icon* (QIcon "icon.svg"))

;; =================
;; Data-definitions
;; =================

;; ==================
;; Global State
;; ==================

(def globals {"header" false})


;; =================
;; Objects
;; =================
(defclass MyTable [QTableWidget]
  (defn --init-- [self r c]
      (.--init-- (super) r c)
      (setv self.check_change true)
      (setv self.header_bold false)
      (.init_ui self))

  (defn init_ui [self]
      (.connect self.cellChanged self.c_current)
      (.show self))

  (defn c_current [self]
    (if self.check_change
        (let [row (.currentRow self)
              col (.currentColumn self)
              value (.text (.item self row col))]
          (print "The current cell is " row " " col)
          (print "In this cell we have: " value))))

  (defn open_sheet [self]
    (let [path (.getOpenFileName QFileDialog self "Open CSV"
                                  (.getenv os "Home") "CSV(*.csv)")]
      (setv self.check_change false)
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
      (setv self.check_change true)
      (print (.used_row_count self))))

  (defn save_sheet_csv [self]
    (let [path (.getSaveFileName QFileDialog self "Save CSV"
                                 (.getenv os "Home") "CSV(*.csv)")]
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
                (.writerow writer row_data))))))))

  (defn save_sheet_html [self]
    (let [path (.getSaveFileName QFileDialog self "Save HTML"
                                 (.getenv os "Home") "HTML(*.html)")]
      (if (!= (first path) "")
        (with [file (open (first path) "w")]
          (.write file (htmlExport.qtable->html self (get globals "header")))
          (.close file)))))

  (defn used_column_count [self]
    "Returns the number of the last column with content, starts with 0"
    (setv ucc 0)
    (for [r (range (.rowCount self))]
      (for [c (range (.columnCount self))]
        (setv item (.item self r c))
        (if (and (!= item None)
                 (> (len (.text item)) 0)
                 (> c ucc))
          (setv ucc c))))
    ucc)

  (defn used_row_count [self]
    "Returns the number of the last row with content, starts with 0"
    (setv urc 0)
    (for [r (range (.rowCount self))]
      (for [c (range (.columnCount self))]
        (setv item (.item self r c))
        (if (and (!= item None)
                 (> (len (.text item)) 0)
                 (> r urc))
          (setv urc r))))
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
        ;  (-> item
        ;      .font
        ;      (.setBold bold)))))
    globals))

(defclass Sheet [QMainWindow]
  (defn --init-- [self]
    (.--init-- (super))
    (.init_window self)
    (setv self.header false))

  (defn init_window [self]
    (let [form_widget (MyTable *rows* *cols*)]
      (.resize self *width* *height*)
      (.center self)
      (.setWindowTitle self *window_title*)
      (.setWindowIcon self *icon*)
      (.setCentralWidget self form_widget)
      (.setHorizontalHeaderLabels form_widget *col_headers*)

      (.->menu self form_widget)

      (.show self)))

  (defn center [self]
    (let [qr (.frameGeometry self)
          cp (-> (QDesktopWidget)
                .availableGeometry
                .center)]
      (.moveCenter qr cp)
      (.move self (.topLeft qr))))

  (defn ->menu [self table]
    (let [bar (.menuBar self)
          file (.addMenu bar "File")
          edit (.addMenu bar "Edit")
          open_action (QAction "&Open" self)
          save_action_csv (QAction "&Save as ..." self)
          save_action_html (QAction "&Export as Html" self)
          quit_action (QAction "&Quit" self)
          set_header_action (QAction "Create table header" self)]
      (.setShortcut open_action "Ctrl+O")
      (.setShortcut save_action_csv "Ctrl+Shift+S")
      (.setShortcut save_action_html "Ctrl+E")
      (.setShortcut quit_action "Ctrl+Q")

      (.addAction file open_action)
      (.addAction file save_action_csv)
      (.addAction file save_action_html)
      (.addAction file quit_action)

      (.addAction edit set_header_action)

      (.connect open_action.triggered table.open_sheet)
      (.connect save_action_csv.triggered table.save_sheet_csv)
      (.connect save_action_html.triggered table.save_sheet_html)
      (.connect quit_action.triggered self.quit_app)

      (.setCheckable set_header_action true)
      (.connect set_header_action.triggered
                (fn [] (.toggle_header self table))))) ; no self in arguments, cause is a FUNCTION, not a medthod

  (defn quit_app [self]
    (.quit qApp))

  (defn toggle_header [self table]
    (let [set_header (.sender self)]
      (.set_header_style table (.isChecked set_header))
      (print (reset! globals "header" (.isChecked set_header)))
      globals)))


;; ==============
;; Functions
;; ==============

(defn reset! [state key new_value]
  "Dict String Object -> Dict
   Consumes a state dictionary, a key and the new value for that key.
   Returns the new state object"
  (setv (get state key) new_value)
  state)

;; ==================
;; Main
;; ==================

(defmain [&rest args]
  (let [app (QApplication sys.argv)
        sheet (Sheet)]
    (.exit sys (.exec_ app))))
