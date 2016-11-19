#! /usr/bin/env hy

(import [sys]
        [os]
        [csv]
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

;; =================
;; Objects
;; =================
(defclass MyTable [QTableWidget]
  (defn --init-- [self r c]
      (.--init-- (super) r c)
      (setv self.check_change true)
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
      (setv self.check_change true)))

  (defn save_sheet_csv [self]
    (let [path (.getSaveFileName QFileDialog self "Save CSV"
                                 (.getenv os "Home") "CSV(*.csv)")]
      (if (!= (first path) "")
        (with [csv_file (open (first path) "w")]
          (let [writer (.writer csv csv_file :dialect "excel")]
            (for [row (range (.rowCount self))]
              (let [row_data []]
                (for [col (range (.columnCount self))]
                  (let [item (.item self row col)]
                    (if (!= item None)
                      (if (> (len (.text item)) 0)
                          (.append row_data (.text item))))))
                (.writerow writer row_data))))))))


  (defn save_sheet_html [self]
    (let [path (.getSaveFileName QFileDialog self "Save HTML"
                                 (.getenv os "Home") "HTML(*.html)")]
      (if (!= (first path) "")
        (with [file (open (first path) "w")]
          (.write file (qtable->html self))
          (.close file))))))



  ;; (defn save_sheet_html [self]
  ;;   (let [path](.getSaveFileName QFileDialog self "Save HTML"
  ;;                                (.getenv os "Home") "HTML(*.html)")
  ;;     (if (!= (first path) "")
  ;;       (with [file (open (first path) "w")]
  ;;         (let [writer "<table>"]
  ;;           (for [row (range (.rowCount self))]
  ;;             (let [row_data "&&"]
  ;;               (print "let1: " + row_data)
  ;;               (for [col (range (.columnCount self))]
  ;;                 (print "for: " row_data)
  ;;                 (let [item (.item self row col)]
  ;;                   (print "let2: " row_data)
  ;;                   (if (!= item None)
  ;;                     (if (> (len (.text item)) 0)
  ;;                         (setv row_data (+ row_data (.text item)))))))
  ;;               (setv writer (+ writer "\n<tr>" row_data "</tr>"))))
  ;;           (setv writer (+ writer "\n</table>"))))))))

(defn qtable->html [qtable]
  "QTableWidget -> String
   Consumes a QTableWidget qtable and
   produces a string with that table in HTML"

  (defn parse-rows [qtable row cols]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the curren of the row and number of columns,
    iterates over its rows and produces the rows in html"
    (if (= row 0)
      (if (!= "" (parse-cols qtable row cols))
        (+ "<tr>\n" (parse-cols qtable row cols) "\n</tr>")
        "")
      (if (!= "" (parse-cols qtable row cols))
        (+ (parse-rows qtable (dec row) cols)
           "\n<tr>\n" (parse-cols qtable row cols) "\n</tr>")
        (+ (parse-rows qtable (dec row) cols) (parse-cols qtable row cols)))))

  (defn parse-cols [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    iterates over its rows and produces the rows in html"
    (if (= col 0)
      (parse-item qtable row col)
      (+ (parse-cols qtable row (dec col)) (parse-item qtable row col))))

  (defn parse-item [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    produces the rows in html"
    (let [item (.item qtable row col)]
      (if (!= item None)
        (if (> (len (.text item)) 0)
          (+ "<td>" (.text item) "</td>")
          "")
        "")))

  (+ "<table>\n"(parse-rows qtable (.rowCount qtable) (.columnCount qtable)) "\n</table>"))

(defclass Sheet [QMainWindow]
  (defn --init-- [self]
    (.--init-- (super))
    (.init_window self))

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
          open_action (QAction "&Open" self)
          save_action_csv (QAction "&Save Csv" self)
          save_action_html (QAction "Save Html" self)
          quit_action (QAction "&Quit" self)]
      (.setShortcut open_action "Ctrl+O")
      (.setShortcut save_action_csv "Ctrl+Shift+S")
      (.setShortcut save_action_html "Ctrl+S")
      (.setShortcut quit_action "Ctrl+Q")

      (.addAction file open_action)
      (.addAction file save_action_html)
      (.addAction file save_action_csv)
      (.addAction file quit_action)

      (.connect open_action.triggered table.open_sheet)
      (.connect save_action_csv.triggered table.save_sheet_csv)
      (.connect save_action_html.triggered table.save_sheet_html)
      (.connect quit_action.triggered self.quit_app)))

  (defn quit_app [self]
    (.quit qApp)))


;; ==============
;; Functions
;; ==============

(defmain [&rest args]
  (let [app (QApplication sys.argv)
        sheet (Sheet)]
    (.exit sys (.exec_ app))))
