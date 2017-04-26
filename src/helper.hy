#! /usr/bin/env hy

;; =================
;; Helper
;; =================

(defn log [&rest params]
  (apply print params))

(defn debug [&rest params]
  (apply print params)
  False)
