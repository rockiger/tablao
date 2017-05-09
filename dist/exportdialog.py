from helper import *
from constants import *
from globals import *
from PyQt5.QtWidgets import QDialog, QPushButton, QPlainTextEdit, QVBoxLayout, QDialogButtonBox, QSizePolicy
from PyQt5.QtGui import QFont


class Export_Dialog(QDialog):

    def __init__(self, parent, html_string):
        super(Export_Dialog, self).__init__(parent)
        vbox_layout = QVBoxLayout(self)
        button_box = QDialogButtonBox(self)
        close_button = button_box.addButton('Close', QDialogButtonBox.RejectRole)
        copy_button = button_box.addButton('Copy To Clipboard', QDialogButtonBox.AcceptRole)
        text_widget = QPlainTextEdit(html_string, self)
        font = QFont('unexistent')
        vbox_layout.addWidget(text_widget)
        vbox_layout.addWidget(button_box)
        text_widget.setSizePolicy(QSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding))
        self.setLayout(vbox_layout)
        self.resize(800, 600)
        self.setWindowTitle('Copy HTML')
        text_widget.selectAll()
        copy_button.clicked.connect(text_widget.copy)
        close_button.clicked.connect(self.close)
        font.setStyleHint(QFont.Monospace)
        text_widget.setFont(font)
        self.exec_()
        return None
