import numpy as np

IMAGE_SIZE = 30


def sobel_filter(image):
    """Apply Sobel edge detection using NumPy only."""
    if image.ndim != 2:
        raise ValueError("Input must be a grayscale image")

    image = image.astype(np.int16)

    gx_kernel = np.array([
        [-1, 0, 1],
        [-2, 0, 2],
        [-1, 0, 1]
    ], dtype=np.int16)

    gy_kernel = np.array([
        [-1, -2, -1],
        [ 0,  0,  0],
        [ 1,  2,  1]
    ], dtype=np.int16)

    output = np.zeros(image.shape, dtype=np.uint8)

    for y in range(1, image.shape[0] - 1):
        for x in range(1, image.shape[1] - 1):
            window = image[y-1:y+2, x-1:x+2]

            gx = int(np.sum(window * gx_kernel))
            gy = int(np.sum(window * gy_kernel))

            magnitude = abs(gx) + abs(gy)
            output[y, x] = min(magnitude, 255)

    return output


if __name__ == "__main__":
    image = np.zeros((IMAGE_SIZE, IMAGE_SIZE), dtype=np.uint8)

    # Synthetic square with sharp edges
    image[8:22, 8:22] = 200

    edges = sobel_filter(image)

    print("Input image shape:", image.shape)
    print("Output image shape:", edges.shape)
    print("Detected edge pixels:", np.count_nonzero(edges))
