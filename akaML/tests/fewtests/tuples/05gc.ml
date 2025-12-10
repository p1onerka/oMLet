let abc =
  let _1 = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 in
  let _2 = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 in
  let _3 = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 in
  3
;;

let main =
  let _ = print_int abc in
  let _ = print_gc_status () in
  let _ = collect () in
  print_gc_status ()
;;
