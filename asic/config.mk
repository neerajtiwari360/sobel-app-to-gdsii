# OpenROAD Flow Scripts design config for the existing Sobel streaming accelerator.
export DESIGN_NAME = sobel_top
export PLATFORM = sky130hd

export VERILOG_FILES = /workspace/rtl/sobel_core.v \
                       /workspace/rtl/line_buffer.v \
                       /workspace/rtl/sobel_top.v
export SDC_FILE = /workspace/asic/constraints/timing.sdc

# Starting point, not a guaranteed timing/area result.
export CORE_UTILIZATION = 25
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 5
export PLACE_DENSITY = 0.55
