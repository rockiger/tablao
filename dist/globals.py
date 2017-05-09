from PyQt5.QtCore import QSettings
globals = {'header': True, 'preview': True, 'settings': QSettings('Rockiger', 'Tablao'), 'filepath': './Welcome-To-Tablao.csv', 'filechanged': False, 'table': None, 'webview': None, 'clipboard': None, 'second-run': False, }

def reset_bang(state, key, new_value):
    'Dict String Object -> Dict\n   Consumes a state dictionary, a key and the new value for that key.\n   Returns the new state object'
    state[key] = new_value
    return state
