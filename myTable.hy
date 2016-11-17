#! /usr/bin/env hy

(def *rows* 100)
(def *cols* 26)
(def *width* 1200)
(def *height* 800)
(def *window_title* "Tabler")
(def *col_headers* (.split "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"))

(import [sys]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          QTableWidget QTableWidgetItem]]
        [PyQt5.QtGui [QIcon]])

(defclass MyTable [QTableWidget]
  (defn --init-- [self r c]

      (.--init-- (super) r c)
      (.init_ui self))

  (defn init_ui [self]
      (.connect self.cellChanged self.c_current)
      (.show self))

  (defn c_current [self]
    (let [row (.currentRow self)
          col (.currentColumn self)
          value (.text (.item self row col))]
      (print "The current cell is " row " " col)
      (print "In this cell we have: " value))))


(defclass Sheet [QMainWindow]
  (defn --init-- [self]
    (.--init-- (super))
    (.init_window self))

  (defn init_window [self]
    (let [form_widget (MyTable *rows* *cols*)
          number (QTableWidgetItem "10")]
      (.resize self *width* *height*)
      (.center self)
      (.setWindowTitle self *window_title*)
      (.setCentralWidget self form_widget)
      (.setHorizontalHeaderLabels form_widget *col_headers*)

      (.setCurrentCell form_widget 1 1)
      (.setItem form_widget 1 1 number)

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
