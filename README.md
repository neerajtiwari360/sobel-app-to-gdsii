# Sobel Edge Detection Accelerator: Application to GDSII

End-to-end development of a 30x30 grayscale Sobel accelerator.

## Design Flow

1. Python/NumPy reference implementation
2. Hardware architecture and fixed-point design
3. Verilog RTL implementation
4. Functional simulation and verification
5. FPGA synthesis and implementation
6. ASIC logic synthesis
7. ASIC floorplanning and placement
8. Clock tree synthesis and routing
9. Timing verification and GDSII generation

## Specifications

- Image: 30x30 pixels
- Input: 8-bit unsigned grayscale
- Operator: 3x3 Sobel Gx/Gy
- Magnitude: abs(Gx) + abs(Gy)
- Output: 8-bit saturated value
- Image boundary: zero-valued output pixels

## Project Status

Initial Python reference and combinational RTL core created.
Streaming architecture, verification and implementation pending.
