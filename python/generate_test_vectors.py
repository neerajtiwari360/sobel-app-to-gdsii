import numpy as np
from sobel_reference import sobel_filter

rng = np.random.default_rng(42)

image = rng.integers(
    0, 256, size=(30, 30), dtype=np.uint8
)

edges = sobel_filter(image)

np.savetxt(
    "tb/vectors/input.hex",
    image.flatten(),
    fmt="%02x"
)

np.savetxt(
    "tb/vectors/expected.hex",
    edges.flatten(),
    fmt="%02x"
)

print("Generated 900 input pixels")
print("Generated 900 expected output pixels")
