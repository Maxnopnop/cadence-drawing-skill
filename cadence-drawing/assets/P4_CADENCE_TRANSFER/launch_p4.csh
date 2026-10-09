#!/bin/tcsh -f
# Run from this transfer-package directory, in the configured course environment.
set task_assets = "$cwd"
if (! -f "$task_assets/p4_draw.il") then
  echo "cd to the P4_CADENCE_TRANSFER folder first."
  exit 1
endif
source /dfs/app/cadence/ic231-150/.cshrc
source /dfs/app/cadence/spectre211hf/.cshrc
set path = ( /dfs/app/cadence/spectre211hf/bin $path )
rehash
spectre -W
if ($status != 0) exit 1
# Override this variable ONLY with a confirmed course GF project directory.
if (! $?P4_COURSE_PROJECT) setenv P4_COURSE_PROJECT "$HOME/ELEC3400/HW2"
if (! -f "$P4_COURSE_PROJECT/cds.lib") then
  echo "No cds.lib in P4_COURSE_PROJECT; set the confirmed course project path."
  exit 1
endif
set task_stamp = `date +%Y%m%d_%H%M%S`
setenv P4_NEW_LIB "HW3_P4_${task_stamp}_$$"
setenv P4_NEW_DIR "$HOME/ELEC3400/HW3/$P4_NEW_LIB"
mkdir -p "$HOME/ELEC3400/HW3"
cd "$P4_COURSE_PROJECT"
exec /dfs/app/cadence/ic231-150/share/dfII/bin/virtuoso -log "$HOME/ELEC3400/HW3/${P4_NEW_LIB}.log" -restore "$task_assets/p4_draw.il"
