from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need
# fine tuning.
buildOptions = dict(packages = ["fractions"], excludes = [])

import sys
base = 'Win32GUI' if sys.platform=='win32' else None

executables = [
    Executable('tablao.py', base=base)
]

setup(name='Tablao',
      version = '0.1',
      description = 'Table Editor that spits out html',
      options = dict(build_exe = buildOptions),
      executables = executables)
