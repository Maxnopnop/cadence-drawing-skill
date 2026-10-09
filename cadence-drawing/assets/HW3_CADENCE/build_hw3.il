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
    delta=list(xCoord(origin)-xCoord(template~>origin)
               yCoord(origin)-yCoord(template~>origin))
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

; ELEC 3400 HW3: draw three native Virtuoso schematics.
; Load in the Virtuoso CIW. Not a bash script.
; Configure two transistor instances through their normal property forms,
; select each instance, and capture it before calling HW3Build().
; Existing destination views are refused, never overwritten.

HW3P3Template=nil
HW3GFTemplate=nil
HW3Names=list("P3_DC_BIAS" "P4_OUTPUT_CURVES" "P4_FOUR_RESISTOR")

procedure(HW3Info()
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

procedure(HW3Capture(which)
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
        HW3P3Template=inst
      )
      (which=="GF"
        unless(inst~>cellName=="npn_inh"
          error("GF template must be the school's npn_inh device.\n"))
        HW3GFTemplate=inst
      )
      (t error("Use HW3Capture(\"P3\") or HW3Capture(\"GF\").\n"))
    )
    printf("Captured %s: %s/%s; terminals=%L\n"
      which inst~>libName inst~>cellName inst~>master~>terminals~>name)
    foreach(prop inst~>prop
      printf("  %s (%s) = %L\n" prop~>name prop~>valueType prop~>value)
    )
    t
  )
)








procedure(HW3Extras(cv q)
  ; Ground an exposed substrate pin if the symbol has one.
  ; Unknown additional pins fail explicitly rather than being silently ignored.
  foreach(term q~>master~>terminals
    unless(member(lowerCase(term~>name)
      list("c" "collector" "b" "base" "e" "emitter"))
      if(member(lowerCase(term~>name) list("s" "sub" "subs" "substrate" "bulk"))
        then
          let((p tail)
            p=CDPoint(q list(lowerCase(term~>name)))
            tail=list(xCoord(p)+1.0 yCoord(p))
            CDWire(cv list(p tail) "gnd!")
            ; gnd! is the same global net as analogLib/gnd.
          )
        else
          error("Unrecognized extra BJT pin %s; contact script author before simulation.\n"
            term~>name)
      )
    )
  )
)

procedure(HW3Finish(cv)
  schCheck(cv)
  dbSave(cv)
  printf("Saved %s/%s/schematic. Review Check and Save messages before simulation.\n"
    cv~>libName cv~>cellName)
  dbClose(cv)
  t
)

procedure(HW3Bias(lib cell template divider)
  let((cv q rc re supply req vb rupper rlower cp bp ep
        rcp rcm rep rem spp spm top bottom eqp eqm vbp vbm
        rup rum rlp rlm)
    cv=dbOpenCellViewByType(lib cell "schematic" "schematic" "a")
    unless(cv error("Cannot create %s/%s.\n" lib cell))
    q=CDCopyConfigured(cv template 8:4)
    q~>name="Q0"
    rc=CDInst(cv "res" "RC" 8:7 "R0" "r" if(divider then "100" else "56k"))
    re=CDInst(cv "res" "RE" 8:2 "R0" "r" if(divider then "74.285714" else "16k"))
    supply=CDInst(cv "vdc" "VCC" 12:5 "R0" "dc" if(divider then "2.5" else "12"))
    cp=CDPoint(q list("c" "collector"))
    bp=CDPoint(q list("b" "base"))
    ep=CDPoint(q list("e" "emitter"))
    rcp=CDPoint(rc list("plus" "p" "1"))
    rcm=CDPoint(rc list("minus" "n" "2"))
    rep=CDPoint(re list("plus" "p" "1"))
    rem=CDPoint(re list("minus" "n" "2"))
    spp=CDPoint(supply list("plus" "p" "1"))
    spm=CDPoint(supply list("minus" "n" "2"))
    top=8:10 bottom=8:0
    CDJoin(cv cp rcm "C")
    CDJoin(cv ep rep "E")
    CDJoin(cv rcp top "VCC")
    CDWire(cv list(top 12:10 spp) "VCC")
    CDJoin(cv rem bottom "gnd!")
    CDWire(cv list(bottom 12:0 spm) "gnd!")
    CDGround(cv bottom)
    if(divider then
      rupper=CDInst(cv "res" "R2" 3:7 "R0" "r" "10k")
      rlower=CDInst(cv "res" "R1" 3:2 "R0" "r" "7.5k")
      rup=CDPoint(rupper list("plus" "p" "1"))
      rum=CDPoint(rupper list("minus" "n" "2"))
      rlp=CDPoint(rlower list("plus" "p" "1"))
      rlm=CDPoint(rlower list("minus" "n" "2"))
      CDWire(cv list(rup 3:10 top) "VCC")
      CDWire(cv list(rum list(3 yCoord(bp)) bp) "B")
      CDWire(cv list(rlp list(3 yCoord(bp))) "B")
      CDWire(cv list(rlm 3:0 bottom) "gnd!")
    else
      req=CDInst(cv "res" "REQ" 4.5:4 "R90" "r" "12k")
      vb=CDInst(cv "vdc" "VEQ" 2:3 "R0" "dc" "4")
      eqp=CDPoint(req list("plus" "p" "1"))
      eqm=CDPoint(req list("minus" "n" "2"))
      ; Resistor polarity is irrelevant: connect its left end to VEQ.
      when(xCoord(eqp)>xCoord(eqm)
        let((swap) swap=eqp eqp=eqm eqm=swap))
      vbp=CDPoint(vb list("plus" "p" "1"))
      vbm=CDPoint(vb list("minus" "n" "2"))
      CDJoin(cv vbp eqp "VEQ")
      CDJoin(cv eqm bp "B")
      CDWire(cv list(vbm 2:0 bottom) "gnd!")
    )
    HW3Extras(cv q)
    HW3Finish(cv)
  )
)

procedure(HW3Curves(lib)
  let((cv q vs ib cp bp ep spp spm ibp ibm)
    cv=dbOpenCellViewByType(lib "P4_OUTPUT_CURVES" "schematic" "schematic" "a")
    unless(cv error("Cannot create output-characteristic schematic.\n"))
    q=CDCopyConfigured(cv HW3GFTemplate 8:4)
    q~>name="Q0"
    vs=CDInst(cv "vdc" "VCE" 12:5 "R0" "dc" "VCE")
    ib=CDInst(cv "idc" "IB" 3:3 "R180" "dc" "IB")
    cp=CDPoint(q list("c" "collector"))
    bp=CDPoint(q list("b" "base"))
    ep=CDPoint(q list("e" "emitter"))
    spp=CDPoint(vs list("plus" "p" "1"))
    spm=CDPoint(vs list("minus" "n" "2"))
    ibp=CDPoint(ib list("plus" "p" "1"))
    ibm=CDPoint(ib list("minus" "n" "2"))
    CDWire(cv list(cp list(xCoord(cp) 8) 12:8 spp) "C")
    ; Positive idc flows PLUS -> MINUS, so PLUS is grounded and MINUS feeds B.
    ; The source was placed at R180 so its positive current arrow points up.
    CDJoin(cv ibm bp "B")
    CDWire(cv list(ibp 3:0 8:0) "gnd!")
    CDWire(cv list(ep list(xCoord(ep) 0) 8:0) "gnd!")
    CDWire(cv list(spm 12:0 8:0) "gnd!")
    CDGround(cv 8:0)
    HW3Extras(cv q)
    HW3Finish(cv)
  )
)

procedure(HW3Build(lib)
  unless(ddGetObj(lib) error("Create destination library %s in Library Manager first.\n" lib))
  unless(HW3P3Template && HW3GFTemplate
    error("Capture both configured transistors in this Virtuoso session first.\n"))
  ; Validate terminal names before creating any destination view.
  foreach(template list(HW3P3Template HW3GFTemplate)
    CDTerm(template list("c" "collector"))
    CDTerm(template list("b" "base"))
    CDTerm(template list("e" "emitter"))
  )
  foreach(cell HW3Names
    when(ddGetObj(lib cell "schematic")
      error("%s/%s/schematic already exists. Use a new destination library.\n" lib cell))
  )
  HW3Bias(lib "P3_DC_BIAS" HW3P3Template nil)
  HW3Curves(lib)
  HW3Bias(lib "P4_FOUR_RESISTOR" HW3GFTemplate t)
  printf("Three schematics created in %s. Open them from Library Manager.\n" lib)
  t
)

procedure(HW3CreateP3(lib)
  let((master cdf specs param specsResolved templateCV template)
    unless(ddGetObj(lib)
      error("Destination library %s must exist first.\n" lib))
    when(ddGetObj(lib "P3_DC_BIAS" "schematic")
      error("%s/P3_DC_BIAS already exists; it will not be overwritten.\n" lib))
    when(ddGetObj(lib "P3_AUTO_TEMPLATE" "schematic")
      error("%s/P3_AUTO_TEMPLATE already exists; use a fresh library to retry.\n" lib))
    master=dbOpenCellViewByType("ahdlLib" "npn_bjt" "symbol" "schematicSymbol" "r")
    unless(master error("ahdlLib/npn_bjt symbol is unavailable.\n"))
    cdf=cdfGetBaseCellCDF(ddGetObj("ahdlLib" "npn_bjt"))
    unless(cdf error("Cannot inspect npn_bjt parameter definitions.\n"))
    specs=list(list("IS" 1e-15) list("BF" 75.0)
               list("BR" 2.0) list("VAF" 75.0))
    ; Resolve real CDF names/types rather than assuming uppercase properties.
    foreach(spec specs
      param=nil
      foreach(p cdf~>parameters
        when(upperCase(p~>name)==car(spec) param=p))
      unless(param
        printf("Available npn_bjt parameters: %L\n" cdf~>parameters~>name)
        error("No unambiguous CDF parameter for %s.\n" car(spec)))
      unless(member(param~>paramType list("string" "float" "int"))
        error("Unsupported CDF type for %s: %L.\n" param~>name param~>paramType))
      when(param~>callback && param~>callback!=""
        error("%s requires a CDF callback; configure a template through its property form.\n"
          param~>name))
      specsResolved=cons(list(param~>name param~>paramType cadr(spec)) specsResolved)
    )
    templateCV=dbOpenCellViewByType(lib "P3_AUTO_TEMPLATE" "schematic" "schematic" "a")
    unless(templateCV error("Could not create P3 template view.\n"))
    template=dbCreateInst(templateCV master "Q_TEMPLATE" 0:0 "R0")
    unless(template error("Could not create transistor instance.\n"))
    foreach(spec specsResolved
      cond(
        (cadr(spec)=="string"
          dbReplaceProp(template car(spec) "string" sprintf(nil "%g" caddr(spec))))
        (cadr(spec)=="float"
          dbReplaceProp(template car(spec) "float" caddr(spec)))
        (cadr(spec)=="int"
          dbReplaceProp(template car(spec) "int" fix(caddr(spec))))
      )
      printf("Set %s (%s) = %L\n" car(spec) cadr(spec) caddr(spec))
    )
    CDTerm(template list("c" "collector"))
    CDTerm(template list("b" "base"))
    CDTerm(template list("e" "emitter"))
    dbSave(templateCV)
    HW3Bias(lib "P3_DC_BIAS" template nil)
    dbClose(templateCV)
    geOpen(?lib lib ?cell "P3_DC_BIAS" ?view "schematic" ?mode "a")
    printf("P3 created and opened. Review Check and Save and Q0 properties before simulation.\n")
    t
  )
)

printf("HW3 loaded. For P3 only: HW3CreateP3(\"HW3_BJT\"). For all three: capture templates then HW3Build.\n")
