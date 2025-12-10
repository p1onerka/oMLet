let t = 1, 2, (3, (4, 5)), 6

let main =
  let a, b, (c, (d, e)), f = t in
  print_int c
;;
