/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Author: Uri Shaked


 - Modified by Pongsgon Vichitvejpaisal to 
  load 320x240 6-bit color image
 */

`default_nettype none

parameter IMG_SIZE = 320;  // Size of the image in pixels
parameter MUL_FACTOR = 2;   // vga_res/img_size
parameter DISPLAY_WIDTH = 640;  // VGA display width
parameter DISPLAY_HEIGHT = 480;  // VGA display height

`define COLOR_WHITE 3'd7

module tt_um_vga_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in[7:1], uio_in};

  // Toasting timer
  reg [31:0] counter;
  reg counter_prev;
  wire counter_cur = counter[15];
  reg counter_prev2;
  wire couter_cur2 = counter[5];
  wire slider_tick;
  wire random_tick;
  assign random_tick = (~counter_prev2) && couter_cur2;

  assign slider_tick = (~counter_prev) && counter_cur;

  // Slider
  reg [9:0] slider_x;
  reg [9:0] slider_negx;

  // Random
  reg mask [0:307199];
  reg [31:0] mask_idx;

  // Add state
  reg [1:0] current_state;
  reg [1:0] next_state;

  // ui_in_prev
  reg [7:0] ui_in_prev;
  wire [7:0] btn_press;
  assign btn_press = ~ui_in_prev & ui_in;

  localparam IDLE = 2'd0;
  localparam CHANGING_SLIDE = 2'd1;
  localparam CHANGING_DOT = 2'd2;

  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  reg [5:0] img[76799:0];  // 320x240
  reg [5:0] img2[76799:0];  // 320x240
  wire [16:0] mem_index;
  reg [5:0] color;

  initial begin
    $readmemh("../data/bg1_dithering.mem", img);
    $readmemh("../data/bg1.mem", img2);
    for (integer i = 0; i < 307200; i = i + 1) begin
      mask[i] = 1'b0;
    end
  end

  always @(*) begin
    if(!rst_n) begin
      next_state = 2'd0;
    end else begin
      next_state = current_state;
      case(current_state)
        2'd0:begin
          if(btn_press[0])begin
            next_state = CHANGING_SLIDE;
          end
          if(btn_press[1])begin
            next_state = CHANGING_DOT;
          end
        end
        2'd1:begin
          if(slider_x >= 640)begin
            next_state = IDLE;
          end
        end
      endcase
    end
  end

  always @(posedge clk)begin
    color <= img[mem_index];
    color <= img2[mem_index];
    if(!rst_n) begin
      counter <= 0;
      counter_prev <= 0;
      counter_prev2 <= 0;
      slider_x <= 0;
      slider_negx <= 640;
      current_state <= 0;
      ui_in_prev <= 0;
      mask_idx <= 0;
    end else begin
      current_state <= next_state;
      ui_in_prev <= ui_in;
      mask_idx <= mask_idx;
      case(current_state)
        2'd0:begin
          counter <= 0;
          counter_prev <= 0;
          slider_x <= 0;
          slider_negx <= 640;
          mask_idx <= 0;
        end
        2'd1:begin
          counter <= counter + 1;
          counter_prev <= counter_cur;
          
          if(slider_tick) begin
            slider_x <= (slider_x >= 640)? 0:slider_x + 1;
            slider_negx <= (slider_x <= 0)? 640:slider_negx - 1;
          end

          if(pix_x < slider_x && pix_y[5] == 0) begin
            color <= img[mem_index];
          end

          if(pix_x > slider_negx && pix_y[5] == 1) begin
            color <= img[mem_index];
          end
        end
        2'd2:begin
          counter <= counter + 1;
          counter_prev2 <= couter_cur2;
          if(random_tick)begin
            mask[mask_idx] <= 1;
            mask_idx <= (mask_idx + 27434317) % 307200;
          end
          if(mask[pix_x + pix_y * 640])begin
            color <= img[mem_index];
          end
        end
      endcase

    end
  end

  assign mem_index = (pix_y / MUL_FACTOR) * IMG_SIZE + pix_x / MUL_FACTOR;  
  // assign color = img[mem_index]+img2[mem_index];
  assign R = (video_active)? color[5:4]:0;
  assign G = (video_active)? color[3:2]:0;
  assign B = (video_active)? color[1:0]:0;



endmodule