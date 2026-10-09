#!/bin/bash
# Read-only, restricted to the candidate GF directory. Does not alter setup.
root=/dfs/app/gf/gf130HPSIGE_8XP
if [ ! -d "$root" ]; then
  echo "Candidate GF directory not accessible: $root"
  exit 1
fi
ls -la "$root"
find "$root" -maxdepth 9 -type d -name npn_inh -print
find "$root" -maxdepth 6 -type f \( -name cds.lib -o -name lib.defs -o -iname '*setup*.csh' -o -iname '*setup*.sh' -o -iname '*readme*' \) -print
echo "GF SEARCH FINISHED"
