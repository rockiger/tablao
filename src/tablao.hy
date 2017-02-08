#! /usr/bin/env hy

(import [sys]
        [constants [*]]
        [globals [*]]
        [table [Table]]
        [ext [htmlExport]]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          qApp QAction QWidget QSplitter]]
        [PyQt5.QtCore [QSettings QPoint QUrl]]
        [PyQt5.QtWebKitWidgets [QWebView]])

;; =================
;; Data-definitions
;; =================

;; TODO

;; =================
;; Objects
;; =================

(defclass MainWindow [QMainWindow]
  (defn --init-- [self]
    (.--init-- (super))
    (.init_settings self)
    (.init_window self)
    (print globals))

  (defn init_window [self]
    (let [table (Table *rows* *cols* self.set_title)
          central_widget (QSplitter)
          webview (QWebView)]

      (reset! globals "table" table)
      (reset! globals "webview" webview)

      (.resize self *width* *height*)
      (.center self)
      (.set_title self)
      (.setWindowIcon self *icon*)
      (.setCentralWidget self central_widget)

      (.addWidget central_widget table)
      (.addWidget central_widget webview)
      (.setSizes central_widget (, 50 50))

      (.setHorizontalHeaderLabels table *col_headers*)


      ;(.load webview (QUrl "file:/home/macco/Listings/tablao/test.html"))

      (.->menu self table)

      (if (get globals "filepath")
        (.open_sheet table (get globals "filepath")))


      (.setHtml webview (htmlExport.->preview table (get globals "header") *previewHeader* *previewFooter*))

      (.show self)
      (.setVisible webview (get globals "preview"))))

  (defn init_settings [self]
    (let [settings (get globals "settings")
          menu (.menuBar self)
          set_header_action (.actionAt menu (QPoint 0 0))]
      (setv header (.value settings "table/header" :type bool))
      (reset! globals "header" header)

      (setv preview (.value settings "window/preview" :type bool))
      (reset! globals "preview" preview)

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
    (setv self.new_action  (QAction "&New" self))
    (setv self.open_action (QAction "&Open" self))
    (setv self.save_action_csv (QAction "&Save as ..." self))
    (setv self.save_action_html (QAction "&Export as Html" self))
    (setv self.quit_action (QAction "&Quit" self))
    (setv self.set_header_action (QAction "Create table header" self))
    (setv self.set_preview_action (QAction "Toggle preview" self))

    (.setShortcut self.new_action "Ctrl+N")
    (.setShortcut self.open_action "Ctrl+O")
    (.setShortcut self.save_action_csv "Ctrl+Shift+S")
    (.setShortcut self.save_action_html "Ctrl+E")
    (.setShortcut self.quit_action "Ctrl+Q")
    (.setShortcut self.set_header_action "Ctrl+Shift+H")
    (.setShortcut self.set_preview_action "Ctrl+P")

    (.addAction self.file self.new_action)
    (.addAction self.file self.open_action)
    (.addAction self.file self.save_action_csv)
    (.addAction self.file self.save_action_html)
    (.addAction self.file self.quit_action)

    (.addAction self.edit self.set_header_action)
    (.addAction self.edit self.set_preview_action)

    (.connect self.new_action.triggered table.new_sheet)
    (.connect self.open_action.triggered table.open_sheet)
    (.connect self.save_action_csv.triggered table.save_sheet_csv)
    (.connect self.save_action_html.triggered table.save_sheet_html)
    (.connect self.quit_action.triggered self.quit_app)

    (.setCheckable self.set_header_action True)
    (.setChecked self.set_header_action (get globals "header"))
    (.connect self.set_header_action.triggered
              ;; no self in arguments, cause is a FUNCTION, not a medthod
              (fn []
                (.toggle_header self table)
                (.update_preview (get globals "table"))))

    (.setCheckable self.set_preview_action True)
    (.setChecked self.set_preview_action (get globals "preview"))
    (.connect self.set_preview_action.triggered
              ;; no self in arguments, cause is a FUNCTION, not a medthod
              (fn []
                (.toggle_preview self (get globals "webview")))))

  (defn quit_app [self]
      (.close self)
      (.quit qApp))

  (defn toggle_header [self table]
    (let [set_header (.sender self)]
      (.set_header_style table (.isChecked set_header))
      (.update_preview (get globals "table"))
      (print (reset! globals "header" (.isChecked set_header)))
      globals))

  (defn toggle_preview [self preview]
    "Webview -> Global State"
    (let [show_preview (.sender self)]
      (.setVisible preview (.isChecked show_preview))
      (.update_preview (get globals "table"))
      (print (reset! globals "preview" (.isChecked show_preview)))
      globals))

  (defn closeEvent [self ev]
    (let [settings (get globals "settings")]
      (print "closeEvent")
      (print (get globals "header"))
      (.save_sheet_csv (get globals "table") (get globals "filepath"))
      (.setValue settings "table/header" (get globals "header"))
      (.setValue settings "window/preview" (get globals "preview"))
      (.setValue settings "table/filepath" (get globals "filepath"))
      (.sync settings)))

  (defn set_title [self]
    "set title of window"
    (setv filepath (get globals "filepath"))
    (if (= filepath *untitled_path*)
      (.setWindowTitle self (+ "UNTITLED"
                               (if (get globals "filechanged") " * " "")
                               " — " *app_title*))
      (.setWindowTitle self (+ filepath
                               (if (get globals "filechanged") " * " "")
                               " — " *app_title*)))
    (print "set_title")))

;; ==================
;; Main
;; ==================

(defmain [&rest args]
  (let [app (QApplication sys.argv)
        mainWindow (MainWindow)]
    (.exit sys (.exec_ app))))
