let rec goal (inv : int) (c : bool) (height : int) =
  (if lt_eq_one height
   then
     Rbtnode
       (true, (goal (increment inv) false height), (increment height),
         (goal (increment inv) false height))
   else
     Rbtnode
       (true, (goal (increment inv) false height), (increment (int_gen ())),
         (goal (increment (int_gen ())) true inv)) : int rbtree)
