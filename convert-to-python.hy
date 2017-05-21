#! /usr/bin/env hy
(import [os [chdir getcwdb listdir system]])

(chdir "./src")
(print (getcwdb))
(print (listdir))

(for [file (listdir)]
  (when (.endswith file ".hy")
    (setv cmd (+ "hy2py " file " > ../dist/" (cut file 0 -2) "py"))
    (print cmd)
    (system cmd)))

(chdir "./ext")

(for [file (listdir)]
  (when (.endswith file ".hy")
    (setv cmd (+ "hy2py " file " > ../../dist/ext/" (cut file 0 -2) "py"))
    (print cmd)
    (system cmd)))
