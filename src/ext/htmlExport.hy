(defn qtable->html [qtable header]
  "QTableWidget Bool -> String
   Consumes a QTableWidget qtable and if header is true
   produces a string with that table in HTML"

  (defn first_row []
    (if header
      1
      0))

  (defn parse-rows [qtable row cols]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the curren of the row and number of columns,
    iterates over its rows and produces the rows in html"
    (if (= row (first_row))
      (if (!= "" (parse-cols qtable row cols))
        (+ "<tr>\n" (parse-cols qtable row cols) "\n</tr>")
        "")
      (if (!= "" (parse-cols qtable row cols))
        (+ (parse-rows qtable (dec row) cols)
           "\n<tr>\n" (parse-cols qtable row cols) "\n</tr>")
        (+ (parse-rows qtable (dec row) cols) (parse-cols qtable row cols)))))

  (defn parse-cols [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    iterates over its rows and produces the rows in html"
    (if (= col 0)
      (parse-item qtable row col)
      (+ (parse-cols qtable row (dec col)) (parse-item qtable row col))))

  (defn parse-item [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    produces the row in html"
    (let [item (.item qtable row col)]
      (if (!= item None)
          (+ "<td>" (.text item) "</td>")
          "<td></td>")))

  (defn parse-headercols [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    iterates over the header rows and produces the row in html"
    (if (= col 0)
      (parse-headeritem qtable row col)
      (+ (parse-headercols qtable row (dec col)) (parse-headeritem qtable row col))))

  (defn parse-headeritem [qtable row col]
    "QTableWidget Int Int -> String
    Consumes a QTableWidget, the current of row and column,
    produces the header row in html"
    (let [item (.item qtable row col)]
      (if (!= item None)
          (+ "<th>" (.text item) "</th>")
          "<th></th>")))

  (+ "<table>\n"
     (if (first_row)
        (+ "<thead>\n<tr>\n"
          (parse-headercols qtable 0 (.used_column_count qtable))
          "</tr></thead>\n")
        "")
     "<tbody>\n"
     (parse-rows qtable
                 (.used_row_count qtable)
                 (.used_column_count qtable))
     "\n</tbody>\n</table>"))
