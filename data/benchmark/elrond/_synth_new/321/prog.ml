let rec goal (size : int) (x0 : int) =
  (if sizecheck size
   then Unil
   else (subs x0) +:: (goal (subs x0) (subs size1)) : int ulist)
