# Use the HW3 drawing tool on the ECE desktop

These commands match the ECE Linux desktop tested in this chat: `tcsh` with
Virtuoso IC23.1. Keep Linux terminal commands separate from Virtuoso CIW code.

## 1. Download once — Linux terminal

```tcsh
mkdir -p ~/ELEC3400/HW3
cd ~/ELEC3400/HW3
git clone https://github.com/Maxnopnop/cadence-drawing-skill.git
```

If you already cloned it, update instead:

```tcsh
cd ~/ELEC3400/HW3/cadence-drawing-skill
git pull --ff-only
```

The ECE server's older Git does not support `git -C`; use `cd` first.

## 2. Start Cadence — Linux terminal

```tcsh
source /dfs/app/cadence/ic231-150/.cshrc
rehash
cd ~/ELEC3400/HW2
/dfs/app/cadence/ic231-150/share/dfII/bin/virtuoso &
```

This uses the existing HW2 project's `cds.lib`. The repository files stay in
HW3. Use your course's configured project if its setup differs. Do not launch
a second Virtuoso if you already have this session open.

## 3. Load the tool — Virtuoso CIW

Paste into the bottom command field of the Virtuoso main window and press Enter:

```lisp
load(strcat(getShellEnvVar("HOME") "/ELEC3400/HW3/cadence-drawing-skill/cadence-drawing/assets/HW3_CADENCE/build_hw3.il"))
```

The following commands require the existing library `HW3_BJT`. For a first use,
create it in Library Manager: **File → New → Library → HW3_BJT**. For Problem 3's
schematic-only library, choose **Do not need process information**.

## 4. Draw or check Problem 3 — Virtuoso CIW

Create a compact circuit with shorter wires and readable labels:

```lisp
HW3CreateP3("HW3_BJT" t)
```

It creates and opens `HW3_BJT / P3_DC_BIAS_COMPACT / schematic` and runs a
connection/value check. Press **f** in the schematic window to fit the drawing.
It refuses to overwrite an existing nonempty schematic.

If the compact circuit already exists, check it and open it instead:

```lisp
HW3CheckP3("HW3_BJT" "P3_DC_BIAS_COMPACT")
geOpen(?lib "HW3_BJT" ?cell "P3_DC_BIAS_COMPACT" ?view "schematic" ?mode "a")
```

For the original, widely spaced circuit, use:

```lisp
HW3CheckP3("HW3_BJT")
```

Look for **P3 CHECK PASSED**. This verifies extracted pin connections and
component values; it does not verify the DC simulation result. After every
`git pull`, reload the script in CIW before using changed commands.

If an older generated circuit reports `Missing parameter dc on VCC`, repair
its source values once and run the check again:

```lisp
HW3RepairP3Sources("HW3_BJT")
HW3CheckP3("HW3_BJT")
```

## 5. Simulate

Run a DC operating-point analysis in ADE. Problem 3's hand-model reference is
`IC = 160.57 µA`, `IB = 24.32 µA`, `VCE = 0.05 V` in saturation. The AHDL model's
simulated voltages can differ from the fixed-voltage hand model.

For Problem 4, the school's GF `npn_inh` library and model setup must be loaded.
Check availability with `HW3Info()` in CIW. Follow the
[full HW3 instructions](cadence-drawing/assets/HW3_CADENCE/README.md) for its two
circuits and sweep settings. The GF library was not available in the session
shown so far.

If a command fails, capture the first CIW error or terminal error. Successful
script loading alone does not prove the circuit is correct.
