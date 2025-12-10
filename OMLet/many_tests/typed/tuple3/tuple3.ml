let t = (1, (2, (3, (4, (5, (6, (7, (8, 9, fun x -> x * 2) ))))))) in
let a, (b, (c, (d, (e, (f, (g, (h, i, j))))))) = t in
print_int (j (a + b + c + d + e + f + g + h + i))