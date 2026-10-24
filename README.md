# Image Toaster FPGA

Image Toaster FPGA is a Verilog graphics project that displays an image over VGA and demonstrates two image transition effects: alternating horizontal strips that slide in from opposite sides, and a scattered-dot reveal.

This project was created as part of a college course for learning purposes. It explores VGA timing, image memory, finite-state machines, and simple graphics effects in hardware description language.

## Try It in VGA Playground

[Open Image Toaster FPGA in VGA Playground](https://vga-playground.com/?repo=https://github.com/789852tonnam/ImageToasterFPGA)

## Demo Video

[Watch the demo video](demo.mp4)

## How It Works

- Two 320 × 240 images are loaded from hexadecimal memory files: a base image and a dithered version.
- Each pixel uses 6-bit RGB color, with 2 bits per color channel.
- The image is scaled by a factor of 2 to fill the 640 × 480 VGA display.
- A VGA synchronization module generates horizontal sync, vertical sync, and visible-area signals. The configured pixel clock is 25.175 MHz.
- A state machine controls the slide and scattered-dot transitions from the base image to the dithered image.

## Controls

The design detects rising edges on the dedicated inputs while idle:

| Signal | Action |
| --- | --- |
| `ui_in[0]` | Start the alternating-strip slide transition. |
| `ui_in[1]` | Start the scattered-dot reveal transition. |
| `rst_n` | Active-low reset; return the controller to its initial state. |

## File Structure

```text
image_toaster/
├── README.md                 # Project overview and usage
├── demo.mp4                  # Demonstration video
├── info.yaml                 # Project configuration, source list, clock, and pinout
├── data/
│   ├── bg1.mem               # Base image: 320 × 240, 6-bit RGB
│   └── bg1_dithering.mem     # Dithered image: 320 × 240, 6-bit RGB
└── src/
    ├── Img_vgaPlayground.v   # Top module, image memories, controls, and transitions
    └── hsync_generator.v     # VGA synchronization and pixel position generator
```

The top-level module is `tt_um_vga_example`. Its VGA outputs follow the TinyVGA PMOD mapping defined in `info.yaml`.

The image-loading paths in `Img_vgaPlayground.v` use `../data/`. When running a local simulation, use `src/` as the working directory or adjust those paths for your simulator.

## Acknowledgments

The top-level source is based on a Tiny Tapeout VGA example credited to Uri Shaked, with image-loading modifications credited to Pongsgon Vichitvejpaisal. See the source header for the original copyright and SPDX notice.
