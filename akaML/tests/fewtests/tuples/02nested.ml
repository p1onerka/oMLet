let f (a, (b, c), e) = c

let main =
  let c3 = f (1, (2, 3), 4) in
  print_int c3
;;
