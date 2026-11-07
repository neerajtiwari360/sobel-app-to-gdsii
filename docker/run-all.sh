#!/usr/bin/env bash
set -Eeuo pipefail

cd /workspace
mkdir -p results/netlist results/asic simulation/waveforms

log() { printf '\n========== %s ==========\n' "$1"; }

log '1/5 Python reference and reproducible vectors'
python3 python/sobel_reference.py
python3 python/generate_test_vectors.py
test "$(wc -l < tb/vectors/input.hex)" -eq 900
test "$(wc -l < tb/vectors/expected.hex)" -eq 900

log '2/5 Combinational RTL against Python'
iverilog -g2012 -Wall -s tb_sobel \
  -o simulation/sobel_tb.vvp rtl/sobel_core.v tb/tb_sobel.v
vvp simulation/sobel_tb.vvp | tee results/asic/core_verification.log
# The testbench must fail on mismatches; check the explicit PASS, too.
grep -q 'PASS: All 900 Sobel pixels match Python' results/asic/core_verification.log

log '3/5 Streaming RTL against Python'
iverilog -g2012 -Wall -s tb_sobel_stream \
  -o simulation/sobel_stream.vvp \
  rtl/sobel_core.v rtl/line_buffer.v rtl/sobel_top.v tb/tb_sobel_stream.v
vvp simulation/sobel_stream.vvp | tee results/asic/stream_verification.log
grep -q 'PASS: 900/900 pixels match Python' results/asic/stream_verification.log

log '4/5 Generic Yosys synthesis and netlist'
# The ORFS image provides Yosys; env.sh sets up its executable locations.
source /OpenROAD-flow-scripts/env.sh
yosys -Q -T -l results/asic/generic_synthesis.log -p '
  read_verilog rtl/sobel_core.v rtl/line_buffer.v rtl/sobel_top.v
  hierarchy -check -top sobel_top
  synth -top sobel_top
  check -assert
  stat
  write_verilog -noattr results/netlist/sobel_top_generic.v
'

log '5/5 SKY130HD ASIC synthesis, placement, CTS, routing, GDSII'

flow=/OpenROAD-flow-scripts/flow

# Ensure the output directories exist.
for dir in results logs reports objects; do
    mkdir -p "$flow/$dir/sky130hd/sobel_top/base"
done

# Run stages sequentially to ensure generated SDC
# files exist before the next stage needs them.
for stage in synth floorplan place cts grt route finish; do
    log "OpenROAD stage: $stage"
    make -C "$flow" \
        DESIGN_CONFIG=/workspace/asic/config.mk \
        "$stage"
done

# Copy the completed artifacts back to Windows.
source_dir="$flow/results/sky130hd/sobel_top/base"
log_dir="$flow/logs/sky130hd/sobel_top/base"
report_dir="$flow/reports/sky130hd/sobel_top/base"

mkdir -p results/asic/orfs
cp -a "$source_dir" results/asic/orfs/results
if [ -d "$log_dir" ]; then cp -a "$log_dir" results/asic/orfs/logs; fi
if [ -d "$report_dir" ]; then cp -a "$report_dir" results/asic/orfs/reports; fi

# Require a real GDSII artifact rather than merely claiming the run succeeded.
gds_file=$(find results/asic/orfs/results -maxdepth 2 -type f \( -iname '*.gds' -o -iname '*.gdsii' \) -print -quit)
if [ -z "$gds_file" ]; then
  echo 'ERROR: Flow finished without a GDSII file. Check OpenROAD logs.' >&2
  exit 1
fi

cp "$gds_file" results/asic/sobel_top_sky130hd.gds
sha256sum results/asic/sobel_top_sky130hd.gds > results/asic/sobel_top_sky130hd.gds.sha256
cat > results/asic/README_RESULTS.txt <<TXT
Sobel educational ASIC flow results
=====================================
RTL functional verification: results/asic/core_verification.log and stream_verification.log
Generic Yosys netlist: results/netlist/sobel_top_generic.v
ASIC implementation stages: results/asic/orfs/results
ASIC synthesis/STA/route reports: results/asic/orfs/reports
ASIC implementation logs: results/asic/orfs/logs
GDSII file: results/asic/sobel_top_sky130hd.gds
SHA256: results/asic/sobel_top_sky130hd.gds.sha256

ATTENTION: Generating GDSII does not prove tapeout readiness.
DRC/LVS, PVT-corner timing and physical signoff must be independently evaluated.
TXT

log 'SUCCESS: Full workflow finished and GDSII generated'
echo "GDSII: /workspace/results/asic/sobel_top_sky130hd.gds"
echo "Reports: /workspace/results/asic/orfs/reports"
