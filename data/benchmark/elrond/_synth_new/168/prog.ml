let rec goal (size : int) (x0 : int) =
  (if sizecheck x0
   then (subs size) +:: (goal (subs x0) (subs size1))
   else goal (subs size) (subs size1) : int ulist)
