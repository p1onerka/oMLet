let large x = if 0<>x then print_int 0 else print_int 1
   let main =
     let x = if (if (if 0 =1
                     then 0 else (let t42 = print_int 42 in 1)) = 1
                then 0 else 1) = 1
             then 0 else 1 in
     large x
