let[@library] eq =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (iff v (a == b) : [%v: bool])

let[@library] neq =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (iff v (a != b) : [%v: bool])

let[@library] lt =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (iff v (a < b) : [%v: bool])

let[@library] gt =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (iff v (a > b) : [%v: bool])

let[@library] le =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (iff v (a <= b) : [%v: bool])

let[@library] ge =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (iff v (a => b) : [%v: bool])

let[@library] plus =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (v == a + b : [%v: int])

let[@library] minus =
  let (a : [%poly: int]) = () in
  let (b : [%poly: int]) = () in
  (v == a - b : [%v: int])

let[@library] nil = (fun (u : [%forall: int]) -> not (mem v u) : [%v: int list])

let[@library] cons =
  let (h : [%poly: int]) = () in
  let t =
    (fun (u : [%forall: int]) ->
       iff (hd v u) (u == h) && implies (mem v u) (u == h)
      : [%v: int list])
  in
  (fun (u : [%forall: int]) ->
     implies (mem v u) (u == h) && iff (hd v u) (u == h)
    : [%v: int list])

let[@library] ileaf =
  (fun (u : [%forall: int]) -> not (mem v u) : [%v: int_tree])

let[@library] _ret_two_value =
  let x = (v > 0 : [%v: int]) in
  (v == 1 || v == x : [%v: int])
