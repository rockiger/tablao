import sys
from helper import *
from constants import *
from globals import *
from table import Table
from exportdialog import Export_Dialog
from ext import htmlExport
from PyQt5.QtWidgets import QApplication, QMainWindow, QDesktopWidget, qApp, QAction, QWidget, QSplitter
from PyQt5.QtCore import QPoint, QUrl, Qt
from PyQt5.QtWebEngineWidgets import QWebEngineView


class MainWindow(QMainWindow):

    def __init__(self):
        super().__init__()
        self.init_settings()
        self.init_window()
        log(globals)
        return None

    def init_window(self):
        table = Table(ROWS, COLS, self.set_title)
        central_widget = QSplitter()
        webview = QWebEngineView()
        reset_bang(globals, 'table', table)
        reset_bang(globals, 'webview', webview)
        self.resize(WIDTH, HEIGHT)
        self.center()
        self.set_title()
        self.setWindowIcon(ICON)
        self.setCentralWidget(central_widget)
        central_widget.addWidget(table)
        central_widget.addWidget(webview)
        central_widget.setSizes((50, 77))
        table.setHorizontalHeaderLabels(COL_HEADERS)
        self.create_menu(table)
        (table.open_sheet(globals['filepath']) if globals['filepath'] else None)
        webview.setHtml(htmlExport.create_preview(table, globals['header'], PREVIEWHEADER, PREVIEWFOOTER))
        self.show()
        return webview.setVisible(globals['preview'])

    def init_settings(self):
        settings = globals['settings']
        menu = self.menuBar()
        set_header_action = menu.actionAt(QPoint(0, 0))
        second_run = settings.value('app/second-run', type=bool)
        reset_bang(globals, 'second-run', second_run)
        if second_run:
            header = settings.value('table/header', type=bool)
            reset_bang(globals, 'header', header)
            preview = settings.value('window/preview', type=bool)
            reset_bang(globals, 'preview', preview)
            filepath = settings.value('table/filepath', type=str)
            _hy_anon_var_1 = reset_bang(globals, 'filepath', filepath)
        else:
            _hy_anon_var_1 = None
        return log(globals['filepath'])

    def center(self):
        qr = self.frameGeometry()
        cp = QDesktopWidget().availableGeometry().center()
        qr.moveCenter(cp)
        return self.move(qr.topLeft())

    def create_menu(self, table):
        self.bar = self.menuBar()
        self.file = self.bar.addMenu('File')
        self.edit = self.bar.addMenu('Edit')
        self.view = self.bar.addMenu('View')
        self.new_action = QAction('&New', self)
        self.open_action = QAction('&Open', self)
        self.save_action_csv = QAction('&Save as ...', self)
        self.save_action_html = QAction('&Export as Html', self)
        self.quit_action = QAction('&Quit', self)
        self.undo_action = QAction('Undo')
        self.undo_action.setEnabled(False)
        self.redo_action = QAction('Redo')
        self.redo_action.setEnabled(False)
        self.copy_action = QAction('Copy', self)
        self.paste_action = QAction('Paste', self)
        self.cut_action = QAction('Cut', self)
        self.delete_action = QAction('Delete', self)
        self.copy_html_action = QAction('Copy HTML', self)
        self.set_header_action = QAction('Create table header', self)
        self.set_preview_action = QAction('Toggle preview', self)
        self.new_action.setShortcut('Ctrl+N')
        self.open_action.setShortcut('Ctrl+O')
        self.save_action_csv.setShortcut('Ctrl+Shift+S')
        self.save_action_html.setShortcut('Ctrl+E')
        self.quit_action.setShortcut('Ctrl+Q')
        self.undo_action.setShortcut('Ctrl+Z')
        self.redo_action.setShortcut('Ctrl+Shift+Z')
        self.copy_action.setShortcut('Ctrl+C')
        self.paste_action.setShortcut('Ctrl+V')
        self.cut_action.setShortcut('Ctrl+X')
        self.delete_action.setShortcuts([Qt.Key_Delete, Qt.Key_Backspace])
        self.copy_html_action.setShortcut('Ctrl+Shift+C')
        self.set_header_action.setShortcut('Ctrl+Shift+H')
        self.set_preview_action.setShortcut('Ctrl+Shift+P')
        self.file.addAction(self.new_action)
        self.file.addAction(self.open_action)
        self.file.addSeparator()
        self.file.addAction(self.save_action_csv)
        self.file.addAction(self.save_action_html)
        self.file.addSeparator()
        self.file.addAction(self.quit_action)
        self.edit.addAction(self.undo_action)
        self.edit.addAction(self.redo_action)
        self.edit.addSeparator()
        self.edit.addAction(self.copy_action)
        self.edit.addAction(self.paste_action)
        self.edit.addAction(self.cut_action)
        self.edit.addSeparator()
        self.edit.addAction(self.copy_html_action)
        self.edit.addSeparator()
        self.edit.addAction(self.delete_action)
        self.view.addAction(self.set_header_action)
        self.view.addAction(self.set_preview_action)
        self.new_action.triggered.connect(table.new_sheet)
        self.open_action.triggered.connect(table.open_sheet)
        self.save_action_csv.triggered.connect(table.save_sheet_csv)
        self.save_action_html.triggered.connect(table.save_sheet_html)
        self.quit_action.triggered.connect(self.quit_app)
        self.undo_action.triggered.connect(table.undo)
        self.redo_action.triggered.connect(table.redo)
        table.undo_stack.canUndoChanged.connect(self.set_undo_entry)
        table.undo_stack.canRedoChanged.connect(self.set_redo_entry)
        self.copy_action.triggered.connect(table.copy_selection)
        self.paste_action.triggered.connect(table.paste)
        self.cut_action.triggered.connect(table.cut_selection)
        self.copy_html_action.triggered.connect(self.export_html)
        self.delete_action.triggered.connect(table.delete_selection)
        self.set_header_action.setCheckable(True)
        self.set_header_action.setChecked(globals['header'])

        def _hy_anon_fn_5():
            self.toggle_header(table)
            return globals['table'].update_preview()
        self.set_header_action.triggered.connect(_hy_anon_fn_5)
        self.set_preview_action.setCheckable(True)
        self.set_preview_action.setChecked(globals['preview'])
        return self.set_preview_action.triggered.connect((lambda : self.toggle_preview(globals['webview'])))

    def quit_app(self):
        self.close()
        return qApp.quit()

    def toggle_header(self, table):
        set_header = self.sender()
        log('ISCHECKED ', set_header.isChecked())
        log(reset_bang(globals, 'header', set_header.isChecked()))
        table.set_header_style(globals['header'])
        globals['table'].update_preview()
        return globals

    def toggle_preview(self, preview):
        'Webview -> Global State'
        show_preview = self.sender()
        preview.setVisible(show_preview.isChecked())
        globals['table'].update_preview()
        log(reset_bang(globals, 'preview', show_preview.isChecked()))
        return globals

    def closeEvent(self, ev):
        settings = globals['settings']
        log('closeEvent')
        log(globals['header'])
        globals['table'].save_sheet_csv(globals['filepath'])
        settings.setValue('table/header', globals['header'])
        settings.setValue('window/preview', globals['preview'])
        settings.setValue('table/filepath', globals['filepath'])
        settings.setValue('app/second-run', True)
        return settings.sync()

    def set_title(self):
        'set title of window'
        filepath = globals['filepath']
        (self.setWindowTitle(((('UNTITLED' + (' * ' if globals['filechanged'] else '')) + ' — ') + APP_TITLE)) if (filepath == UNTITLED_PATH) else self.setWindowTitle((((filepath + (' * ' if globals['filechanged'] else '')) + ' — ') + APP_TITLE)))
        return debug('set_title')

    def set_undo_entry(self, can_undo):
        return (self.undo_action.setEnabled(True) if can_undo else self.undo_action.setEnabled(False))

    def set_redo_entry(self, can_redo):
        return (self.redo_action.setEnabled(True) if can_redo else self.redo_action.setEnabled(False))

    def export_html(self):
        'Void -> Void\n    Creates a Export-Dialog and presents the HTML to the user'
        html_string = htmlExport.qtable_to_html(globals['table'], globals['header'])
        export_dialog = Export_Dialog(self, html_string)
        return export_dialog.show()

def main():
    app = QApplication(sys.argv)
    mainWindow = MainWindow()
    clipboard = QApplication.clipboard()
    reset_bang(globals, 'clipboard', clipboard)
    return sys.exit(app.exec_())
(main() if (__name__ == '__main__') else None)
