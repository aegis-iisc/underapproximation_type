let rec goal (size : int) (x0 : int) =
  (if sizecheck x0
   then goal (subs x0) (subs size1)
   else (subs size) +:: (goal size1 (subs x0)) : int ulist)
