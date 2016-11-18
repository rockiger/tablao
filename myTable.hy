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
                          QTableWidget QTableWidgetItem QFileDialog
                          qApp QAction]]
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

  (defn save_sheet [self]
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
                (.writerow writer row_data)))))))))


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
          save_action (QAction "&Save" self)
          quit_action (QAction "&Quit" self)]
      (.setShortcut open_action "Ctrl+O")
      (.setShortcut save_action "Ctrl+S")
      (.setShortcut quit_action "Ctrl+Q")

      (.addAction file open_action)
      (.addAction file save_action)
      (.addAction file quit_action)

      (.connect open_action.triggered table.open_sheet)
      (.connect save_action.triggered table.save_sheet)
      (.connect quit_action.triggered self.quit_app)))

  (defn quit_app [self]
    (.quit qApp)))


(defmain [&rest args]
  (let [app (QApplication sys.argv)
        sheet (Sheet)]
    (.exit sys (.exec_ app))))
