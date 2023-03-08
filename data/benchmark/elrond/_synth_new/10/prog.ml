let rec goal (size : int) (x0 : int) =
  (if sizecheck x0
   then goal (subs size) x0
   else x0 +:: (goal (subs x0) (subs size)) : int ulist)
