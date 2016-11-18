#! /usr/bin/env hy

(def *col_headers* (.split "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"))
(def *rows* 100)
(def *cols* (len *col_headers*))
(def *width* 1200)
(def *height* 800)
(def *window_title* "Tablao")

(import [sys]
        [os]
        [csv]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          QTableWidget QTableWidgetItem QFileDialog]]
        [PyQt5.QtGui [QIcon]])

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
          (let [my_file
                (.reader csv csv_file :delimiter ";" :quotechar "|")]
            (for [row_data my_file]
              (let [row (.rowCount self)]
                (.insertRow self row)
                (if (> (len row_data) *cols*)
                    (.setColumnCount self (len row_data)))
                (for [[column stuff] (enumerate row_data)]
                  (let [item (QTableWidgetItem stuff)]
                    (.setItem self row column item)))))
            (.setRowCount self *rows*))))
      (setv self.check_change true))))


(defclass Sheet [QMainWindow]
  (defn --init-- [self]
    (.--init-- (super))
    (.init_window self))

  (defn init_window [self]
    (let [form_widget (MyTable *rows* *cols*)]
      (.resize self *width* *height*)
      (.center self)
      (.setWindowTitle self *window_title*)
      (.setCentralWidget self form_widget)
      (.setHorizontalHeaderLabels form_widget *col_headers*)

      (.open_sheet form_widget)

      (.show self)))

  (defn center [self]
    (let [qr (.frameGeometry self)
          cp (-> (QDesktopWidget)
                .availableGeometry
                .center)]
      (.moveCenter qr cp)
      (.move self (.topLeft qr)))))

(defmain [&rest args]
  (let [app (QApplication sys.argv)
        sheet (Sheet)]
    (.exit sys (.exec_ app))))
