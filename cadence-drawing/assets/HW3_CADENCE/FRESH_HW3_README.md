# HW3 fresh drawing: ECE desktop

This version builds a new library on every launch. P3 is created directly from
`ahdlLib/npn_bjt` and `analogLib` symbols. It does not open, copy, repair, or
modify your previous homework schematic. The new SKILL file is self-contained.

## One paste into the Linux terminal

Save your work and close the old Virtuoso session normally first, so the new
session inherits the working Spectre environment. Then paste:

```tcsh
cd ~/ELEC3400/HW3/cadence-drawing-skill
git pull --ff-only
tcsh cadence-drawing/assets/HW3_CADENCE/launch_fresh_hw3.csh
```

For a first download, run this instead:

```tcsh
mkdir -p ~/ELEC3400/HW3
cd ~/ELEC3400/HW3
git clone https://github.com/Maxnopnop/cadence-drawing-skill.git
cd cadence-drawing-skill
tcsh cadence-drawing/assets/HW3_CADENCE/launch_fresh_hw3.csh
```

The launcher loads IC23.1, then Spectre21.1, checks `spectre -W`, and starts
Virtuoso with the new file. It uses the course HW2 `cds.lib` to find libraries;
it registers a NEW library there and stores NEW circuit files under HW3.
Library names include the time and launcher PID. Existing circuits are untouched.
The log is under `~/ELEC3400/HW3/HW3_FRESH_*.log`.

The schematic opens automatically as `P3_BIAS_FRESH`. Put the pointer over its
canvas and press **F** to fit and center it. Zoom in for larger symbols. Wires
are compact and repeated net labels and oversized duplicate captions are removed.
If there is an error, send the final CIW error lines; do not remove lock files.

## P3 values and calculation

| Element | Value / connections |
|---|---|
| Q0 | ahdlLib npn_bjt; IS=1e-15, BF=75, BR=2, VAF=75 |
| RC | 56k ohm, VCC to collector C |
| REQ | 12k ohm, VEQ to base B |
| RE | 16k ohm, emitter E to ground |
| VCC | +12V; negative terminal grounded |
| VEQ | +4V; negative terminal grounded |
| Substrate | grounded |

```text
          +12V
            |
           RC 56k
            |
            C
 +4V--12k--B Q0
            E
            |
           RE 16k
            |
           GND
```

A forward-active assumption with VBE=0.7V gives negative VCE, so use saturation.
With the homework approximations VBE(sat)=0.75V and VCE(sat)=0.05V:

- IB=(4-VE-0.75)/12000
- IC=(12-VE-0.05)/56000
- IE=VE/16000=IB+IC
- VE=2.95818V, VB=3.70818V, VC=3.00818V
- IB=24.3182uA, IC=160.568uA, IE=184.886uA

Know Kirchhoff's voltage/current laws, IB/IC/IE relationships, and how to test
cutoff, forward-active operation, and saturation. The nonlinear transistor model
can differ from the assumed fixed saturation voltages.

The script checks **extracted native connections and effective CDF values**.
Look for `P3 CHECK PASSED`. This checks the drawing, not a simulation result.

## Open ADE: no existing maestro view is required

From the new **schematic editor**, choose **Launch > ADE Explorer**. Create a
new setup if prompted; do not select a transistor template in the Open File dialog.
A `maestro` view holds a saved ADE setup; it is not a required schematic button.
Choose a DC analysis with operating-point saving and no sweep for P3. Run once.
After a successful run, use the Results menu to display/annotate DC node voltages
and device operating points. Compare B, C, E and transistor currents above.
Save the ADE setup in this NEW library. If a run fails, inspect the simulator log.
This launcher deliberately selects the Spectre21.1 version you already verified;
it does not change the operating system or delete existing locks.

## Two additional P4 circuits

The course GF PDK has not yet been found in your session. P4 needs the actual
`npn_inh`, not the P3 AHDL transistor. Once the course setup provides that PDK:

1. In this NEW library, create a NEW cell `GF_SETUP`, view `schematic`.
2. Place one `npn_inh` in R0 orientation. Through its normal property form, set
   emitter length 12u, multiplicity 10, and High_Breakdown; retain other defaults.
3. Select only that NEW transistor. Keep its schematic open. In **Virtuoso CIW**
   (not the Linux terminal), paste:

```lisp
FreshCapture("GF")
FreshBuildP4()
```

This creates `P4_CURVES_FRESH` and `P4_BIAS_FRESH`. It refuses a GF instance from
any previous library. Check and save both drawings and inspect their netlists
before simulation. P4 drawings have not yet been executed or simulated here.

For curves: grounded emitter; a collector voltage source uses variable `VCE`;
a current source injects variable `IB` into the base. In ADE sweep VCE from
0 to 2.5V in steps of 0.1V, and IB from 0 to 30uA in steps of 5uA. Plot collector
current for all seven base-current values.

For bias: VCC=2.5V; R2 upper=10k, R1 lower=7.5k, RC=100 ohm,
RE=74.285714 ohm. Divider Vth=1.07143V, Rth=4.28571k ohm.
These RC/RE are initial design estimates for IC=5mA and **VC=2V**.
They assume negligible base loading and VBE near 0.7V; verify and adjust using
the actual GF model. The target is VC, not VCE; the ideal estimate VCE=1.62857V.

## Files

- `fresh_hw3.il`: new native drawing and P3 connectivity/value checking.
- `launch_fresh_hw3.csh`: ECE Linux terminal launcher.
- `FRESH_HW3_README.md`: this Markdown guide.

Validation status: local source checks only for this rewrite. The older helper
APIs were exercised in your ECE session, but the fresh version still needs native
execution. No DC simulation result is claimed.

The launcher uses Cadence's documented `-restore` loading behavior:
[Cadence startup SKILL guidance](https://community.cadence.com/cadence_technology_forums/f/custom-ic-skill/38961/running-a-skill-script-from-command-line/1355677).
