; Reusable native Cadence drawing helpers. Load in Virtuoso CIW.
; R0 configured templates; lowercase terminal aliases; Manhattan routes.

procedure(CDTerm(inst candidates)
  let((found)
    foreach(term inst~>master~>terminals
      when(member(lowerCase(term~>name) candidates) found=term)
    )
    unless(found
      error("Unknown pin mapping on %s/%s: wanted %L; available %L\n"
        inst~>libName inst~>cellName candidates inst~>master~>terminals~>name))
    found
  )
)

procedure(CDPoint(inst candidates)
  let((term pin)
    term=CDTerm(inst candidates)
    pin=car(term~>pins)
    unless(pin && pin~>fig error("No symbol pin figure on %s.\n" term~>name))
    dbTransformPoint(centerBox(pin~>fig~>bBox) inst~>transform)
  )
)

procedure(CDInst(cv cell name origin orient propName value)
  let((master inst)
    master=dbOpenCellViewByType("analogLib" cell "symbol" "schematicSymbol" "r")
    unless(master error("Missing analogLib/%s/symbol.\n" cell))
    inst=dbCreateInst(cv master name origin orient)
    unless(inst error("Could not place %s.\n" name))
    when(propName dbReplaceProp(inst propName "string" value))
    inst
  )
)

procedure(CDCopyConfigured(cv template origin)
  let((delta inst)
    delta=list(xCoord(origin)-xCoord(template~>xy)
               yCoord(origin)-yCoord(template~>xy))
    inst=dbCopyFig(template cv list(delta "R0" 1.0))
    unless(inst error("Could not copy configured transistor.\n"))
    inst
  )
)

procedure(CDWire(cv points netName)
  let((clean previous wires)
    ; Remove consecutive duplicates; all supplied routes are Manhattan.
    foreach(point points
      unless(equal(point previous) clean=cons(point clean))
      previous=point
    )
    clean=reverse(clean)
    when(length(clean)>1
      wires=schCreateWire(cv "draw" "full" clean 0.0625 0.0625 0.0)
      unless(wires error("Could not draw wire %s.\n" netName))
      when(netName
        schCreateWireLabel(cv car(wires) car(clean)
          netName "lowerLeft" "R0" "stick" 0.125 nil)
      )
    )
    wires
  )
)

procedure(CDJoin(cv a b netName)
  CDWire(cv list(a list(xCoord(a) yCoord(b)) b) netName)
)

procedure(CDGround(cv point)
  CDInst(cv "gnd" nil point "R0" nil nil)
)
