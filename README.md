# Sobel Edge Detection Accelerator — Application to GDSII

**End-to-End Digital Hardware Design | Python → Verilog RTL → ASIC → GDSII**

A complete, Docker-based digital hardware design project demonstrating the development of a **30×30 grayscale Sobel edge detection accelerator**, starting from a Python/NumPy application and progressing through RTL design, simulation, logic synthesis, technology mapping, floorplanning, placement, clock-tree synthesis, routing and GDSII generation.

The project uses **Yosys, Icarus Verilog, OpenROAD, KLayout and the SKY130HD standard-cell library** to demonstrate the application-to-silicon design methodology.

The primary objective is to understand how a software algorithm becomes a hardware circuit and eventually a physical ASIC layout.

## 1. Project Overview

| Parameter | Specification |
|---|---|
| Application | Sobel edge detection |
| Input image | 30 × 30 grayscale |
| Input pixel | Unsigned 8-bit |
| Output pixel | Unsigned 8-bit |
| Convolution | 3 × 3 Sobel X and Y kernels |
| Edge magnitude | `min(255, abs(Gx) + abs(Gy))` |
| Pixel interface | Streaming, valid/ready handshake |
| Hardware language | Verilog |
| RTL simulator | Icarus Verilog |
| Logic synthesis | Yosys |
| ASIC technology | SKY130HD (130 nm) |
| Physical design | OpenROAD |
| Layout viewer | KLayout |
| Environment | Docker / Docker Compose |
| Development host | Windows 11 |

### Project objectives

- Implement a computer vision algorithm using Python and NumPy.
- Translate the application into synthesizable Verilog RTL.
- Design line buffers, a sliding-window generator, arithmetic logic and control circuitry.
- Verify RTL results against a Python golden reference.
- Understand the differences between combinational and sequential hardware.
- Synthesize RTL into generic logic and ASIC standard cells.
- Perform ASIC floorplanning, placement, clock-tree synthesis and routing.
- Generate and inspect the final GDSII layout.
- Analyse hardware area, timing, resource utilisation and opportunities for optimisation.

## 2. Complete Application-to-ASIC Flow

```text
                  APPLICATION DEVELOPMENT
                            |
                            v
                  Python / NumPy Sobel
                            |
                            v
                 Golden Reference Outputs
                            |
                            v
                    RTL ARCHITECTURE
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
         Sobel Core     Line Buffers    Controller
             |              |              |
             +--------------+--------------+
                            |
                            v
                     Verilog RTL
                            |
                            v
                    RTL VERIFICATION
                            |
                    Icarus Verilog
                            |
              Compare with Python outputs
                            |
                            v
                      LOGIC SYNTHESIS
                            |
                          Yosys
                            |
                            v
                  Generic Logic Netlist
                            |
                            v
                   TECHNOLOGY MAPPING
                            |
                  SKY130HD Standard Cells
                            |
                            v
                   ASIC PHYSICAL DESIGN
                            |
                        Floorplan
                            |
                        Placement
                            |
                   Clock Tree Synthesis
                            |
                      Global Routing
                            |
                     Detailed Routing
                            |
                            v
                   Physical Design Reports
                            |
                            v
                     GDSII GENERATION
                            |
                            v
                  sobel_top_sky130hd.gds
```

The workflow is executed using Docker to reduce host-specific tool installation requirements.

## 3. Repository Structure

```text
sobel-app-to-gdsii/
|
|-- README.md
|-- Dockerfile
|-- compose.yaml
|-- .dockerignore
|-- .gitignore
|-- requirements.txt
|
|-- python/
|   |-- sobel_reference.py
|   |-- generate_test_vectors.py
|   |-- images/
|   |-- outputs/
|   `-- tests/
|
|-- rtl/
|   |-- sobel_core.v
|   |-- line_buffer.v
|   `-- sobel_top.v
|
|-- tb/
|   |-- tb_sobel.v
|   |-- tb_sobel_stream.v
|   `-- vectors/
|       |-- input.hex
|       `-- expected.hex
|
|-- docker/
|   `-- run-all.sh
|
|-- asic/
|   |-- config.mk
|   |-- constraints/
|   |   `-- timing.sdc
|   `-- scripts/
|
|-- fpga/
|   |-- constraints/
|   `-- scripts/
|
|-- simulation/
|   `-- waveforms/
|
|-- results/
|   |-- netlist/
|   |-- synthesis/
|   |-- timing/
|   |-- physical_design/
|   `-- asic/
|       |-- sobel_top_sky130hd.gds
|       `-- orfs/
|           |-- reports/
|           |-- results/
|           `-- logs/
|
|-- docs/
`-- scripts/
```

Generated simulation and ASIC outputs are excluded from normal Git tracking. The `results/` directory is recreated when the workflow runs.

## 4. Stage 1 — Python Application

**Source:** `python/sobel_reference.py`

The initial application performs Sobel edge detection on an 8-bit grayscale image using NumPy.

### Sobel kernels

Horizontal gradient:

```text
Gx = [-1   0   1]
     [-2   0   2]
     [-1   0   1]
```

Vertical gradient:

```text
Gy = [-1  -2  -1]
     [ 0   0   0]
     [ 1   2   1]
```

The final pixel magnitude is calculated as:

```python
magnitude = abs(gx) + abs(gy)
output_pixel = min(magnitude, 255)
```

The implementation uses integer arithmetic and 8-bit saturation to make its numerical behaviour reproducible in RTL.

The outermost image-border pixels are assigned zero.

### Golden reference generation

**Source:** `python/generate_test_vectors.py`

A deterministic 30×30 random grayscale image is generated and processed using the Python Sobel implementation.

Two files are produced:

- `tb/vectors/input.hex` — 900 input pixel values.
- `tb/vectors/expected.hex` — 900 reference output values.

These files provide the reference data for RTL functional verification.

## 5. Stage 2 — RTL Hardware Architecture

The Sobel application is implemented as three Verilog modules.

### `sobel_core.v` — Arithmetic datapath

The Sobel core accepts a complete 3×3 pixel window:

```text
P00 P01 P02
P10 P11 P12
P20 P21 P22
```

Its input width is:

```text
9 pixels × 8 bits = 72 bits
```

The core performs:

1. Horizontal Sobel gradient computation.
2. Vertical Sobel gradient computation.
3. Signed absolute-value calculation.
4. Gradient magnitude addition.
5. 8-bit output saturation.

The arithmetic is combinational. Sobel's constant coefficients allow additions, subtractions and shifts to replace general-purpose multiplication.

### `line_buffer.v` — Pixel buffering

The line-buffer module converts sequential input pixels into 3×3 neighbourhoods.

The initial implementation contains:

- Two previous-row buffers.
- Horizontal sliding-window registers.
- Indexed pixel storage.
- Window assembly logic.

The internal processing width is 32 pixels because the hardware uses a zero-padded image.

Two row buffers provide:

```text
2 × 32 × 8 = 512 bits
```

of logical pixel storage.

During synthesis, these buffers are currently expanded into flip-flops and associated logic rather than being mapped to dedicated SRAM macros.

### `sobel_top.v` — Streaming controller

The top-level module integrates the line buffer and arithmetic core.

Main interface signals:

| Signal | Description |
|---|---|
| `clk` | System clock |
| `rst` | Synchronous reset |
| `start` | Start image processing |
| `pixel_in[7:0]` | Grayscale input pixel |
| `in_valid` | Input data valid |
| `in_ready` | Input pixel acceptance |
| `edge_out[7:0]` | Processed output pixel |
| `out_valid` | Output pixel valid |
| `done` | Frame completion |

An input pixel is accepted when `in_valid` and `in_ready` are asserted together at the active clock edge.

The controller handles the padded image coordinates, window processing, output border conditions and completion signalling.

The initial accelerator uses a combinational Sobel datapath followed by an output register. Further arithmetic pipelining remains an optimisation opportunity.

## 6. Stage 3 — RTL Simulation and Verification

**Tool:** Icarus Verilog

Two testbenches verify different aspects of the hardware.

### Arithmetic verification

**File:** `tb/tb_sobel.v`

Tests the combinational Sobel core by supplying 3×3 windows and comparing the results against the Python reference.

Verified result:

```text
PASS: All 900 Sobel pixels match Python
```

### Streaming verification

**File:** `tb/tb_sobel_stream.v`

Tests the complete clocked accelerator, including input handshaking, line buffering, sliding-window generation and output sequencing.

Verified result:

```text
==== STREAMING SOBEL TEST ====
Input pixels  : 900
Output pixels : 900
Clock cycles  : 1025
Mismatches    : 0
PASS: 900/900 pixels match Python
```

The internal processing grid contains:

```text
32 × 32 = 1024 positions
```

The testbench reports 1,025 clock cycles, including startup counting.

The simulation uses a 10 ns clock period. This is a simulation setting and does not by itself establish the maximum achievable hardware clock frequency.

### Waveform generation

The streaming testbench generates:

```text
simulation/waveforms/sobel_stream.vcd
```

This file can be inspected with GTKWave to examine input handshakes, clock cycles, internal coordinates, window data, output values and control signals.

The current test results establish functional agreement for the supplied test vectors. Additional corner-case verification and formal equivalence checking remain future tasks.

## 7. Stage 4 — Docker Environment

The project uses Docker to execute the application, RTL simulation, synthesis and ASIC implementation tools within a reproducible Linux environment.

### Requirements

- Windows 11 with Docker Desktop.
- Docker configured to use Linux containers.
- Docker Compose.
- Sufficient storage for the OpenROAD image and generated design files.

### Build Docker image

From PowerShell:

```powershell
cd D:\Github\sobel-app-to-gdsii

docker compose build
```

The initial build downloads the OpenROAD Flow Scripts base image and installs the additional application and simulation dependencies.

### Run the complete workflow

```powershell
docker compose run --rm sobel-asic
```

The container executes the configured stages and exports the selected reports and final layout into the host repository.

The workflow has been successfully executed on this project and produced a GDSII file using SKY130HD.

### Rebuild after Dockerfile changes

```powershell
docker compose build
docker compose run --rm sobel-asic
```

Changes to bind-mounted Python, RTL or workflow scripts generally do not require rebuilding the image.

## 8. Stage 5 — Logic Synthesis

**Tool:** Yosys

Logic synthesis converts synthesizable Verilog RTL into a network of sequential and combinational logic.

This includes:

- RTL hierarchy elaboration.
- Process conversion.
- Constant propagation and logic optimisation.
- Register and multiplexer inference.
- Boolean logic mapping.
- Netlist generation.
- Structural checks.

### Generic synthesis results

| RTL module | Generic cell count |
|---|---:|
| `sobel_top` (local) | 95 |
| `line_buffer` | 1,749 |
| `sobel_core` | 481 |
| **Total** | **2,325** |

The complete generic netlist includes:

- 512 enabled flip-flops.
- 69 synchronously reset enabled flip-flops.
- 2 synchronously reset flip-flops.
- Combinational AND, NAND, OR, NOR, XOR, XNOR and multiplexer logic.

These are generic Yosys cell counts, not final SKY130 standard-cell counts.

### Structural verification

Yosys reported:

```text
Found and reported 0 problems.
```

This confirms that the structural checks completed without reporting problems. It is not a substitute for full formal verification.

## 9. Stage 6 — ASIC Technology Mapping

**Technology:** SKY130HD

**Tools:** Yosys and OpenROAD Flow Scripts

The generic synthesized design is mapped into physical standard cells from the SKY130HD library.

These cells represent actual library implementations of digital logic, including:

- Combinational logic gates.
- Flip-flops.
- Multiplexers.
- Clock buffers.
- Other library-specific logic functions.

Technology mapping considers the target library's logic functions and timing characteristics.

Unlike generic RTL operators, the mapped instances correspond to library cells with defined physical dimensions and electrical characteristics.

The resulting technology-mapped design becomes the input to ASIC physical implementation.

## 10. Stage 7 — ASIC Physical Design

**Tool:** OpenROAD

The physical-design flow has successfully executed through the final GDSII generation stage.

### 7.1 Floorplanning

Defines the initial chip core dimensions and standard-cell placement region.

Observed initial floorplanning results:

| Metric | Value |
|---|---:|
| Design cell area | 26,095 µm² |
| Target utilisation | 25% |
| Process | SKY130HD |

The area is the initial standard-cell design area, not the final die area.

### 7.2 Placement

OpenROAD performs global and detailed placement to position the technology-mapped cells within the chip core.

Placement attempts to balance:

- Wire length.
- Timing.
- Cell density.
- Routing congestion.
- Legal placement constraints.

### 7.3 Clock Tree Synthesis

Clock-tree synthesis constructs the physical clock distribution network to supply sequential elements.

The flow includes clock buffers and clock-network optimisation.

### 7.4 Global Routing

Global routing estimates and assigns routing paths, accounting for routing resources and congestion.

### 7.5 Detailed Routing

Detailed routing creates the actual interconnect geometry between cells using the available metal layers and vias.

The completed project generated the detailed-route database and subsequent final-layout outputs.

### 7.6 Finishing and GDSII generation

The finishing stages generated final design reports, layout data and the merged GDSII file.

The GDS merge log reported:

```text
All LEF cells have matching GDS/OAS cells
No orphan cells in the final layout
```

These checks establish successful layout-cell matching during the merge. They do not independently certify complete fabrication signoff.

## 11. Stage 8 — Final GDSII Output

**Generated file:**

```text
results/asic/sobel_top_sky130hd.gds
```

The GDSII file was successfully generated and its existence was verified on the development machine.

It contains the final physical layout geometry produced by the flow, including standard-cell instances and metal routing.

### View layout in KLayout

Download KLayout:

https://www.klayout.de/

Open:

```text
results/asic/sobel_top_sky130hd.gds
```

KLayout can be used to inspect the physical implementation, standard-cell locations, metal routing and layout layers.

GDSII generation demonstrates the RTL-to-layout flow; it does not mean that a physical silicon chip has been fabricated.

## 12. Generated Results and Reports

The Docker workflow exports OpenROAD reports to:

```text
results/asic/orfs/reports/
```

Important report files include:

| File | Description |
|---|---|
| `synth_stat.txt` | Technology-mapped synthesis statistics |
| `synth_check.txt` | Synthesis structural checks |
| `2_floorplan_final.rpt` | Floorplan report |
| `3_global_place.rpt` | Global placement report |
| `3_detailed_place.rpt` | Detailed placement report |
| `4_cts_final.rpt` | Clock-tree synthesis report |
| `5_global_route.rpt` | Global routing report |
| `6_finish.rpt` | Final physical-design report |
| `final_placement.webp` | Physical placement visualisation |
| `final_clocks.webp` | Clock network visualisation |
| `final_congestion.webp` | Routing congestion visualisation |
| `final_routing.webp` | Final routing visualisation |
| `final_worst_path.webp` | Critical timing-path visualisation |
| `final_ir_drop.webp` | IR-drop visualisation |

Generated reports and images allow the hardware implementation to be analysed without inspecting every intermediate build artifact.

### Examine final timing

From Windows PowerShell:

```powershell
Get-Content results\asic\orfs\reports\6_finish.rpt
```

To search for timing metrics:

```powershell
Get-Content results\asic\orfs\reports\6_finish.rpt |
    Select-String -Pattern "slack|wns|tns|setup|hold|violat"
```

The final timing result must be evaluated separately. Successful routing and GDSII generation do not automatically establish timing closure.

## 13. Verification and Signoff Status

| Verification item | Status |
|---|---|
| Python reference execution | Passed |
| RTL arithmetic test | Passed |
| Streaming RTL test | Passed |
| 900/900 pixel comparison | Passed |
| Generic Yosys structural check | Passed |
| SKY130HD technology mapping | Completed |
| Floorplanning | Completed |
| Placement | Completed |
| Clock tree synthesis | Completed |
| Global routing | Completed |
| Detailed routing | Completed |
| GDSII generation | Completed |
| Final timing closure | Requires report evaluation |
| Full manufacturing DRC | Not yet established |
| Layout versus schematic (LVS) | Not yet established |
| Formal RTL equivalence | Not yet established |
| Fabrication and silicon testing | Not performed |

This repository is an educational application-to-GDSII hardware design project, not a claim of fabrication-ready ASIC signoff.

## 14. Current Architecture Limitations

The initial implementation is intentionally simple to make the complete design flow understandable.

### Line-buffer implementation

The line buffers are synthesized largely into flip-flops and associated selection logic rather than dense SRAM macros.

A future version can investigate memory macros, memory inference and area-efficient buffering architectures.

### Arithmetic pipelining

The Sobel arithmetic is currently combinational between its input window and output register.

Additional pipeline stages may improve timing at the cost of latency and extra registers.

### Image padding

The hardware processes a 32×32 padded grid for a 30×30 image, introducing padding cycles.

Future optimisation can investigate a continuous pixel stream with more efficient border handling.

### Fixed image dimensions

The current design targets 30×30 images.

A later version can introduce parameterised image widths and heights.

### Verification coverage

The existing testbenches validate the primary mathematical and streaming behaviour.

Additional testing is needed for varying input-valid patterns, frame boundaries, resets, repeated frames, extreme pixel values and other corner cases.

## 15. Future Improvements

- [x] Python/NumPy Sobel algorithm
- [x] Golden reference generation
- [x] Combinational Sobel RTL
- [x] Streaming line-buffer architecture
- [x] RTL simulation and Python comparison
- [x] Docker-based ASIC toolchain
- [x] Generic logic synthesis
- [x] SKY130HD technology mapping
- [x] ASIC floorplanning
- [x] Standard-cell placement
- [x] Clock-tree synthesis
- [x] Global and detailed routing
- [x] GDSII generation
- [ ] Review timing closure and physical-design reports
- [ ] Add more extensive RTL verification
- [ ] Add automated gate-level or formal equivalence checking
- [ ] Run complete available physical DRC and LVS checks
- [ ] Compare different clock constraints
- [ ] Implement a pipelined Sobel arithmetic core
- [ ] Optimise line-buffer area
- [ ] Compare sequential and parallel processing architectures
- [ ] Investigate SRAM-based storage
- [ ] Implement and verify the design on an FPGA
- [ ] Extend the approach to an INT8 CNN accelerator

## 16. Lessons Learned

This project demonstrates the differences between application development, RTL design and ASIC implementation.

**Application development** defines the mathematical operations and expected outputs.

**RTL design** describes the clocked digital circuitry needed to execute those operations.

**Functional simulation** verifies the behaviour of the proposed hardware before physical implementation.

**Logic synthesis** converts RTL into a network of gates, registers and other digital logic elements.

**Technology mapping** selects appropriate standard cells from a specific semiconductor library.

**Physical design** converts the mapped netlist into placed cells and routed interconnects.

**GDSII generation** produces a physical layout database representing the resulting chip geometry.

An algorithm can be mathematically correct but inefficient as hardware. Area, timing, clock distribution, storage architecture, routing congestion and power must also be considered.

## 17. Related Future Project

The next planned project extends the same methodology to a small neural-network accelerator:

**`cnn-app-to-gdsii`**

It will explore:

- PyTorch model development.
- INT8 quantization.
- Multiply-accumulate hardware.
- Convolution engines.
- Weight and activation buffering.
- Fixed-point inference.
- RTL verification against model outputs.
- ASIC synthesis and physical implementation.

The Sobel project establishes the foundational RTL-to-GDSII methodology for that work.

## 18. Tools and References

- [Python](https://www.python.org/)
- [NumPy](https://numpy.org/)
- [Icarus Verilog](https://steveicarus.github.io/iverilog/)
- [Yosys](https://yosyshq.net/yosys/)
- [OpenROAD](https://openroad.readthedocs.io/)
- [OpenROAD Flow Scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
- [KLayout](https://www.klayout.de/)
- [SKY130 Open PDK](https://github.com/google/skywater-pdk)
- [Docker](https://www.docker.com/)

---

**Project status:** Application, RTL simulation, ASIC synthesis, physical implementation and GDSII generation completed successfully for the initial Sobel design. Further timing analysis, physical signoff verification and hardware optimisation are ongoing.

**Purpose:** Educational, reproducible, end-to-end digital hardware and ASIC design exploration.