(defn qtable-to-html [qtable header]
  "QTableWidget Bool -> String
   Consumes a QTableWidget qtable and if header is true
   produces a string with that table in HTML"

  (defn first_row []
    (if header
      1
      0))

  (defn parse-rows [qtable row cols]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of the row and number of columns,
    iterates over its rows and produces the rows in html"
    (if (or (not header) (> (.used_row_count qtable) 1))
      (if (= row (first_row))
        (if (!= "" (parse-cols qtable row cols))
          (+ "\n    <tr>" (parse-cols qtable row cols) "\n    </tr>")
          "")
        (if (!= "" (parse-cols qtable row cols))
          (+ (parse-rows qtable (dec row) cols)
             "\n    <tr>" (parse-cols qtable row cols) "\n    </tr>")
          (+ (parse-rows qtable (dec row) cols) (parse-cols qtable row cols))))
      ""))

  (defn parse-cols [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    iterates over its rows and produces the rows in html"
    (if (zero? col)
      (parse-item qtable row col)
      (+ (parse-cols qtable row (dec col)) (parse-item qtable row col))))

  (defn parse-item [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    produces the row in html"
    (setv item (.item qtable row col))
    (if (!= item None)
        (+ "\n      <td>" (.text item) "</td>")
        "\n      <td></td>"))

  (defn parse-headercols [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    iterates over the header rows and produces the row in html"
    (if (zero? col)
      (parse-headeritem qtable row col)
      (+ (parse-headercols qtable row (dec col)) (parse-headeritem qtable row col))))

  (defn parse-headeritem [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    produces the header row in html"
    (setv item (.item qtable row col))
    (if (!= item None)
        (+ "\n      <th>" (.text item) "</th>")
        "\n      <th></th>"))
  ;; look for a table with 0 rows or 0 columns
  (if (or (zero? (.used_column_count qtable)) (zero? (.used_row_count qtable)))
    ""
    (+ "<table>\n"
       (if (first_row)
          (+ "  <thead>\n    <tr>"
            (parse-headercols qtable 0 (dec (.used_column_count qtable)))
            "\n    </tr>\n  </thead>\n")
          "")
       "  <tbody>"
       (parse-rows qtable
                   (dec (.used_row_count qtable))
                   (dec (.used_column_count qtable)))
       "\n  </tbody>\n</table>")))

(defn create_preview [qtable theader? header footer]
    "QTableWidget Bool String String -> String
     Consumes a QTableWidget qtable, if the tableheader theader is true, the strings for the header and footer of the html
     produces a string with that documen in HTML"
     (+ header (qtable-to-html qtable theader?) footer))
