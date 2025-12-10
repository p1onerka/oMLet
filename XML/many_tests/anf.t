  $ dune exec ./../bin/XML.exe -- --anf <<EOF
  > let rec fac n = if n = 0 then 1 else n * fac (n - 1)
  > 
  > let main = print_int (fac 4)
  let rec fac = let t_5 = fun n -> let t_0 = (n = 0)
                                     in let t_4 = if t_0 then 1 else let t_1 = (n - 1)
                                                                      in 
                                                                      let t_2 = fac t_1
                                                                      in 
                                                                      let t_3 = (n * t_2)
                                                                      in t_3
                                          in t_4 in t_5;;
  let main = let t_6 = fac 4 in let t_7 = print_int t_6 in t_7;;

  $ ../bin/XML.exe --anf <<EOF
  > let rec fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
  > 
  > let main = print_int (fib 6)
  let rec fib = let t_7 = fun n -> let t_0 = (n < 2)
                                     in let t_6 = if t_0 then n else let t_1 = (n - 1)
                                                                      in 
                                                                      let t_2 = fib t_1
                                                                      in 
                                                                      let t_3 = (n - 2)
                                                                      in 
                                                                      let t_4 = fib t_3
                                                                      in 
                                                                      let t_5 = (t_2 + t_4)
                                                                      in t_5
                                          in t_6 in t_7;;
  let main = let t_8 = fib 6 in let t_9 = print_int t_8 in t_9;;

  $ ../bin/XML.exe --anf <<EOF
  > let large x = if 0<>x then print_int 0 else print_int 1
  > let main =
  >   let x = if (if (if 0 = 1
  >                   then 0 = 1 else (let t42 = print_int 42 in 1 = 1))
  >               then 0 = 1 else 1 = 1)
  >           then 0 else 1 in
  >   large x
  let large = let t_4 = fun x -> let t_0 = (0 <> x)
                                   in let t_3 = if t_0 then let t_1 = print_int 0
                                                              in t_1 else 
                                                  let t_2 = print_int 1 in t_2
                                        in t_3 in t_4;;
  let main = let t_5 = (0 = 1)
               in let t_9 = if t_5 then let t_6 = (0 = 1) in t_6 else let t_7 = print_int 42
                                                                      in 
                                                                      let t42 = t_7
                                                                      in 
                                                                      let t_8 = (1 = 1)
                                                                      in t_8
                    in let t_12 = if t_9 then let t_10 = (0 = 1) in t_10 else 
                                    let t_11 = (1 = 1) in t_11
                         in let t_13 = if t_12 then 0 else 1
                              in let x = t_13 in let t_14 = large x in t_14;;

  $ cat manytests/typed/010fibcps_ll.ml
  let id x = x
  let fresh_2 p1 k p2 =
    k (p1 + p2)
  
  let fresh_1 n k fib p1 =
    fib (n-2) (fresh_2 p1 k)
  
  let rec fib n k =
    if n < 2
    then k n
    else fib (n - 1) (fresh_1 n k fib)
  
  let main =
    let z = print_int (fib 6 id)  in
    0

  $ ../bin/XML.exe --anf -fromfile manytests/typed/010fibcps_ll.ml
  let id = let t_0 = fun x -> x in t_0;;
  let fresh_2 = let t_3 = fun p1 k
                            p2 -> let t_1 = (p1 + p2) in let t_2 = k t_1 in t_2
                  in t_3;;
  let fresh_1 = let t_9 = fun n k fib
                            p1 -> let t_4 = (n - 2)
                                    in let t_5 = fib t_4
                                         in let t_6 = fresh_2 p1
                                              in let t_7 = t_6 k
                                                   in let t_8 = t_5 t_7 in t_8
                  in t_9;;
  let rec fib = let t_19 = fun n
                             k -> let t_10 = (n < 2)
                                    in let t_18 = if t_10 then let t_11 = k n
                                                                 in t_11 else 
                                                    let t_12 = (n - 1)
                                                      in let t_13 = fib t_12
                                                           in let t_14 = fresh_1 n
                                                                in let t_15 = t_14 k
                                                                     in 
                                                                     let t_16 = t_15 fib
                                                                      in 
                                                                      let t_17 = t_13 t_16
                                                                      in t_17
                                         in t_18 in t_19;;
  let main = let t_20 = fib 6
               in let t_21 = t_20 id
                    in let t_22 = print_int t_21 in let z = t_22 in 0;;

  $ dune exec ./../bin/XML.exe -- --anf <<EOF
  > let main =
  >   let t = (10, 20) in
  >   let (a, b) = t in
  >   print_int (a + b)
  let main = let t_0 = alloc(10,  20)
               in let t = t_0
                    in let t_1 = t
                         in let t_5 = t_1[0]
                              in let a = t_5
                                   in let t_4 = t_1[8]
                                        in let b = t_4
                                             in let t_2 = (a + b)
                                                  in let t_3 = print_int t_2
                                                       in t_3;;

  $ dune exec ./../bin/XML.exe -- --anf <<EOF
  > let main =
  >   let t = (1, (2, 3)) in
  >   let (a, (b, c)) = t in
  >   print_int (a + b + c)
  let main = let t_0 = alloc(2,  3)
               in let t_1 = alloc(1,  t_0)
                    in let t = t_1
                         in let t_2 = t
                              in let t_9 = t_2[0]
                                   in let a = t_9
                                        in let t_6 = t_2[8]
                                             in let t_8 = t_6[0]
                                                  in let b = t_8
                                                       in let t_7 = t_6[8]
                                                            in let c = t_7
                                                                 in let t_3 = (a + b)
                                                                      in 
                                                                      let t_4 = (t_3 + c)
                                                                      in 
                                                                      let t_5 = print_int t_4
                                                                      in t_5;;

  $ dune exec ./../bin/XML.exe -- --anf <<EOF
  > let swap p =
  >   let (x, y) = p in
  >   (y, x)
  > let main = 
  >   let p = (1, 2) in
  >   swap p
  let swap = let t_4 = fun p -> let t_0 = p
                                  in let t_3 = t_0[0]
                                       in let x = t_3
                                            in let t_2 = t_0[8]
                                                 in let y = t_2
                                                      in let t_1 = alloc(y,  x)
                                                           in t_1 in t_4;;
  let main = let t_5 = alloc(1,  2) in let p = t_5 in let t_6 = swap p in t_6;;
