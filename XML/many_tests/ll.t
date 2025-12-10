  $ dune exec ./../bin/XML.exe -- --ll <<EOF
  > let rec fac n = if n = 0 then 1 else n * fac (n - 1)
  > 
  > let main = print_int (fac 4)
  let rec fac = fun n -> let t_0 = (n = 0)
                           in let t_4 = if t_0 then 1 else let t_1 = (n - 1)
                                                             in let t_2 = fac t_1
                                                                  in let t_3 = (n * t_2)
                                                                      in t_3
                                in t_4;;
  let main = let t_6 = fac 4 in let t_7 = print_int t_6 in t_7;;

  $ cat manytests/typed/004manyargs.ml
  let wrap f = if 1 = 1 then f else f
  
  let test3 a b c =
    let a = print_int a in
    let b = print_int b in
    let c = print_int c in
    0
  
  let test10 a b c d e f g h i j = a + b + c + d + e + f + g + h + i + j
  
  let main =
    let rez =
        (wrap test10 1 10 100 1000 10000 100000 1000000 10000000 100000000
           1000000000)
    in
    let () = print_int rez in
    let temp2 = wrap test3 1 10 100 in
    0
  
  $ ../bin/XML.exe --ll -fromfile manytests/typed/004manyargs.ml
  let wrap = fun f -> let t_0 = (1 = 1)
                        in let t_1 = if t_0 then f else f in t_1;;
  let test3 = fun a b
                c -> let t_3 = print_int a
                       in let a = t_3
                            in let t_4 = print_int b
                                 in let b = t_4
                                      in let t_5 = print_int c
                                           in let c = t_5 in 0;;
  let test10 = fun a b c d e f g h i
                 j -> let t_7 = (a + b)
                        in let t_8 = (t_7 + c)
                             in let t_9 = (t_8 + d)
                                  in let t_10 = (t_9 + e)
                                       in let t_11 = (t_10 + f)
                                            in let t_12 = (t_11 + g)
                                                 in let t_13 = (t_12 + h)
                                                      in let t_14 = (t_13 + i)
                                                           in let t_15 = (t_14 + j)
                                                                in t_15;;
  let main = let t_17 = wrap test10
               in let t_18 = t_17 1
                    in let t_19 = t_18 10
                         in let t_20 = t_19 100
                              in let t_21 = t_20 1000
                                   in let t_22 = t_21 10000
                                        in let t_23 = t_22 100000
                                             in let t_24 = t_23 1000000
                                                  in let t_25 = t_24 10000000
                                                       in let t_26 = t_25 100000000
                                                            in let t_27 = t_26 1000000000
                                                                 in let rez = t_27
                                                                      in 
                                                                      let t_28 = print_int rez
                                                                      in 
                                                                      let t_29 = wrap test3
                                                                      in 
                                                                      let t_30 = t_29 1
                                                                      in 
                                                                      let t_31 = t_30 10
                                                                      in 
                                                                      let t_32 = t_31 100
                                                                      in 
                                                                      let temp2 = t_32
                                                                      in 0;;


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

  $ ../bin/XML.exe --ll -fromfile manytests/typed/010fibcps_ll.ml
  let id = fun x -> x;;
  let fresh_2 = fun p1 k p2 -> let t_1 = (p1 + p2) in let t_2 = k t_1 in t_2;;
  let fresh_1 = fun n k fib
                  p1 -> let t_4 = (n - 2)
                          in let t_5 = fib t_4
                               in let t_6 = fresh_2 p1
                                    in let t_7 = t_6 k
                                         in let t_8 = t_5 t_7 in t_8;;
  let rec fib = fun n
                  k -> let t_10 = (n < 2)
                         in let t_18 = if t_10 then let t_11 = k n in t_11 else 
                                         let t_12 = (n - 1)
                                           in let t_13 = fib t_12
                                                in let t_14 = fresh_1 n
                                                     in let t_15 = t_14 k
                                                          in let t_16 = t_15 fib
                                                               in let t_17 = t_13 t_16
                                                                    in t_17
                              in t_18;;
  let main = let t_20 = fib 6
               in let t_21 = t_20 id
                    in let t_22 = print_int t_21 in let z = t_22 in 0;;

