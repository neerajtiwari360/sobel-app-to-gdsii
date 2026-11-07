# Sobel application-to-GDSII in Docker

This is an overlay for your **existing** `sobel-app-to-gdsii` repository.
It does not replace any files under `python/`, `rtl/`, `tb/` or `tb/vectors/`.

## Requirements
- Windows 11 with Docker Desktop installed and Linux containers enabled
- Enough free disk space for the `openroad/orfs:latest` image and intermediate build data
- Existing source files and testbenches that passed 900/900 verification

## One-time setup
Copy the supplied Docker bundle files to your repository root, preserving subfolders.
From PowerShell:

```powershell
cd D:\Github\sobel-app-to-gdsii
docker info
docker compose build
```

## End-to-end run

```powershell
docker compose run --rm sobel-asic
```

This invokes, inside Linux containers:

1. Python/NumPy application, input/expected vectors
2. Icarus Verilog mathematical-core verification
3. Icarus Verilog streaming verification
4. Yosys generic logic synthesis and `check -assert`
5. ORFS/Yosys SKY130HD standard-cell mapping, floorplanning, placement, CTS, routing, timing and GDSII export

## Outputs on Windows

- `results/netlist/sobel_top_generic.v`: synthesised generic logic
- `results/asic/generic_synthesis.log`: synthesis statistics
- `results/asic/orfs/results`: all ORFS intermediates including technology-mapped netlists and DEF/ODB files
- `results/asic/orfs/reports`: timing, area and route reports
- `results/asic/orfs/logs`: tool logs
- `results/asic/sobel_top_sky130hd.gds`: final merged GDSII if the flow succeeds
- `simulation/waveforms/sobel_stream.vcd`: signal waveform, from Icarus

The open-source flow is **not equivalent to signoff**. Inspect DRC results, run independent full-chip DRC/LVS if required, and check all timing and power corners before considering fabrication.

## Troubleshooting
- If Docker Desktop isn't running, `docker info` will fail. Start Docker Desktop with Linux containers.
- If the image lacks a usable `sky130hd` platform or the ORFS configuration changes, the flow will stop and report an error instead of producing a fake success.
- If detailed routing cannot complete, inspect `results`/`logs` if present; the script intentionally returns failure.
- These are starter clock/placement constraints. Meeting 50 ns is not guaranteed until STA reports show it.
- As a first improvement, pin `openroad/orfs` to a tested image digest for reproducible results across future releases.

## Visualising netlists and layout
- Generic netlist is Verilog; use Yosys `show` plus Graphviz or a schematic viewer to render selected modules.
- GDSII can be opened with KLayout on Windows. It contains geometries, not simulation waveforms.
- The VCD waveform can be opened using GTKWave if installed.
