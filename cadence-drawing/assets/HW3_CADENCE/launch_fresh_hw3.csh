#!/bin/tcsh -f
# Run from the repository root. Keep the course project setup, use new OA library.
set task_repo = "$cwd"
set task_assets = "$task_repo/cadence-drawing/assets/HW3_CADENCE"
if (! -f "$task_assets/fresh_hw3.il") then
  echo "First cd to ~/ELEC3400/HW3/cadence-drawing-skill"
  exit 1
endif
if (! -f /dfs/app/cadence/ic231-150/.cshrc) then
  echo "The expected ECE Virtuoso setup is missing."
  exit 1
endif
if (! -f /dfs/app/cadence/spectre211hf/.cshrc) then
  echo "The working Spectre 21.1 setup is missing."
  exit 1
endif
if (! -f "$HOME/ELEC3400/HW2/cds.lib") then
  echo "The configured course project cds.lib is missing."
  exit 1
endif
source /dfs/app/cadence/ic231-150/.cshrc
source /dfs/app/cadence/spectre211hf/.cshrc
set path = ( /dfs/app/cadence/spectre211hf/bin $path )
rehash
/dfs/app/cadence/spectre211hf/bin/spectre -W
if ($status != 0) exit 1
set task_stamp = `date +%Y%m%d_%H%M%S`
setenv HW3_FRESH_LIB "HW3_FRESH_${task_stamp}_$$"
setenv HW3_FRESH_DIR "$HOME/ELEC3400/HW3/$HW3_FRESH_LIB"
mkdir -p "$HOME/ELEC3400/HW3"
cd "$HOME/ELEC3400/HW2"
echo "Creating $HW3_FRESH_LIB in $HW3_FRESH_DIR"
# -restore runs SKILL after the normal course initialization.
exec /dfs/app/cadence/ic231-150/share/dfII/bin/virtuoso -log "$HOME/ELEC3400/HW3/${HW3_FRESH_LIB}.log" -restore "$task_assets/fresh_hw3.il"
