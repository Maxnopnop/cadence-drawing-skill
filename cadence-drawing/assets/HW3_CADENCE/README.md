# HW3: Three native Cadence Virtuoso schematics

Status: portable SKILL source prepared on Windows. It has NOT been executed
inside your Linux Virtuoso or tested against your school's PDK. Run Check and
Save and compare the generated netlist against the wiring table below.

## Quick start: automatically draw Problem 3

This route uses the already-created `HW3_BJT` library and requires no manual
transistor placement. Update the cloned repository in your Linux terminal:

```bash
git -C "$HOME/ELEC3400/HW3/cadence-drawing-skill" pull --ff-only
```

Then paste this single expression into the Virtuoso CIW:

```lisp
progn(load(strcat(getShellEnvVar("HOME") "/ELEC3400/HW3/cadence-drawing-skill/cadence-drawing/assets/HW3_CADENCE/build_hw3.il")) HW3CreateP3("HW3_BJT"))
```

The command discovers `npn_bjt` parameter names and types from its CDF, sets
IS/BF/BR/VAF, draws Problem 3, checks and saves it, and opens the schematic.
It refuses existing destination views and parameters requiring callbacks.
The new command has been statically checked; its first native execution still
needs verification in your Virtuoso session.

Problem 4 requires your GF PDK. The template workflow below covers drawing
all three in a fresh destination library; it does not overwrite an existing P3.

## 1. Find the shared folder

Your screenshot shares C:\Users\A\Documents\FYP. A copy of this package is in
its HW3_CADENCE subfolder. Its Linux mount path depends on the remote desktop
service. Use the Linux file browser or run:

```bash
bash /actual/Linux/path/HW3_CADENCE/check_cadence.sh
```

Run this from your normal school Cadence project directory.
Do not replace your project's cds.lib or school setup scripts.

## 2. Load the drawing script

Launch Virtuoso from the school's configured project directory.
In the Virtuoso Command Interpreter Window (CIW), not the Linux shell, type:

```lisp
load("/actual/Linux/path/HW3_CADENCE/build_hw3.il")
HW3Info()
```


## 3. Create an empty library and transistor templates

In Library Manager, create a library named HW3_BJT. Follow your course's usual
technology-library selection. Create a schematic cell named templates.
Place these two devices, both with orientation R0. Configure them through
their normal property forms and apply the changes before capture:


```text
ahdlLib / npn_bjt / symbol
  IS=1e-15, BF=75, BR=2, VAF=75.
  Select ONLY this transistor and type in CIW:
    HW3Capture("P3")
```



```text
your GF PDK library / npn_inh / symbol
  Emitter Length=12u, Multiplicity=10,
  Performance/Breakdown=High_Breakdown; all other properties default.
  Select ONLY this transistor and type in CIW:
    HW3Capture("GF")
```


Keep the templates schematic open, and do not delete or change its devices.
Capture and build in the SAME Virtuoso session. Opening another schematic is OK.
Capturing devices copies their existing properties without guessing internal
PDK property names or bypassing the property form's CDF callbacks.

## 4. Draw all three

In CIW type:

```lisp
HW3Build("HW3_BJT")
```

Then open these schematic views from Library Manager:

```text
HW3_BJT / P3_DC_BIAS / schematic
HW3_BJT / P4_OUTPUT_CURVES / schematic
HW3_BJT / P4_FOUR_RESISTOR / schematic
```

Existing destination views are refused. To regenerate, use another new library.
The script grounds a recognized exposed substrate terminal. Confirm the
required substrate connection against your PDK/course setup before simulation.
Unexpected pin names cause an explicit error rather than an assumed mapping.

## 5. Verify connectivity before simulation

The script runs schCheck and saves each view. Read its errors/warnings, then
open each transistor's property form to confirm the copied model parameters.
In the ADE-generated netlist, compare electrical connections with this table:

### `P3_DC_BIAS`


```text
VCC positive: VCC, negative: ground, DC=12 V
VEQ positive: VEQ, negative: ground, DC=4 V
RC: VCC--C, 56k
REQ: VEQ--B, 12k
RE: E--ground, 16k
Q0: C=C, B=B, E=E, ahdlLib/npn_bjt
DC analysis. Hand model: IC=160.568u, IB=24.318u, VCE=0.05 V.
Exact SPICE values may differ from the constant-voltage hand model.
```


### `P4_OUTPUT_CURVES`


```text
VCE positive: C, negative: ground, DC design variable VCE
IB current flows ground -> B, DC design variable IB
Q0: C=C, B=B, E=ground, GF npn_inh
ADE design variables initially: VCE=0, IB=0.
DC sweep: VCE from 0 to 2.5 V in 0.1 V steps.
Outer parameter sweep: IB from 0 to 30u A in 5u A steps.
Plot Q0 collector current against VCE. Expect seven curves.
```


### `P4_FOUR_RESISTOR`


```text
VCC positive: VCC, negative: ground, DC=2.5 V
R2: VCC--B, 10k (UPPER resistor in the homework screenshot)
R1: B--ground, 7.5k (LOWER resistor)
RC: VCC--C, 100 ohm
RE: E--ground, 74.285714 ohm initially
Q0: C=C, B=B, E=E, GF npn_inh
DC analysis; adjust RE until IC is near 5mA.
IC too low -> decrease RE. IC too high -> increase RE.
At IC=5mA, VC=2.0V. This target is VC, not VCE.
```


Use the school's required GF model-library setup in ADE. Symbols alone do not
provide proprietary model files. The package includes no PDK, model files,
simulation results, or copied Cadence binaries.

## Troubleshooting

If load or build reports an error, send the first CIW error, HW3Info() output,
the printed terminal list, and a schematic screenshot. Do not send license
keys or proprietary model contents. The separate circuit_previews.svg is a
reference drawing, not proof of Cadence execution.
