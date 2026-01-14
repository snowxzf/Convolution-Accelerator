import numpy as np
from PIL import Image

pixels = []

with open("output_pixels.txt") as f:
    for line in f:
        pixels.append(int(line.strip()))

print("Output pixels:", len(pixels))
print("Min:", min(pixels))
print("Max:", max(pixels))

# read output pixels
with open("output_pixels.txt") as f:
    pixels = [int(line.strip()) for line in f]

# output image will be smaller due to borders
w = 128  # 128 - 2
h = 128

img_out = np.array(pixels).reshape(h, w)
Image.fromarray(img_out.astype(np.uint8), mode="L").save("blurred.png")


