#!/bin/tcsh -f
# ECE GF 8HP schematic project; new project/library on every launch.
set task_assets = "$cwd"
if (! -f "$task_assets/p4_draw.il") then
  echo "cd to cadence-drawing/assets/P4_CADENCE_TRANSFER first."
  exit 1
endif
set task_gf = /dfs/app/gf/gf130HPSIGE_8XP/V1_8_6_0b
set task_setup = "$task_gf/DesignEnv/VirtuosoOA/setup"
foreach task_file ( .cdsinit .cdsenv .simrc display.drf gfPdkEnvSet.config wireopt413.cds.lib )
  if (! -r "$task_setup/$task_file") then
    echo "Missing PDK setup: $task_setup/$task_file"
    exit 1
  endif
end
if (! -d "$task_gf/DesignEnv/VirtuosoOA/libs/bicmos8hp/npn_inh") then
  echo "Expected GF npn_inh is not accessible."
  exit 1
endif
foreach task_model ( design.scs wafer.scs allModels.scs )
  if (! -r "$task_gf/Models/Spectre/models/$task_model") then
    echo "Missing GF Spectre model: $task_model"
    exit 1
  endif
end
source /dfs/app/cadence/ic231-150/.cshrc
source /dfs/app/cadence/spectre211hf/.cshrc
set path = ( /dfs/app/cadence/spectre211hf/bin $path )
setenv CDSHOME /dfs/app/cadence/ic231-150
setenv GF_PDK_HOME "$task_gf"
setenv CDS_Netlisting_Mode Analog
rehash
spectre -W
if ($status != 0) exit 1
set task_stamp = `date +%Y%m%d_%H%M%S`
set task_project = "$HOME/ELEC3400/HW3/GF_P4_${task_stamp}_$$"
if (-e "$task_project") then
  echo "Destination exists; rerun for a new project name."
  exit 1
endif
mkdir -p "$task_project"
if ($status != 0) exit 1
foreach task_file ( .cdsinit .cdsenv .simrc display.drf gfPdkEnvSet.config )
  cp "$task_setup/$task_file" "$task_project/$task_file"
  if ($status != 0) exit 1
end
cp "$task_setup/wireopt413.cds.lib" "$task_project/cds.lib"
if ($status != 0) exit 1
setenv P4_NEW_LIB "HW3_P4_${task_stamp}_$$"
setenv P4_NEW_DIR "$task_project/$P4_NEW_LIB"
echo "New P4 project: $task_project"
echo "GF model: $GF_PDK_HOME ; library: $P4_NEW_LIB"
cd "$task_project"
exec /dfs/app/cadence/ic231-150/share/dfII/bin/virtuoso -log "$task_project/P4.log" -restore "$task_assets/p4_draw.il"
