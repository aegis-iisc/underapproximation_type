let rec goal (inv : int) (c : bool) (height : int) =
  (if c
   then
     Rbtnode
       (true, (goal (int_gen ()) true inv), (increment height),
         (goal (increment inv) false (increment height)))
   else
     if c
     then
       Rbtnode
         (true, (goal (int_gen ()) c (increment (int_gen ()))), (int_gen ()),
           (goal r false inv))
     else
       if c
       then
         Rbtnode
           (true, (goal (increment inv) false (increment inv)), inv,
             (goal (increment inv) false (increment inv)))
       else
         if c
         then
           Rbtnode
             (true, (goal r c (int_gen ())), (increment (int_gen ())),
               (goal (int_gen ()) false height))
         else
           if lt_eq_one inv
           then
             Rbtnode
               (true, (goal inv c (increment (int_gen ()))),
                 (increment (int_gen ())), (goal (int_gen ()) c inv))
           else
             Rbtnode
               (true, (goal r c (increment inv)), (increment inv),
                 (goal (int_gen ()) false (int_gen ()))) : int rbtree)
