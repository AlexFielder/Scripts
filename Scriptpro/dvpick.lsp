;;Written Mitch Paulk May 1999
;;This lisp temporarily uses a UCS, so be careful if the command is canceled or
;;undone using UNDO.  

(defun c:DVPICK (/ vangle vsize vcenter)
  (setq oldcmd (getvar "cmdecho"))
  (setvar "cmdecho" 0)
	
(setq vsize (getvar "viewsize"))
	(setq vcenter (getvar "viewctr"))

 (princ "\nThe Object selected will be rotated horizontal using DView Twist...")

     (command "ucs" "ob" pause)
        (command "plan" "")
           (command "ucs" "")            
  (setvar "cmdecho" oldcmd)
 (princ)

; Set the snapangle to the negative value of the viewtwist so that 
; the crosshairs will be horizontal.

  (setq vangle (getvar "viewtwist"))      ;The viewtwist in radians
  (setq vangle (/ (* vangle -180.0) PI))  ;convert it to degrees and multiply by -1

     (progn
      (command "SNAPANG" vangle)
		(command "zoom" "c" vcenter vsize)
    )
 (setvar "cmdecho" oldcmd)
 (princ)
)