#! /usr/bin/env hy

(import [sys]
        [os]
        [csv]
        [ext [htmlExport]]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          QTableWidget QTableWidgetItem QFileDialog
                          qApp QAction]]
        [PyQt5.QtGui [QIcon]]
        [PyQt5.QtCore [QSettings QPoint QEvent]])

;; ============
;; Constants
;; ============
(def *col_headers* (.split "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"))
(def *rows* 99)
(def *cols* (len *col_headers*))
(def *width* 1200)
(def *height* 800)
(def *app_title* "Tablao")
(def *icon* (QIcon "icon.svg"))
(def *ActiveWindowFocusReason* 3)

;; =================
;; Data-definitions
;; =================

;; TODO

;; ==================
;; Global State
;; ==================

(def globals {"header" true
              "settings" (QSettings "Rockiger" "Tablao")
              "filepath" ""
              "filechanged" false})

;; =================
;; Objects
;; =================
(defclass MyTable [QTableWidget]
  (defn --init-- [self r c set_title]
      (.--init-- (super) r c)
      (setv self.set_title set_title)
      (setv self.check_change true)
      (setv self.header_bold false)
      (.init_ui self)
      (.installEventFilter self self))

  (defn init_ui [self]
      (.connect self.cellChanged self.c_current)
      (.connect self.cellChanged self.set_changed)
      (.show self))

  (defn c_current [self]
    (if self.check_change
        (let [row (.currentRow self)
              col (.currentColumn self)
              value (.text (.item self row col))]
          (print "The current cell is " row " " col)
          (print "In this cell we have: " value))))

  (defn open_sheet [self &optional defpath]
    (let [path
          (if defpath ; if defpath is not none, it mean we don't need to ask for a path
            [defpath] ; put defpath in a dict, to simulate QFileDialog
            (.getOpenFileName QFileDialog self "Open CSV"
                                  (.getenv os "Home") "CSV(*.csv)"))]
      (reset! globals "filepath" (first path))
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
      ;; set style for table header, if header is activated
      (if (get globals "header") (.set_header_style self true))
      (print (.used_row_count self))
      (setv self.check_change true)
      (reset! globals "filechanged" false)
      (.set_title self)))

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
      (reset! globals "filechanged" false)
      (.set_title self)))

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
    globals)

  (defn eventFilter [self object ev]
    (if (and (= (.type ev) QEvent.FocusOut) (= (.reason ev) *ActiveWindowFocusReason*))
      (do
        (print "QtCore.QEvent.FocusOut")
        (print (.lostFocus ev))
        (print (.reason ev))
        (.on_focus_lost self ev)))
    false)

  (defn on_focus_lost [self ev]
    (.save_sheet_csv self (get globals "filepath"))
    (.set_title self))

  (defn set_changed [self]
    (reset! globals "filechanged" true)
    (.set_title self)
    (print "set_changed")))

(defclass MainWindow [QMainWindow]
  (defn --init-- [self]
    (.--init-- (super))
    (.init_settings self)
    (.init_window self)
    (print globals))

  (defn init_window [self]
    (let [form_widget (MyTable *rows* *cols* self.set_title)]
      (.resize self *width* *height*)
      (.center self)
      (.set_title self)
      (.setWindowIcon self *icon*)
      (.setCentralWidget self form_widget)
      (.setHorizontalHeaderLabels form_widget *col_headers*)

      (.->menu self form_widget)

      (if (get globals "filepath")
        (.open_sheet form_widget (get globals "filepath")))

      (.show self)))

  (defn init_settings [self]
    (let [settings (get globals "settings")
          menu (.menuBar self)
          set_header_action (.actionAt menu (QPoint 0 0))]
      (setv header (.value settings "table/header" :type bool))
      (reset! globals "header" header)

      (setv filepath (.value settings "table/filepath" :type str))
      (reset! globals "filepath" filepath)

      (print (get globals "filepath"))))


  (defn center [self]
    (let [qr (.frameGeometry self)
          cp (-> (QDesktopWidget)
                .availableGeometry
                .center)]
      (.moveCenter qr cp)
      (.move self (.topLeft qr))))

  (defn ->menu [self table]
    (setv self.bar (.menuBar self))
    (setv self.file (.addMenu self.bar "File"))
    (setv self.edit (.addMenu self.bar "Edit"))
    (setv self.open_action (QAction "&Open" self))
    (setv self.save_action_csv (QAction "&Save as ..." self))
    (setv self.save_action_html (QAction "&Export as Html" self))
    (setv self.quit_action (QAction "&Quit" self))
    (setv self.set_header_action (QAction "Create table header" self))
    (.setShortcut self.open_action "Ctrl+O")
    (.setShortcut self.save_action_csv "Ctrl+Shift+S")
    (.setShortcut self.save_action_html "Ctrl+E")
    (.setShortcut self.quit_action "Ctrl+Q")

    (.addAction self.file self.open_action)
    (.addAction self.file self.save_action_csv)
    (.addAction self.file self.save_action_html)
    (.addAction self.file self.quit_action)

    (.addAction self.edit self.set_header_action)

    (.connect self.open_action.triggered table.open_sheet)
    (.connect self.save_action_csv.triggered table.save_sheet_csv)
    (.connect self.save_action_html.triggered table.save_sheet_html)
    (.connect self.quit_action.triggered self.quit_app)

    (.setCheckable self.set_header_action true)
    (.setChecked self.set_header_action (get globals "header"))

    (.connect self.set_header_action.triggered
              ;; no self in arguments, cause is a FUNCTION, not a medthod
              (fn [] (.toggle_header self table))))

  (defn quit_app [self]
      (.close self)
      (.quit qApp))

  (defn toggle_header [self table]
    (let [set_header (.sender self)]
      (.set_header_style table (.isChecked set_header))
      (print (reset! globals "header" (.isChecked set_header)))
      globals))

  (defn closeEvent [self ev]
    (let [settings (get globals "settings")]
      (print "closeEvent")
      (print (get globals "header"))
      (.setValue settings "table/header" (get globals "header"))
      (.setValue settings "table/filepath" (get globals "filepath"))
      (.sync settings)))

  (defn set_title [self]
    (.setWindowTitle self (+ (get globals "filepath")
                             (if (get globals "filechanged") " * " "")
                             " — " *app_title*))
    (print "set_title")))


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
        mainWindow (MainWindow)]
    (.exit sys (.exec_ app))))
