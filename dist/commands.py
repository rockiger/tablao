from hy.core.language import inc
import copy
from helper import *
from constants import *
from globals import *
from PyQt5.QtWidgets import QUndoCommand


class Command_Paste(QUndoCommand):

    def __init__(self, table, start_row, start_col, paste_list, description):
        super(Command_Paste, self).__init__(description)
        self.table = table
        self.start_row = start_row
        self.start_col = start_col
        self.paste_list = copy.deepcopy(paste_list)
        self.undo_list = copy.deepcopy(paste_list)
        self.gather_undo_information()
        return None

    def redo(self):

        def _hy_anon_fn_2(lst, pl_rnr, pl_cnr, row, col):
            val = self.paste_list[pl_rnr][pl_cnr]
            if (val == None):
                item_text = ''
                _hy_anon_var_1 = None
            else:
                item_text = val
                _hy_anon_var_1 = None
            debug(item_text)
            return self.table.item(row, col).setText(item_text)
        return self.table.map_paste_list(self.paste_list, self.start_row, self.start_col, _hy_anon_fn_2)

    def undo(self):
        debug(self.undo_list)

        def _hy_anon_fn_4(lst, pl_rnr, pl_cnr, row, col):
            val = self.undo_list[pl_rnr][pl_cnr]
            debug(val)
            if (val == None):
                item_text = ''
                _hy_anon_var_2 = None
            else:
                item_text = val
                _hy_anon_var_2 = None
            debug(item_text)
            return self.table.item(row, col).setText(item_text)
        return self.table.map_paste_list(self.undo_list, self.start_row, self.start_col, _hy_anon_fn_4)

    def gather_undo_information(self):
        debug(self.paste_list)

        def _hy_anon_fn_6(lst, pl_rnr, pl_cnr, row, col):
            undo_row = lst[pl_rnr]
            undo_row[pl_cnr] = self.table.item(row, col).text()
        self.table.map_paste_list(self.undo_list, self.start_row, self.start_col, _hy_anon_fn_6)
        self.paste_list = copy.deepcopy(self.paste_list)
        log('GATHER-UNDO-INFORMATION')
        debug(self.undo_list)
        return debug(self.paste_list)


class Command_Delete(QUndoCommand):

    def __init__(self, table, description):
        super(Command_Delete, self).__init__(description)
        self.table = table
        self.gather_undo_information()
        return None

    def redo(self):
        for item in self.table.selectedItems():
            self.table.blockSignals(True)
            item.setText('')
            self.table.blockSignals(True)
            self.table.update_preview()
            self.table.set_changed()

    def undo(self):
        for r in self.undo_ranges:

            def _hy_anon_fn_10(lst, pl_rnr, pl_cnr, row, col):
                val = r['\ufdd0:undo-list'][pl_rnr][pl_cnr]
                debug(val)
                if (val == None):
                    item_text = ''
                    _hy_anon_var_3 = None
                else:
                    item_text = val
                    _hy_anon_var_3 = None
                debug(item_text)
                return self.table.item(row, col).setText(item_text)
            self.table.map_paste_list(r['\ufdd0:undo-list'], r['\ufdd0:start-row'], r['\ufdd0:start-col'], _hy_anon_fn_10)

    def gather_undo_information(self):
        self.undo_ranges = []
        for r in self.table.selectedRanges():
            row_list = []
            for row in range(r.topRow(), inc(r.bottomRow())):
                col_list = []
                for col in range(r.leftColumn(), inc(r.rightColumn())):
                    item = self.table.item(row, col).text()
                    col_list.append(item)
                row_list.append(col_list)
            self.undo_ranges.append({'\ufdd0:undo-list': row_list, '\ufdd0:start-row': r.topRow(), '\ufdd0:start-col': r.leftColumn(), })


class Command_Cell_Edit(QUndoCommand):

    def __init__(self, table, cell, description):
        super(Command_Cell_Edit, self).__init__(description)
        self.table = table
        self.cell = copy.deepcopy(cell)
        return None

    def redo(self):
        debug(self.cell)
        return self.table.item(self.cell['\ufdd0:row'], self.cell['\ufdd0:col']).setText(self.cell['\ufdd0:new'])

    def undo(self):
        debug(self.cell)
        return self.table.item(self.cell['\ufdd0:row'], self.cell['\ufdd0:col']).setText(self.cell['\ufdd0:old'])
