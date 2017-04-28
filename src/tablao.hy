#! /usr/bin/env hy

(import [sys]
        [helper [*]]
        [constants [*]]
        [globals [*]]
        [table [Table]]
        [ext [htmlExport]]
        [PyQt5.QtWidgets [QApplication QMainWindow QDesktopWidget
                          qApp QAction QWidget QSplitter]]
        [PyQt5.QtCore [QSettings QPoint QUrl Qt]]
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
    (log globals))

  (defn init_window [self]
    (setv table (Table *rows* *cols* self.set_title)
          central_widget (QSplitter)
          webview (QWebView))

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
    (.setVisible webview (get globals "preview")))

  (defn init_settings [self]
    (setv settings (get globals "settings")
          menu (.menuBar self)
          set_header_action (.actionAt menu (QPoint 0 0)))
    (setv header (.value settings "table/header" :type bool))
    (reset! globals "header" header)

    (setv preview (.value settings "window/preview" :type bool))
    (reset! globals "preview" preview)

    (setv filepath (.value settings "table/filepath" :type str))
    (reset! globals "filepath" filepath)

    (log (get globals "filepath")))


  (defn center [self]
    (setv qr (.frameGeometry self)
          cp (-> (QDesktopWidget)
                .availableGeometry
                .center))
    (.moveCenter qr cp)
    (.move self (.topLeft qr)))

  (defn ->menu [self table]
    (setv self.bar (.menuBar self))
    (setv self.file (.addMenu self.bar "File"))
    (setv self.edit (.addMenu self.bar "Edit"))
    (setv self.view (.addMenu self.bar "View"))

    (setv self.new_action  (QAction "&New" self))
    (setv self.open_action (QAction "&Open" self))
    (setv self.save_action_csv (QAction "&Save as ..." self))
    (setv self.save_action_html (QAction "&Export as Html" self))
    (setv self.quit_action (QAction "&Quit" self))

    (setv self.undo-action (QAction "Undo"))
    (.setEnabled self.undo-action False)
    (setv self.redo-action (QAction "Redo"))
    (.setEnabled self.redo-action False)
    (setv self.copy_action (QAction "Copy" self))
    (setv self.paste_action (QAction "Paste" self))
    (setv self.cut_action (QAction "Cut" self))
    (setv self.delete_action (QAction "Delete" self))

    (setv self.set_header_action (QAction "Create table header" self))
    (setv self.set_preview_action (QAction "Toggle preview" self))

    (.setShortcut self.new_action "Ctrl+N")
    (.setShortcut self.open_action "Ctrl+O")
    (.setShortcut self.save_action_csv "Ctrl+Shift+S")
    (.setShortcut self.save_action_html "Ctrl+E")
    (.setShortcut self.quit_action "Ctrl+Q")

    (.setShortcut self.undo-action "Ctrl+Z")
    (.setShortcut self.redo-action "Ctrl+Shift+Z")
    (.setShortcut self.copy_action "Ctrl+C")
    (.setShortcut self.paste_action "Ctrl+V")
    (.setShortcut self.cut_action "Ctrl+X")
    (.setShortcuts self.delete_action [Qt.Key_Delete Qt.Key_Backspace])

    (.setShortcut self.set_header_action "Ctrl+Shift+H")
    (.setShortcut self.set_preview_action "Ctrl+Shift+P")

    (.addAction self.file self.new_action)
    (.addAction self.file self.open_action)
    (.addSeparator self.file)
    (.addAction self.file self.save_action_csv)
    (.addAction self.file self.save_action_html)
    (.addSeparator self.file)
    (.addAction self.file self.quit_action)

    (.addAction self.edit self.undo-action)
    (.addAction self.edit self.redo-action)
    (.addSeparator self.edit)
    (.addAction self.edit self.copy_action)
    (.addAction self.edit self.paste_action)
    (.addAction self.edit self.cut_action)
    (.addSeparator self.edit)
    (.addAction self.edit self.delete_action)

    (.addAction self.view self.set_header_action)
    (.addAction self.view self.set_preview_action)

    (.connect self.new_action.triggered table.new_sheet)
    (.connect self.open_action.triggered table.open_sheet)
    (.connect self.save_action_csv.triggered table.save_sheet_csv)
    (.connect self.save_action_html.triggered table.save_sheet_html)
    (.connect self.quit_action.triggered self.quit_app)

    (.connect self.undo-action.triggered table.undo)
    (.connect self.redo-action.triggered table.redo)
    (.connect table.undo-stack.canUndoChanged self.set-undo-entry)
    (.connect table.undo-stack.canRedoChanged self.set-redo-entry)

    (.connect self.copy_action.triggered table.copy-selection)
    (.connect self.paste_action.triggered table.paste)
    (.connect self.cut_action.triggered table.cut-selection)
    (.connect self.delete_action.triggered table.delete-selection)

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
    (setv set_header (.sender self))
    (log "ISCHECKED " (.isChecked set_header))
    (log (reset! globals "header" (.isChecked set_header)))
    (.set_header_style table (get globals "header"))
    (.update_preview (get globals "table"))
    globals)

  (defn toggle_preview [self preview]
    "Webview -> Global State"
    (setv show_preview (.sender self))
    (.setVisible preview (.isChecked show_preview))
    (.update_preview (get globals "table"))
    (log (reset! globals "preview" (.isChecked show_preview)))
    globals)

  (defn closeEvent [self ev]
    (setv settings (get globals "settings"))
    (log "closeEvent")
    (log (get globals "header"))
    (.save_sheet_csv (get globals "table") (get globals "filepath"))
    (.setValue settings "table/header" (get globals "header"))
    (.setValue settings "window/preview" (get globals "preview"))
    (.setValue settings "table/filepath" (get globals "filepath"))
    (.sync settings))

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
    (debug "set_title"))

  (defn set-undo-entry [self can-undo]
    (if can-undo
      (.setEnabled self.undo-action True)
      (.setEnabled self.undo-action False)))

  (defn set-redo-entry [self can-redo]
    (if can-redo
      (.setEnabled self.redo-action True)
      (.setEnabled self.redo-action False))))


;; ==================
;; Main
;; ==================

(defmain [&rest args]
  (setv app (QApplication sys.argv)
        mainWindow (MainWindow)
        clipboard (.clipboard QApplication))
  (reset! globals "clipboard" clipboard)
  (.exit sys (.exec_ app)))
