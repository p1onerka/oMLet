let rec fac n =
  if n <= 1
  then 1
  else let n1 = n-1 in
          let m = fac n1 in
          n*m
let main = fac 4
