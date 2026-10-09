# Virtuoso drawing details

## Native API pattern

Open a new schematic with
`dbOpenCellViewByType(lib cell "schematic" "schematic" "a")` after checking that
the destination view does not exist. Read symbol masters with
`dbOpenCellViewByType(lib cell "symbol" "schematicSymbol" "r")`.

Use actual terminal names and symbol pin figures to locate connections:
`dbTransformPoint(centerBox(pin~>fig~>bBox) inst~>transform)`.
The toolkit accepts a list of lowercase terminal-name aliases and refuses an
unresolved mapping. For symbols with multiple pin figures, inspect which
figure should anchor the wire rather than assuming the first one is sufficient.

`schCreateWire` draws native wires and `schCreateWireLabel` attaches electrical
net names. Give the wire constructor Manhattan points and remove consecutive
duplicates. Reusing a name connects separate wire segments electrically;
inspect the resulting geometry for accidental intersections between nets.

## Configured-device copies

Changing raw properties with `dbReplaceProp` does not execute the device's CDF
callbacks. For simple analogLib resistors and DC sources, the example sets
string properties `r` and `dc`. For a school PDK or AHDL device, configure the
source through the property form and apply it before copying the instance.
`dbCopyFig` preserves existing instance properties; it does not prove that a
source instance was configured correctly. Confirm the copied properties and
the generated netlist. Use a source instance at R0 for the included copy helper.

The source instance must remain valid in the same Virtuoso session. Do not
delete it, close its editable cellview, reload the script that resets template
variables, or restart Virtuoso between capture and build.

## Sources and terminals

For analogLib DC voltage sources, PLUS is the positive voltage terminal.
For an analogLib idc, positive current flows PLUS to MINUS. To inject positive
base current into an NPN, connect PLUS to ground and MINUS to B; the example
uses R180 for an upward-pointing source. Check the netlist's source polarity.

Ground symbols in the supplied example use the global `gnd!` net. Check the
PDK-required substrate connection independently; do not reuse a generic
ground rule for a device that requires a different bulk bias.

## Verification evidence

The repository has been statically validated. Native execution, CDF behavior,
symbol geometry, license availability, and GF model simulation require the
user's Virtuoso environment. They have not been certified by static checks.

After `schCheck`, open each generated cell, inspect wire junctions and model
properties, and compare its ADE-generated netlist with the example's net table.
Record the first failing CIW message when debugging; changing a library setup
or internal PDK parameter without evidence is not a repair.

## Primary API references

- [Create a schematic cellview and CDF callback caveat](https://community.cadence.com/cadence_technology_forums/f/custom-ic-skill/36448/skill-command-to-create-the-cell-view)
- [Wire creation and transformed symbol pin coordinates](https://community.cadence.com/cadence_technology_forums/f/custom-ic-skill/59636/connecting-wires-through-skill-ic-6-1-8/1398888)
- [Wire labels and schCheck connectivity extraction](https://community.cadence.com/cadence_technology_forums/f/custom-ic-skill/65634/how-to-short-all-the-internal-nets-to-vss-with-skill)
- [Version query in CIW](https://community.cadence.com/cadence_technology_forums/f/custom-ic-skill/19313/skill-command-to-check-which-cadence-version-is-running)
