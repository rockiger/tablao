#! /usr/bin/env hy

(import [helper [*]]
        [constants [*]]
        [globals [*]]
        [PyQt5.QtWidgets [QDialog QPushButton QPlainTextEdit QVBoxLayout QDialogButtonBox QSizePolicy]]
        [PyQt5.QtGui [QFont]])

(defclass Export-Dialog[QDialog]
  (defn --init-- [self parent html-string]
    (.--init-- (super Export-Dialog self) parent)
    (setv vbox-layout (QVBoxLayout self)
          button-box  (QDialogButtonBox self)
          close-button (.addButton button-box "Close" QDialogButtonBox.RejectRole)
          copy-button (.addButton button-box "Copy To Clipboard" QDialogButtonBox.AcceptRole)
          text-widget  (QPlainTextEdit html-string self)
          font (QFont "unexistent"))

    (.addWidget vbox-layout text-widget)
    (.addWidget vbox-layout button-box)

    (.setSizePolicy text-widget (QSizePolicy QSizePolicy.Expanding QSizePolicy.Expanding))
    (.setLayout self vbox-layout)
    (.resize self 800 600)
    (.setWindowTitle self "Copy HTML")

    (.selectAll text-widget)
    (.connect copy-button.clicked text-widget.copy)
    (.connect close-button.clicked self.close)


    (.setStyleHint font QFont.Monospace);
    (.setFont text-widget font)

    (.exec_ self)))
