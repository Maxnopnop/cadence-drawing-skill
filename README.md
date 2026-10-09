# Cadence Drawing Skill

A reusable Codex skill for drawing native Cadence Virtuoso schematics from
circuit descriptions. Portable SKILL runs inside a configured Linux Virtuoso
session; Linux diagnostics help locate the tools and shared folders.

## Install in Codex

Copy the `cadence-drawing` directory into your Codex skills directory, normally
`~/.codex/skills/`, then start a new Codex chat. Invoke `$cadence-drawing` or ask
Codex to draw a native Virtuoso schematic. Keep the bundled folders together.

## Included

- `cadence-drawing/SKILL.md`: reusable agent workflow.
- `cadence-drawing/scripts/cadence_draw.il`: generic native drawing helpers.
- `cadence-drawing/scripts/check_cadence.sh`: read-only Linux diagnostics.
- `cadence-drawing/assets/HW3_CADENCE`: three-circuit BJT example, loading
  instructions, and reference preview.

The example includes a DC bias circuit, a common-emitter output-curve test
bench, and a four-resistor bias circuit. Two transistor templates are configured
in the user's own Virtuoso environment, then copied into the generated cells.
This preserves actual PDK properties without guessing internal CDF names.

## Validation status

Static checks were performed on the skill structure, SKILL delimiters, and
shell syntax. **The drawing scripts have not yet been executed in Virtuoso.**
After building, run Check and Save, inspect the native drawings and device
properties, and compare the ADE netlist with the supplied connectivity table.
The package is prepared automation, not a certified simulator result.

No PDKs, transistor model files, Cadence binaries, license data, or source
homework PDFs are distributed. Use your organization's own Cadence setup.
