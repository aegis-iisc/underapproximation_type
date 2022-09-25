let balance =
  let color = (true : [%v: bool]) in
  let left =
    (fun (u : [%forall: int]) -> implies (mem v u) (hd v u) : [%v: int rbset])
  in
  let elem =
    (fun (u : [%forall: int]) -> implies (hd left u) (u == v) : [%v: int])
  in
  let right =
    (fun (u : [%forall: int]) -> implies (mem v u) (hd left u)
      : [%v: int rbset])
  in
  (fun (u : [%forall: int]) -> implies (mem v u) (hd left u) : [%v: int rbset])
