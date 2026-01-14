from PIL import Image
import numpy as np

# load image and convert to grayscale
img = Image.open("testimg.png").convert("L")
img = img.resize((128, 128))

pixels = np.array(img)

# write pixels to text file (row-major order)
with open("input_pixels.txt", "w") as f:
    for y in range(128):
        for x in range(128):
            f.write(f"{pixels[y, x]}\n")

print("Wrote", pixels.size, "pixels to input_pixels.txt")
print("First pixel:", pixels[0, 0])
print("Last pixel:", pixels[-1, -1])
