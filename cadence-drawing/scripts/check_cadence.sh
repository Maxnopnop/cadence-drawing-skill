#!/usr/bin/env bash
# Read-only diagnostics. Run from the school's usual Cadence project directory.
printf '\n--- Linux and working directory ---\n'
uname -srm
pwd
printf '\n--- Cadence executables ---\n'
for tool in virtuoso spectre; do
  if command -v "$tool" >/dev/null 2>&1; then
    command -v "$tool"
    "$tool" -W 2>&1 | head -n 8
  else
    printf '%s is not on PATH; use the school-provided setup instructions.\n' "$tool"
  fi
done
printf '\n--- Project setup files ---\n'
for setup in cds.lib .cdsinit; do
  if [ -f "$setup" ]; then ls -l "$setup"; else printf '%s not in this directory\n' "$setup"; fi
done
printf '\n--- Visible library definitions (paths only) ---\n'
if [ -f cds.lib ]; then
  grep -E '^[[:space:]]*(DEFINE|INCLUDE|SOFTINCLUDE)[[:space:]]' cds.lib | head -n 60
fi
printf '\n--- Candidate shared-folder mount points ---\n'
for base in /run/user /media /mnt "$HOME/thinclient_drives" "$HOME/tsclient" "$HOME/Desktop"; do
  if [ -d "$base" ]; then
    find "$base" -maxdepth 4 -type d \( -name FYP -o -name HW3_CADENCE -o -name P6_DIODE_SIMPLE_PORTABLE \) -print 2>/dev/null
  fi
done
printf '\nIf a shared folder is absent, inspect the remote desktop file browser.\n'
printf 'Do not assume a Windows path is also a Linux path.\n'
