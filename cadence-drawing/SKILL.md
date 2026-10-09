---
name: cadence-drawing
description: Create native Cadence Virtuoso schematics from circuit descriptions using portable SKILL scripts, with Linux environment discovery, configured-device copying, and connectivity checks. Use for Virtuoso schematic drawing and import; not PCB layout or generic circuit illustrations.
---

# Cadence drawing

Convert the user's circuit into an explicit instance/net table before drawing.
Keep source labels and terminal polarity; do not infer resistor names from a
convention when the supplied diagram labels them differently.

## Discover the execution environment

Run [scripts/check_cadence.sh](scripts/check_cadence.sh) in the user's configured
Linux Cadence project. It reports versions and likely shared-folder locations.
If only a local Windows filesystem is accessible, prepare portable source files
and ask the user to run the diagnostics remotely. A shared Windows folder path
is not automatically its Linux mount path. Preserve existing cds.lib and PDK
startup files; use the school's or organization's established setup.

Linux shell commands and Virtuoso CIW SKILL expressions are separate interfaces.
Label instructions accordingly. Use `load("/actual/Linux/path/script.il")` in
CIW, after the user has launched their configured Virtuoso session.

## Build native schematics

Use [scripts/cadence_draw.il](scripts/cadence_draw.il) as a small drawing toolkit.
It provides native instance creation, terminal-coordinate lookup, configured
instance copying, Manhattan wires, attached net labels, and ground symbols.
Read [references/virtuoso-workflow.md](references/virtuoso-workflow.md) when
adapting pin mappings or PDK properties. Use new destination cells and refuse
existing views unless the user requested a specific edit.

For PDK devices with unknown property names or callbacks, have the user place
one device, configure it through its normal property form, and select it.
Copy that configured instance with `CDCopyConfigured`. Inspect available pin
names and symbol-pin locations; stop on ambiguous electrical mappings.
Require an explicit connection for additional substrate or bulk terminals.

Adapt topology, device types, sources, values, and simulation variables to the
current circuit. The [HW3 example](assets/HW3_CADENCE/README.txt) demonstrates
three BJT circuits; its device names and values are example-specific.

## Verify and hand off

Run `schCheck`, review messages, save, and inspect the generated schematic and
simulator netlist against the instance/net table. Verify source polarity,
floating pins, distinct supplies, and transistor parameters before simulation.
For quantitative simulation requests, use the actual model libraries and
record simulator results; a sketch or guessed device gain is not a simulation.

Distinguish prepared source, static validation, native Cadence execution,
connectivity verification, and simulation verification in the delivery status.
If Cadence is inaccessible, provide the script, preview, and exact next commands
without claiming tested OA schematics. Return an error-specific repair after
the user provides remote execution output.

For a GitHub deliverable, include only authored automation and permitted example
data. Exclude proprietary PDKs, Cadence binaries, model files, license data,
source homework documents, and remote project logs. Repository creation or
publishing follows the user's requested destination and visibility.
