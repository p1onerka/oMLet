let f (a, b) = a + b

let main =
  let sum = f (1, 2) in
  let _ = print_gc_status () in
  let _ = print_int sum in
  let _ = collect () in
  print_gc_status ()
;;
