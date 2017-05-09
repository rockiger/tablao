from hy.core.language import dec, is_zero

def qtable_to_html(qtable, header):
    'QTableWidget Bool -> String\n   Consumes a QTableWidget qtable and if header is true\n   produces a string with that table in HTML'

    def first_row():
        return (1 if header else 0)

    def parse_rows(qtable, row, cols):
        'QTableWidget Int Int -> String\n    Consumes a QTableWidget, the current of the row and number of columns,\n    iterates over its rows and produces the rows in html'
        return ((((('\n    <tr>' + parse_cols(qtable, row, cols)) + '\n    </tr>') if ('' != parse_cols(qtable, row, cols)) else '') if (row == first_row()) else ((((parse_rows(qtable, dec(row), cols) + '\n    <tr>') + parse_cols(qtable, row, cols)) + '\n    </tr>') if ('' != parse_cols(qtable, row, cols)) else (parse_rows(qtable, dec(row), cols) + parse_cols(qtable, row, cols)))) if ((not header) or (qtable.used_row_count() > 1)) else '')

    def parse_cols(qtable, row, col):
        'QTableWidget Int Int -> String\n    Consumes a QTableWidget, the current of row and column,\n    iterates over its rows and produces the rows in html'
        return (parse_item(qtable, row, col) if is_zero(col) else (parse_cols(qtable, row, dec(col)) + parse_item(qtable, row, col)))

    def parse_item(qtable, row, col):
        'QTableWidget Int Int -> String\n    Consumes a QTableWidget, the current of row and column,\n    produces the row in html'
        item = qtable.item(row, col)
        return ((('\n      <td>' + item.text()) + '</td>') if (item != None) else '\n      <td></td>')

    def parse_headercols(qtable, row, col):
        'QTableWidget Int Int -> String\n    Consumes a QTableWidget, the current of row and column,\n    iterates over the header rows and produces the row in html'
        return (parse_headeritem(qtable, row, col) if is_zero(col) else (parse_headercols(qtable, row, dec(col)) + parse_headeritem(qtable, row, col)))

    def parse_headeritem(qtable, row, col):
        'QTableWidget Int Int -> String\n    Consumes a QTableWidget, the current of row and column,\n    produces the header row in html'
        item = qtable.item(row, col)
        return ((('\n      <th>' + item.text()) + '</th>') if (item != None) else '\n      <th></th>')
    return ('' if (is_zero(qtable.used_column_count()) or is_zero(qtable.used_row_count())) else (((('<table>\n' + ((('  <thead>\n    <tr>' + parse_headercols(qtable, 0, dec(qtable.used_column_count()))) + '\n    </tr>\n  </thead>\n') if first_row() else '')) + '  <tbody>') + parse_rows(qtable, dec(qtable.used_row_count()), dec(qtable.used_column_count()))) + '\n  </tbody>\n</table>'))

def create_preview(qtable, is_theader, header, footer):
    'QTableWidget Bool String String -> String\n     Consumes a QTableWidget qtable, if the tableheader theader is true, the strings for the header and footer of the html\n     produces a string with that documen in HTML'
    return ((header + qtable_to_html(qtable, is_theader)) + footer)
