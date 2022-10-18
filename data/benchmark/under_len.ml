let[@library] eq =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (iff v (a == b) : [%v: bool])

let[@library] neq =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (iff v (a != b) : [%v: bool])

let[@library] lt =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (iff v (a < b) : [%v: bool])

let[@library] gt =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (iff v (a > b) : [%v: bool])

let[@library] le =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (iff v (a <= b) : [%v: bool])

let[@library] ge =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (iff v (a >= b) : [%v: bool])

let[@library] plus =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (v == a + b : [%v: int])

let[@library] minus =
  let (a : [%over: int]) = (true : [%v: int]) in
  let (b : [%over: int]) = (true : [%v: int]) in
  (v == a - b : [%v: int])

let[@library] tt = (true : [%v: unit])
let[@library] nil = (len v 0 : [%v: int list])

let[@library] cons =
  let (dummy : [%under: int]) = (true : [%v: int]) in
  let (s : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int list]) = (len v s : [%v: int list]) in
  (fun (u : [%forall: int]) -> implies (u == s + 1) (len v u) : [%v: int list])

let[@library] batchedq =
  let (s1 : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int list]) = (len v s1 : [%v: int list]) in
  let (s2 : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int list]) =
    (fun (u : [%forall: int]) -> implies (0 <= u && u <= s1) (len v u)
      : [%v: int list])
  in
  (len v s1 : [%v: int batchedq])

let[@library] leaf = (len v 0 : [%v: int tree])

let[@library] node =
  let (dummy : [%under: int]) = (true : [%v: int]) in
  let (sizel : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int tree]) =
    (fun (u : [%forall: int]) -> len v sizel : [%v: int tree])
  in
  let (sizer : [%over: int]) = (v == sizel : [%v: int]) in
  let (dummy : [%under: int tree]) =
    (fun (u : [%forall: int]) -> len v sizer : [%v: int tree])
  in
  (fun (u : [%forall: int]) -> implies (u == sizel + 1) (len v u)
    : [%v: int tree])

(* color black *)
let[@library] rbtleaf = (len v 0 : [%v: int rbtree])

let[@library] rbtnode =
  let (c : [%over: bool]) = (not v : [%v: bool]) in
  let (sizel : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int rbtree]) =
    (len v sizel && implies (sizel == 0) (hdcolor v true) : [%v: int rbtree])
  in
  let (dummy : [%under: int]) = (true : [%v: int]) in
  let (sizer : [%over: int]) = (v == sizel : [%v: int]) in
  let (dummy : [%under: int rbtree]) =
    (len v sizer && implies (sizer == 0) (hdcolor v true) : [%v: int rbtree])
  in
  (fun (u : [%forall: int]) ->
     hdcolor v false && implies (u == sizel + 1) (len v u)
    : [%v: int rbtree])

(* color red *)
let[@library] rbtnode =
  let (c : [%over: bool]) = (v : [%v: bool]) in
  let (sizel : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int rbtree]) =
    (len v sizel && hdcolor v false : [%v: int rbtree])
  in
  let (dummy : [%under: int]) = (true : [%v: int]) in
  let (sizer : [%over: int]) = (v == sizel : [%v: int]) in
  let (dummy : [%under: int rbtree]) =
    (len v sizer && hdcolor v false : [%v: int rbtree])
  in
  (hdcolor v true && len v sizel : [%v: int rbtree])

(* heap *)
let[@library] hempty = (len v 0 : [%v: int heap])

let[@library] hnode =
  let (root : [%over: int]) = (true : [%v: int]) in
  let (sizel : [%over: int]) = (v >= 0 : [%v: int]) in
  let (dummy : [%under: int heap]) =
    (fun (u : [%forall: int]) ->
       len v sizel && heap v && implies (hd v u) (u <= root)
      : [%v: int heap])
  in
  let (sizer : [%over: int]) = (v == sizel : [%v: int]) in
  let (dummy : [%under: int heap]) =
    (fun (u : [%forall: int]) ->
       len v sizer && heap v && implies (hd v u) (u <= root)
      : [%v: int heap])
  in
  (fun (u : [%forall: int]) ->
     hd v root && heap v && implies (u == sizel + 1) (len v u)
    : [%v: int heap])
