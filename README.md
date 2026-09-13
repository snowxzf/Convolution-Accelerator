# Convolution Accelerator

A small SystemVerilog hardware accelerator that applies a **3×3 box blur** to a
128×128 grayscale image. Pixels stream in one per clock in row-major order; the
design keeps a rolling 3×3 neighbourhood using on-chip line buffers, adds up the
nine pixels, divides by nine, and streams the blurred pixels back out.

There are two interchangeable implementations of the maths — a fast parallel one
and a small resource-shared one — sharing the same front end.

## How it works

The pipeline is:

```
pixel_in ─► line_buffer ─► window (3×3) ─► convolution ─► normalizer ─► pixel_out
```

- **`line_buffer`** — remembers the previous two image rows, so at any pixel the
  design can also see the two pixels directly above it without re-reading memory.
- **`window` (`window_3x3.sv`)** — maintains the sliding 3×3 block of pixels
  around the current position (`w00 … w22`), zero-padding at the image edges.
- **convolution** — sums the nine window pixels (a box blur weights them all
  equally). Two versions are provided:
  - **`convolution_9mac`** — nine multipliers working in parallel; produces one
    blurred pixel every clock cycle. Fast, uses more hardware.
  - **`convolution_onemac`** — a single multiply-accumulate unit reused nine
    times. Smaller and cheaper, but slower, so it uses a `ready` handshake and
    works on one window at a time.
- **`normalizer`** — divides the sum by 9 and outputs the final 8-bit pixel.
- **`mac_unit`** — the multiply-accumulate building block used by the
  single-MAC convolution.
- **`blur_top` / `blur_top9`** — the top-level modules that track the current
  row/column, decide when an output pixel is valid, and wire everything
  together. `blur_top` uses the single-MAC core; `blur_top9` uses the 9-MAC core.

## Files

**Hardware (SystemVerilog)**

| File | Role |
|------|------|
| `blur_top9.sv` | Top level for the 9-MAC (parallel) design |
| `blur_top.sv` | Top level for the single-MAC (resource-shared) design |
| `line_buffer.sv` | Stores the previous two rows |
| `window_3x3.sv` | Builds the sliding 3×3 window |
| `convolution_9mac.sv` | Nine parallel multipliers |
| `convolution_onemac.sv` | One shared multiply-accumulate |
| `mac_unit.sv` | Multiply-accumulate primitive |
| `normalizer.sv` | Divides the sum by 9 |
| `tb_blur9.sv` | Testbench for the 9-MAC design |
| `tb_blur.sv` | Testbench for the single-MAC design |

**Python helpers**

| File | Role |
|------|------|
| `convert_pixels.py` | Turns an image (`testimg.png`) into `input_pixels.txt` |
| `gen_image.py` | Turns `output_pixels.txt` back into `blurred.png` |
| `debug_image.py` | Renders the raw output as a tall strip for debugging |

**Data**

| File | Role |
|------|------|
| `input_pixels.txt` | The 128×128 input image, one pixel value per line |
| `output_pixels9.txt` | Output of the 9-MAC design |
| `output_pixels.txt` | Output of the single-MAC design |
| `blurred.png` | The blurred result as an image |

## Running it

The testbenches read `input_pixels.txt` and write the blurred pixels to a text
file. Run them from this folder (so the paths line up) in ModelSim/Questa:

```tcl
vlib work

# 9-MAC design -> output_pixels9.txt
vlog -sv line_buffer.sv window_3x3.sv convolution_9mac.sv normalizer.sv blur_top9.sv tb_blur9.sv
vsim -c -do "run -all; quit -f" tb_blur9

# single-MAC design -> output_pixels.txt
vlog -sv mac_unit.sv line_buffer.sv window_3x3.sv convolution_onemac.sv normalizer.sv blur_top.sv tb_blur.sv
vsim -c -do "run -all; quit -f" tb_blur
```

Then turn the output back into a picture:

```bash
python gen_image.py      # reads output_pixels.txt -> blurred.png
```

To blur a different image, drop a `testimg.png` in this folder and run
`python convert_pixels.py` first to regenerate `input_pixels.txt`.

## Notes

- The image size is fixed at **128×128**.
- Edges use **zero padding**, so the outermost pixels come out slightly darker
  than the interior.
- The blurred image is shifted by one pixel down-and-right compared to the input,
  because the current pixel sits at the bottom-right corner of the window — this
  is normal for a streaming line-buffer design.
