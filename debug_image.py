import numpy as np
from PIL import Image

pixels = np.loadtxt("output_pixels.txt", dtype=np.uint8)

# make a tall image just to visualize data
img = pixels.reshape((-1, 1))
Image.fromarray(img, mode="L").save("debug_output.png")
