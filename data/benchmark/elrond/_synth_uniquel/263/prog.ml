let rec goal (size : int) (x0 : int) =
  (if sizecheck x0
   then x0 +:: (goal (subs size) x0)
   else x0 +:: (x0 +:: Unil) : int ulist)
