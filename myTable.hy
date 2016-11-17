#! /usr/bin/env hy

(def *rows* 1000)
(def *cols* 1000)
(def *width* 1000)
(def *heigh* 800)
(def *window_title* "Tabler")

(import [sys]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          QTableWidget QTableWidgetItem]]
        [PyQt5.QtGui [QIcon]])

(defclass MyTable [QTableWidget]
  (defn --init-- [self r c]

      (.--init-- (super) r c)
      (.init_ui self))

  (defn init_ui [self]
      (.show self)))


(defclass Sheet [QMainWindow]
  (defn --init-- [self]
    (do
      (.--init-- (super))
      (.init_window self)))

  (defn init_window [self]
    (let [form_widget (MyTable *rows* *cols*)]
      (.resize self *width* *heigh*)
      (.center self)
      (.setWindowTitle self *window_title*)
      (.setCentralWidget self form_widget)
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
