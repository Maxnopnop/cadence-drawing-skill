; Reusable native Cadence drawing helpers. Load in Virtuoso CIW.
; R0 configured templates; lowercase terminal aliases; Manhattan routes.

procedure(FreshTerm(inst candidates)
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

procedure(FreshPoint(inst candidates)
  let((term pin)
    term=FreshTerm(inst candidates)
    pin=car(term~>pins)
    unless(pin && pin~>fig error("No symbol pin figure on %s.\n" term~>name))
    dbTransformPoint(centerBox(pin~>fig~>bBox) inst~>transform)
  )
)

procedure(FreshInst(cv cell name origin orient propName value)
  let((master inst)
    master=dbOpenCellViewByType("analogLib" cell "symbol" "schematicSymbol" "r")
    unless(master error("Missing analogLib/%s/symbol.\n" cell))
    inst=dbCreateInst(cv master name origin orient)
    unless(inst error("Could not place %s.\n" name))
    when(propName dbReplaceProp(inst propName "string" value))
    inst
  )
)

procedure(FreshCopyConfigured(cv template origin)
  let((delta inst)
    delta=list(xCoord(origin)-xCoord(template~>xy)
               yCoord(origin)-yCoord(template~>xy))
    inst=dbCopyFig(template cv list(delta "R0" 1.0))
    unless(inst error("Could not copy configured transistor.\n"))
    inst
  )
)

procedure(FreshWire(cv points netName @optional (forceLabel nil))
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
      when(netName && (forceLabel || !member(netName FreshLabeledNets))
        FreshLabeledNets=cons(netName FreshLabeledNets)
        schCreateWireLabel(cv car(wires) car(clean)
          netName "lowerLeft" "R0" "stick" 0.125 nil)
      )
    )
    wires
  )
)

procedure(FreshJoin(cv a b netName)
  FreshWire(cv list(a list(xCoord(a) yCoord(b)) b) netName)
)

procedure(FreshGround(cv point)
  FreshInst(cv "gnd" nil point "R0" nil nil)
)

; ELEC 3400 Fresh: draw three native Virtuoso schematics.
; Load in the Virtuoso CIW. Not a bash script.
; Configure two transistor instances through their normal property forms,
; select each instance, and capture it before calling FreshBuild().
; Existing destination views are refused, never overwritten.

FreshP3Template=nil
FreshGFTemplate=nil
FreshNames=list("P3_DC_BIAS" "P4_OUTPUT_CURVES" "P4_FOUR_RESISTOR")

procedure(FreshInfo()
  printf("Virtuoso: %s\n" getVersion(t))
  printf("Libraries containing npn_inh:\n")
  foreach(lib ddGetLibList()
    when(ddGetObj(lib~>name "npn_inh")
      printf("  %s / npn_inh\n" lib~>name)
    )
  )
  printf("analogLib available: %L\n" ddGetObj("analogLib"))
  printf("ahdlLib/npn_bjt available: %L\n" ddGetObj("ahdlLib" "npn_bjt"))
  t
)

procedure(FreshCapture(which)
  let((sel inst)
    sel=geGetSelSet()
    unless(length(sel)==1 error("Select exactly one transistor instance.\n"))
    inst=car(sel)
    unless(inst~>objType=="inst" error("Selection must be an instance.\n"))
    unless(inst~>orient=="R0" error("Set the transistor orientation to R0 first.\n"))
    cond(
      (which=="P3"
        unless(inst~>libName=="ahdlLib" && inst~>cellName=="npn_bjt"
          error("P3 template must be ahdlLib/npn_bjt.\n"))
        FreshP3Template=inst
      )
      (which=="GF"
        unless(inst~>cellName=="npn_inh"
          error("GF template must be the school's npn_inh device.\n"))
        FreshGFTemplate=inst
      )
      (t error("Use FreshCapture(\"P3\") or FreshCapture(\"GF\").\n"))
    )
    printf("Captured %s: %s/%s; terminals=%L\n"
      which inst~>libName inst~>cellName inst~>master~>terminals~>name)
    foreach(prop inst~>prop
      printf("  %s (%s) = %L\n" prop~>name prop~>valueType prop~>value)
    )
    t
  )
)








procedure(FreshExtras(cv q)
  ; Ground an exposed substrate pin if the symbol has one.
  ; Unknown additional pins fail explicitly rather than being silently ignored.
  foreach(term q~>master~>terminals
    unless(member(lowerCase(term~>name)
      list("c" "collector" "vcoll" "b" "base" "vbase" "e" "emitter" "vemit"))
      if(member(lowerCase(term~>name) list("s" "sub" "subs" "substrate" "bulk" "vsubs"))
        then
          let((p tail)
            p=FreshPoint(q list(lowerCase(term~>name)))
            tail=list(xCoord(p)+0.5 yCoord(p))
            ; Separate substrate stub MUST have its own global-net label.
            FreshWire(cv list(p tail) "gnd!" t)
            ; gnd! is the same global net as analogLib/gnd.
          )
        else
          error("Unrecognized extra BJT pin %s; contact script author before simulation.\n"
            term~>name)
      )
    )
  )
)

procedure(FreshFinish(cv)
  schCheck(cv)
  dbSave(cv)
  printf("Saved %s/%s/schematic. Review Check and Save messages before simulation.\n"
    cv~>libName cv~>cellName)
  dbClose(cv)
  t
)

procedure(FreshBias(lib cell template divider @optional (compact nil))
  let((cv q rc re supply req vb rupper rlower cp bp ep
        rcp rcm rep rem spp spm top bottom eqp eqm vbp vbm
        rup rum rlp rlm)
    FreshLabeledNets=nil
    when(ddGetObj(lib cell "schematic") error("Fresh destination already exists: %s/%s.\n" lib cell))
    cv=dbOpenCellViewByType(lib cell "schematic" "schematic" "a")
    unless(cv error("Cannot create %s/%s.\n" lib cell))
    q=if(divider then FreshCopyConfigured(cv template 2:1.5) else FreshNewQ(cv 2:1.5))
    q~>name="Q0"
    rc=FreshInst(cv "res" "RC" if(compact then 2:2.75 else 8:7) "R0" "r" if(divider then "100" else "56k"))
    re=FreshInst(cv "res" "RE" if(compact then 2:0.5 else 8:2) "R0" "r" if(divider then "74.285714" else "16k"))
    supply=FreshInst(cv "vdc" "VCC" if(compact then 4:1.75 else 12:5) "R0" "vdc" if(divider then "2.5" else "12"))
    cp=FreshPoint(q list("c" "collector" "vcoll"))
    bp=FreshPoint(q list("b" "base" "vbase"))
    ep=FreshPoint(q list("e" "emitter" "vemit"))
    rcp=FreshPoint(rc list("plus" "p" "1"))
    rcm=FreshPoint(rc list("minus" "n" "2"))
    rep=FreshPoint(re list("plus" "p" "1"))
    rem=FreshPoint(re list("minus" "n" "2"))
    spp=FreshPoint(supply list("plus" "p" "1"))
    spm=FreshPoint(supply list("minus" "n" "2"))
    top=if(compact then 2:3.75 else 8:10) bottom=if(compact then 2:0 else 8:0)
    FreshJoin(cv cp rcm "C")
    FreshJoin(cv ep rep "E")
    FreshJoin(cv rcp top "VCC")
    FreshWire(cv list(top if(compact then 4:3.75 else 12:10) spp) "VCC")
    FreshJoin(cv rem bottom "gnd!")
    FreshWire(cv list(bottom if(compact then 4:0 else 12:0) spm) "gnd!")
    FreshGround(cv bottom)
    if(divider then
      rupper=FreshInst(cv "res" "R2" 0.5:2.75 "R0" "r" "10k")
      rlower=FreshInst(cv "res" "R1" 0.5:0.5 "R0" "r" "7.5k")
      rup=FreshPoint(rupper list("plus" "p" "1"))
      rum=FreshPoint(rupper list("minus" "n" "2"))
      rlp=FreshPoint(rlower list("plus" "p" "1"))
      rlm=FreshPoint(rlower list("minus" "n" "2"))
      FreshWire(cv list(rup 0.5:3.75 top) "VCC")
      FreshWire(cv list(rum list(0.5 yCoord(bp)) bp) "B")
      FreshWire(cv list(rlp list(0.5 yCoord(bp))) "B")
      FreshWire(cv list(rlm 0.5:0 bottom) "gnd!")
    else
      req=FreshInst(cv "res" "REQ" if(compact then 1:1.5 else 4.5:4) "R90" "r" "12k")
      vb=FreshInst(cv "vdc" "VEQ" if(compact then 0:0.75 else 2:3) "R0" "vdc" "4")
      eqp=FreshPoint(req list("plus" "p" "1"))
      eqm=FreshPoint(req list("minus" "n" "2"))
      ; Resistor polarity is irrelevant: connect its left end to VEQ.
      when(xCoord(eqp)>xCoord(eqm)
        let((swap) swap=eqp eqp=eqm eqm=swap))
      vbp=FreshPoint(vb list("plus" "p" "1"))
      vbm=FreshPoint(vb list("minus" "n" "2"))
      FreshJoin(cv vbp eqp "VEQ")
      FreshJoin(cv eqm bp "B")
      FreshWire(cv list(vbm if(compact then 0:0 else 2:0) bottom) "gnd!")
    )
    FreshExtras(cv q)
    FreshFinish(cv)
  )
)

procedure(FreshCurves(lib)
  let((cv q vs ib cp bp ep spp spm ibp ibm)
    FreshLabeledNets=nil
    when(ddGetObj(lib "P4_CURVES_FRESH" "schematic") error("Fresh P4 curves already exist.\n"))
    cv=dbOpenCellViewByType(lib "P4_CURVES_FRESH" "schematic" "schematic" "a")
    unless(cv error("Cannot create output-characteristic schematic.\n"))
    q=FreshCopyConfigured(cv FreshGFTemplate 2:1.5)
    q~>name="Q0"
    vs=FreshInst(cv "vdc" "VCE" 4:1.75 "R0" "vdc" "VCE")
    ib=FreshInst(cv "idc" "IB" 0:0.75 "R180" "idc" "IB")
    cp=FreshPoint(q list("c" "collector" "vcoll"))
    bp=FreshPoint(q list("b" "base" "vbase"))
    ep=FreshPoint(q list("e" "emitter" "vemit"))
    spp=FreshPoint(vs list("plus" "p" "1"))
    spm=FreshPoint(vs list("minus" "n" "2"))
    ibp=FreshPoint(ib list("plus" "p" "1"))
    ibm=FreshPoint(ib list("minus" "n" "2"))
    FreshWire(cv list(cp list(xCoord(cp) 3.25) 4:3.25 spp) "C")
    ; Positive idc flows PLUS -> MINUS, so PLUS is grounded and MINUS feeds B.
    ; The source was placed at R180 so its positive current arrow points up.
    FreshJoin(cv ibm bp "B")
    FreshWire(cv list(ibp 0:0 2:0) "gnd!")
    FreshWire(cv list(ep list(xCoord(ep) 0) 2:0) "gnd!")
    FreshWire(cv list(spm 4:0 2:0) "gnd!")
    FreshGround(cv 2:0)
    FreshExtras(cv q)
    FreshFinish(cv)
  )
)

; Read extracted native connectivity, not intended wire coordinates.
procedure(FreshPinNet(inst aliases)
  let((term found)
    term=FreshTerm(inst aliases)
    foreach(it inst~>instTerms
      when(it~>term~>name==term~>name found=it))
    unless(found && found~>net
      error("Unconnected extracted pin: %s/%s.\n" inst~>name term~>name))
    found~>net~>name
  )
)

procedure(FreshNumeric(inst name)
  let((cdf param value)
    cdf=cdfGetInstCDF(inst)
    foreach(p cdf~>parameters
      when(upperCase(p~>name)==upperCase(name) param=p))
    unless(param error("Missing parameter %s on %s.\n" name inst~>name))
    value=param~>value
    if(stringp(value) then cdfParseFloatString(value) else value)
  )
)

procedure(FreshBuildP4()
  unless(FreshLibrary && FreshGFTemplate error("Create the fresh library and capture a NEW configured GF transistor first.\n"))
  foreach(cell list("P4_CURVES_FRESH" "P4_BIAS_FRESH")
    when(ddGetObj(FreshLibrary cell "schematic") error("P4 destination exists; refusing overwrite.\n")))
  unless(FreshGFTemplate~>cellView~>libName==FreshLibrary
    error("Place and configure a NEW GF instance in this fresh library first.\n"))
  FreshTerm(FreshGFTemplate list("c" "collector" "vcoll"))
  FreshTerm(FreshGFTemplate list("b" "base" "vbase"))
  FreshTerm(FreshGFTemplate list("e" "emitter" "vemit"))
  FreshCurves(FreshLibrary)
  FreshBias(FreshLibrary "P4_BIAS_FRESH" FreshGFTemplate t t)
  printf("Two fresh P4 circuits saved; check PDK settings and simulator netlists before simulation.\n")
  t
)

FreshLibrary=nil
FreshLabeledNets=nil

; P4-only entry point. Never opens a previous homework schematic.
procedure(P4Start()
  let((lib folder available win cv)
    foreach(item ddGetLibList()
      when(ddGetObj(item~>name "npn_inh") available=cons(item~>name available)))
    unless(available
      error("No loaded npn_inh library. Load the course GF 8HP PDK first, then run P4Start().\n"))
    printf("Candidate npn_inh libraries: %L. Confirm the course GF model.\n" available)
    lib=getShellEnvVar("P4_NEW_LIB")
    folder=getShellEnvVar("P4_NEW_DIR")
    unless(lib && folder error("Use launch_p4.csh, or set its P4_NEW_LIB/P4_NEW_DIR environment variables before launching Cadence.\n"))
    when(ddGetObj(lib) error("New library already exists; use a new launch name.\n"))
    unless(ddCreateLib(lib folder) error("Cannot register new P4 library.\n"))
    FreshLibrary=lib
    cv=dbOpenCellViewByType(lib "GF_SETUP" "schematic" "schematic" "a")
    unless(cv error("Cannot create new GF setup cell.\n"))
    dbSave(cv)
    dbClose(cv)
    win=geOpen(?lib lib ?cell "GF_SETUP" ?view "schematic" ?mode "a")
    when(win hiSetCurrentWindow(win))
    printf("Place a NEW GF npn_inh: length 12u, multiplicity 10, High_Breakdown.\n")
    printf("Select it and run: FreshCapture(\"GF\") then FreshBuildP4().\n")
    t
  )
)

P4Start()
