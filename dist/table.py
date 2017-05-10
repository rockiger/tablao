from hy.core.language import first, inc, is_pos
import os
import csv
from helper import *
from constants import *
from globals import *
from ext import htmlExport
from commands import Command_Paste, Command_Delete, Command_Cell_Edit
from PyQt5.QtWidgets import QTableWidget, QTableWidgetItem, QFileDialog, QAction, QTableWidgetSelectionRange, QUndoStack, QUndoCommand
from PyQt5.QtCore import QEvent, Qt


class Table(QTableWidget):

    def __init__(self, r, c, set_title):
        super().__init__(r, c)
        self.set_title = set_title
        self.check_change = True
        self.header_bold = False
        self.undo_stack = QUndoStack(self)
        self.init_cells()
        self.init_ui()
        self.installEventFilter(self)
        self.init_undo_cell_edits()
        return None

    def init_cells(self):
        for row in range(self.rowCount()):
            for col in range(self.columnCount()):
                (self.setItem(row, col, QTableWidgetItem()) if (self.item(row, col) == None) else None)

    def init_ui(self):
        self.cellChanged.connect(self.update_preview)
        self.cellChanged.connect(self.set_changed)
        self.cellChanged.connect((lambda : (self.set_header_style(True) if globals['header'] else None)))
        self.cellChanged.connect(self.on_cell_changed)
        self.itemSelectionChanged.connect(self.set_selection)
        self.cellActivated.connect((lambda : log('CELLACTIVATED')))
        return self.show()

    def init_undo_cell_edits(self):
        "undo/redo of edits\n    The whole thing is very complicated and dirty, because we can't\n    use the standard way of using the QUndoCommand.\n    We use 2 state variables, one that carries the current cell content\n    and one that determines, if the current cell was changed.\n    Every time we enter a cell, the content is written to open-editor-content\n    and open-editor-content-changed is set to False. This is done in\n    reimplemented function self.edit. If the user changes the cell content\n    on-cell-changed is called and sets self.open-editor-content-changed\n    to true. When the user leaves the cell self.closeEditor is called.\n    If self.open-editor-content-changed is True it creates a QUndoCommand."
        self.open_editor_content = {'\ufdd0:old': '', '\ufdd0:new': '', '\ufdd0:row': 0, '\ufdd0:col': 0, }
        self.open_editor_content_changed = False

    def edit(self, index, tmp1, tmp2):
        log('OPENEDITOR')
        item = self.currentItem()
        txt = (item.text() if item else '')
        self.open_editor_content = {'\ufdd0:old': txt, '\ufdd0:row': self.currentRow(), '\ufdd0:col': self.currentColumn(), }
        self.open_editor_content_changed = False
        return QTableWidget.edit(self, index, tmp1, tmp2)

    def on_cell_changed(self, row, col):
        log('OnCELLCHANGED')
        self.open_editor_content_changed = True
        self.open_editor_content['\ufdd0:new'] = self.item(self.open_editor_content['\ufdd0:row'], self.open_editor_content['\ufdd0:col']).text()
        return debug(self.open_editor_content)

    def closeEditor(self, editor, hint):
        log('CLOSEPERSISTANTEDITOR')
        if self.open_editor_content_changed:
            log('DO EDIT-COMMAND')
            command = Command_Cell_Edit(self, self.open_editor_content, 'Edit Cell')
            _hy_anon_var_1 = self.undo_stack.push(command)
        else:
            _hy_anon_var_1 = None
        return QTableWidget.closeEditor(self, editor, hint)

    def range_content(self, selection_range):
        rows = []
        for row in range(selection_range.topRow(), inc(selection_range.bottomRow())):
            cols = []
            for col in range(selection_range.leftColumn(), inc(selection_range.rightColumn())):
                item = self.item(row, col)
                cols.append(item)
            rows.append(cols)
        return rows

    def undo(self):
        'Undo changes to table'
        log('UNDO')
        return self.undo_stack.undo()

    def redo(self):
        'Redo changes to table'
        log('REDO')
        return self.undo_stack.redo()

    def set_selection(self):
        'Void -> Void\n    Inserts the selection to the primary clipboard. http://doc.qt.io/qt-5/qclipboard.html#Mode-enum'
        return (self.copy_selection(clipboard_mode=CLIPBOARD_MODE_SELECTION) if is_pos(self.selectionMode()) else None)

    def paste(self, clipboard_mode=CLIPBOARD_MODE_CLIPBOARD):
        'Void (Enum(0-2)) -> Void\n    Inserts the clipboard, at the upper left corner of the current selection'
        (log('WARNING: Paste only works on first selection') if (len(self.selectedRanges()) > 1) else None)
        r = first(self.selectedRanges())
        paste_list = self.parse_for_paste(first(globals['clipboard'].text('plain', clipboard_mode)))
        if (r == None):
            start_row = self.currentRow()
            start_col = self.currentColumn()
            _hy_anon_var_2 = None
        else:
            start_col = r.leftColumn()
            start_row = r.topRow()
            _hy_anon_var_2 = None
        command = Command_Paste(self, start_row, start_col, paste_list, 'Paste')
        return self.undo_stack.push(command)

    def copy_selection(self, clipboard_mode=CLIPBOARD_MODE_CLIPBOARD):
        'Int(0,2) -> Void\n    Copies the current selection to the clipboard. Depending on the clipboard-mode to define which clipboard system is used\n    QClipboard::Clipboard\t0\tindicates that data should be stored and retrieved from the global clipboard.\n    QClipboard::Selection\t1\tindicates that data should be stored and retrieved from the global mouse selection. Support for Selection is provided only on systems with a global mouse selection (e.g. X11).\n    QClipboard::FindBuffer\t2\tindicates that data should be stored and retrieved from the Find buffer. This mode is used for holding search strings on macOS.\n    http://doc.qt.io/qt-5/qclipboard.html#Mode-enum'
        (log('WARNING: Copy only works on first selection') if (len(self.selectedRanges()) > 1) else None)
        r = first(self.selectedRanges())
        copy_content = ''
        try:
            for row in range(r.topRow(), inc(r.bottomRow())):
                for col in range(r.leftColumn(), inc(r.rightColumn())):
                    item = self.item(row, col)
                    if (item != None):
                        copy_content = (copy_content + item.text())
                        if (not (col == r.rightColumn())):
                            copy_content = (copy_content + '\t')
                            _hy_anon_var_3 = None
                        else:
                            _hy_anon_var_3 = None
                        _hy_anon_var_4 = _hy_anon_var_3
                    else:
                        _hy_anon_var_4 = None
                if (not (row == r.bottomRow())):
                    copy_content = (copy_content + '\n')
                    _hy_anon_var_5 = None
                else:
                    _hy_anon_var_5 = None
            _hy_anon_var_6 = globals['clipboard'].setText(copy_content, clipboard_mode)
        except AttributeError as e:
            _hy_anon_var_6 = log('WARING: No selection available')
        return _hy_anon_var_6

    def delete_selection(self):
        'Void -> Void\n    Deletes the current selection.'
        log('DELETE-SELECTION')
        command = Command_Delete(self, 'Delete')
        return self.undo_stack.push(command)

    def cut_selection(self):
        self.copy_selection()
        return self.delete_selection()

    def c_current(self):
        if self.check_change:
            row = self.currentRow()
            col = self.currentColumn()
            try:
                value = self.item(row, col).text()
            except AttributeError as e:
                value = ''
            log('The current cell is ', row, ' ', col)
            _hy_anon_var_8 = log('In this cell we have: ', value)
        else:
            _hy_anon_var_8 = None
        return _hy_anon_var_8

    def update_preview(self):
        return (globals['webview'].setHtml(htmlExport.create_preview(self, globals['header'], PREVIEWHEADER, PREVIEWFOOTER)) if self.check_change else None)

    def new_sheet(self):
        (self.save_sheet_csv() if ((globals['filepath'] == UNTITLED_PATH) and is_pos(self.used_row_count())) else self.save_sheet_csv(globals['filepath']))
        reset_bang(globals, 'filepath', UNTITLED_PATH)
        self.clear()
        self.save_sheet_csv(globals['filepath'])
        self.undo_stack.clear()
        return self.update_preview()

    def open_sheet(self, defpath=None):
        self.blockSignals(True)
        path = ([defpath] if defpath else QFileDialog.getOpenFileName(self, 'Open CSV', os.getenv('Home'), 'CSV(*.csv)'))
        reset_bang(globals, 'filepath', first(path))
        self.check_change = False
        if (first(path) != ''):
            with open(first(path), newline='') as csv_file:
                self.setRowCount(0)
                my_file = csv.reader(csv_file, dialect='excel')
                for row_data in my_file:
                    row = self.rowCount()
                    self.insertRow(row)
                    (self.setColumnCount(len(row_data)) if (len(row_data) > COLS) else None)
                    for [column, stuff] in enumerate(row_data):
                        item = QTableWidgetItem(stuff)
                        self.setItem(row, column, item)
                _hy_anon_var_9 = self.setRowCount(ROWS)
            _hy_anon_var_10 = _hy_anon_var_9
        else:
            _hy_anon_var_10 = None
        self.init_cells()
        (self.set_header_style(True) if globals['header'] else None)
        debug(self.used_row_count())
        self.check_change = True
        reset_bang(globals, 'filechanged', False)
        self.set_title()
        self.update_preview()
        self.undo_stack.clear()
        return self.blockSignals(False)

    def save_sheet_csv(self, defpath=None):
        path = ([defpath] if defpath else QFileDialog.getSaveFileName(self, 'Save CSV', os.getenv('Home'), 'CSV(*.csv)'))
        if (first(path) != ''):
            with open(first(path), 'w') as csv_file:
                writer = csv.writer(csv_file, dialect='excel')
                for row in range(inc(self.used_row_count())):
                    row_data = []
                    for col in range(inc(self.used_column_count())):
                        item = self.item(row, col)
                        (row_data.append(item.text()) if (item != None) else row_data.append(''))
                    writer.writerow(row_data)
                _hy_anon_var_11 = None
            _hy_anon_var_12 = _hy_anon_var_11
        else:
            _hy_anon_var_12 = None
        reset_bang(globals, 'filepath', first(path))
        reset_bang(globals, 'filechanged', False)
        return self.set_title()

    def save_sheet_html(self):
        path = QFileDialog.getSaveFileName(self, 'Save HTML', os.getenv('Home'), 'HTML(*.html)')
        if (first(path) != ''):
            with open(first(path), 'w') as file:
                file.write(htmlExport.qtable_to_html(self, globals['header']))
                _hy_anon_var_13 = file.close()
            _hy_anon_var_14 = _hy_anon_var_13
        else:
            _hy_anon_var_14 = None
        return _hy_anon_var_14

    def used_column_count(self):
        'Returns the number of the last column with content, starts with 0 if none is used'
        ucc = 0
        for r in range(self.rowCount()):
            for c in range(self.columnCount()):
                item = self.item(r, c)
                if ((item != None) and is_pos(len(item.text())) and (c >= ucc)):
                    ucc = inc(c)
                    _hy_anon_var_15 = None
                else:
                    _hy_anon_var_15 = None
        return ucc

    def used_row_count(self):
        'Returns the number of the last row with content, starts with 0 if none is used'
        urc = 0
        for r in range(self.rowCount()):
            for c in range(self.columnCount()):
                item = self.item(r, c)
                if ((item != None) and is_pos(len(item.text())) and (r >= urc)):
                    urc = inc(r)
                    _hy_anon_var_16 = None
                else:
                    _hy_anon_var_16 = None
        return urc

    def set_header_style(self, bold):
        'Bool -> Bool\n     Consumes the if style of header is bold or not\n     returns global state'
        for col in range(self.columnCount()):
            item = self.item(0, col)
            if (item != None):
                font = item.font()
                font.setBold(bold)
                _hy_anon_var_17 = item.setFont(font)
            else:
                _hy_anon_var_17 = None
        return globals

    def eventFilter(self, object, ev):
        if ((ev.type() == QEvent.FocusOut) and (ev.reason() == ACTIVEWINDOWFOCUSREASON)):
            debug('QtCore.QEvent.FocusOut')
            debug(ev.lostFocus())
            debug(ev.reason())
            _hy_anon_var_18 = self.on_focus_lost(ev)
        else:
            _hy_anon_var_18 = None
        return False

    def on_focus_lost(self, ev):
        self.save_sheet_csv(globals['filepath'])
        return self.set_title()

    def set_changed(self):
        reset_bang(globals, 'filechanged', True)
        self.set_title()
        return log('set_changed')

    def clear(self):
        self.blockSignals(True)
        self.clearContents()
        self.init_cells()
        return self.blockSignals(False)

    def parse_for_paste(self, clipboard_text):
        "String -> List[][]\n    Consumes a String clipboard-text and produces a 2-dimensional list with\n    lines and columns. Example:\n    'Test\tTest\tTest\n1\t1\t2\t3' -> [['Test', 'Test', 'Test'], ['1', '2', '3']]"
        paste_list = []
        row = []
        lns = clipboard_text.strip().split('\n')
        debug(lns)
        for ln in lns:
            debug(ln)
            paste_list.append(ln.split('\t'))
        return paste_list

    def map_paste_list(self, lst, start_row, start_col, func):
        'list function -> Void\n    Cycles through a paste-list and uses function func on each cell'
        pl_rnr = 0
        for row in range(start_row, (start_row + len(lst))):
            pl_cnr = 0
            for col in range(start_col, (start_col + len(lst[pl_rnr]))):
                self.blockSignals(True)
                func(lst, pl_rnr, pl_cnr, row, col)
                self.blockSignals(False)
                pl_cnr = inc(pl_cnr)
            self.update_preview()
            self.set_changed()
            pl_rnr = inc(pl_rnr)
