module gpu_core (

    input  wire        clk,
    input  wire        pixel_clk,
    input  wire        reset,

    // =========================================================
    // INTERFACE DE COMANDOS
    // =========================================================

    input  wire        command_valid,
    input  wire [31:0] command_data,

    output wire        command_ready,


    // =========================================================
    // VGA
    // =========================================================

    output wire [7:0]  vga_r,
    output wire [7:0]  vga_g,
    output wire [7:0]  vga_b,

    output wire        vga_hs,
    output wire        vga_vs,
    output wire        vga_blank_n

);


    // =========================================================
    // VGA TIMING
    // =========================================================

    wire [9:0] vga_x;
    wire [9:0] vga_y;

    wire video_active;
    wire frame_start;


    vga_timing timing_inst (

        .pixel_clk    (pixel_clk),
        .reset        (reset),

        .pixel_x      (vga_x),
        .pixel_y      (vga_y),

        .hsync        (vga_hs),
        .vsync        (vga_vs),

        .video_active (video_active),
        .frame_start  (frame_start)

    );


    // =========================================================
    // RESOLUCAO LOGICA 320x240
    // =========================================================

    wire [8:0] logical_x;
    wire [7:0] logical_y;


    assign logical_x = vga_x >> 1;
    assign logical_y = vga_y >> 1;


    // =========================================================
    // COMMAND DECODER
    // =========================================================

    wire        reg_write_enable;
    wire [7:0]  reg_write_address;
    wire [19:0] reg_write_data;


    wire        tilemap_write_enable;
    wire [10:0] tilemap_write_address;
    wire [7:0]  tilemap_write_data;


    wire        tile_write_enable;
    wire [13:0] tile_write_address;
    wire [7:0]  tile_write_data;


    wire        sprite_write_enable;
    wire [4:0]  sprite_index;
    wire [3:0]  sprite_field;
    wire [18:0] sprite_data;


    wire invalid_command;


    command_decoder decoder_inst (

        .clk                   (clk),
        .reset                 (reset),

        .command_valid         (command_valid),
        .command_data          (command_data),

        .command_ready         (command_ready),


        .reg_write_enable      (reg_write_enable),
        .reg_write_address     (reg_write_address),
        .reg_write_data        (reg_write_data),


        .tilemap_write_enable  (tilemap_write_enable),
        .tilemap_write_address (tilemap_write_address),
        .tilemap_write_data    (tilemap_write_data),


        .tile_write_enable     (tile_write_enable),
        .tile_write_address    (tile_write_address),
        .tile_write_data       (tile_write_data),


        .sprite_write_enable   (sprite_write_enable),
        .sprite_index          (sprite_index),
        .sprite_field          (sprite_field),
        .sprite_data           (sprite_data),


        .invalid_command       (invalid_command)

    );


    // =========================================================
    // REGISTRADORES
    // =========================================================

    wire [8:0] scroll_x;
    wire [7:0] scroll_y;

    wire bg_enable;


    // Retangulo

    wire       rect_enable;

    wire [8:0] rect_x0;
    wire [7:0] rect_y0;

    wire [8:0] rect_x1;
    wire [7:0] rect_y1;

    wire [7:0] rect_color;
    wire [1:0] rect_priority;


    // Triangulo

    wire       tri_enable;

    wire [8:0] tri_x0;
    wire [7:0] tri_y0;

    wire [8:0] tri_x1;
    wire [7:0] tri_y1;

    wire [8:0] tri_x2;
    wire [7:0] tri_y2;

    wire [7:0] tri_color;
    wire [1:0] tri_priority;


    gpu_registers registers_inst (

        .clk           (clk),
        .reset         (reset),

        .write_enable  (reg_write_enable),
        .write_address (reg_write_address),
        .write_data    (reg_write_data),


        // Background

        .scroll_x      (scroll_x),
        .scroll_y      (scroll_y),
        .bg_enable     (bg_enable),


        // Retangulo

        .rect_enable   (rect_enable),

        .rect_x0       (rect_x0),
        .rect_y0       (rect_y0),

        .rect_x1       (rect_x1),
        .rect_y1       (rect_y1),

        .rect_color    (rect_color),
        .rect_priority (rect_priority),


        // Triangulo

        .tri_enable    (tri_enable),

        .tri_x0        (tri_x0),
        .tri_y0        (tri_y0),

        .tri_x1        (tri_x1),
        .tri_y1        (tri_y1),

        .tri_x2        (tri_x2),
        .tri_y2        (tri_y2),

        .tri_color     (tri_color),
        .tri_priority  (tri_priority)

    );


    // =========================================================
    // BACKGROUND
    // =========================================================

    wire [7:0] background_color;


    background_engine background_inst (

        .clk                   (clk),

        .logical_x             (logical_x),
        .logical_y             (logical_y),

        .scroll_x              (scroll_x),
        .scroll_y              (scroll_y),


        .tilemap_write_enable  (tilemap_write_enable),
        .tilemap_write_address (tilemap_write_address),
        .tilemap_write_data    (tilemap_write_data),


        .tile_write_enable     (tile_write_enable),
        .tile_write_address    (tile_write_address),
        .tile_write_data       (tile_write_data),


        .background_color      (background_color)

    );


    // =========================================================
    // POLIGONOS
    // =========================================================

    wire       polygon_valid;
    wire [7:0] polygon_color;
    wire [1:0] polygon_priority;


    polygon_engine polygon_inst (

        .logical_x        (logical_x),
        .logical_y        (logical_y),


        // Retangulo

        .rect_enable      (rect_enable),

        .rect_x0          (rect_x0),
        .rect_y0          (rect_y0),

        .rect_x1          (rect_x1),
        .rect_y1          (rect_y1),

        .rect_color       (rect_color),
        .rect_priority    (rect_priority),


        // Triangulo

        .tri_enable       (tri_enable),

        .tri_x0           (tri_x0),
        .tri_y0           (tri_y0),

        .tri_x1           (tri_x1),
        .tri_y1           (tri_y1),

        .tri_x2           (tri_x2),
        .tri_y2           (tri_y2),

        .tri_color        (tri_color),
        .tri_priority     (tri_priority),


        // Resultado

        .polygon_valid    (polygon_valid),
        .polygon_color    (polygon_color),
        .polygon_priority (polygon_priority)

    );


    // =========================================================
    // SPRITES
    // =========================================================

    wire       sprite_valid;
    wire [7:0] sprite_color;
    wire [1:0] sprite_priority;


    sprite_engine sprite_inst (

        .clk                 (clk),
        .reset               (reset),

        .logical_x           (logical_x),
        .logical_y           (logical_y),


        .sprite_write_enable (sprite_write_enable),
        .sprite_index        (sprite_index),
        .sprite_field        (sprite_field),
        .sprite_data         (sprite_data),


        .tile_write_enable   (tile_write_enable),
        .tile_write_address  (tile_write_address),
        .tile_write_data     (tile_write_data),


        .sprite_valid        (sprite_valid),
        .sprite_color        (sprite_color),
        .sprite_priority     (sprite_priority)

    );


    // =========================================================
    // BACKGROUND ENABLE
    // =========================================================

    wire [7:0] active_background_color;


    assign active_background_color =
        bg_enable
        ? background_color
        : 8'd0;


    // =========================================================
    // COMPOSITOR
    // =========================================================

    wire [7:0] composed_color;


    compositor compositor_inst (

        .background_color (active_background_color),

        .polygon_valid    (polygon_valid),
        .polygon_color    (polygon_color),
        .polygon_priority (polygon_priority),

        .sprite_valid     (sprite_valid),
        .sprite_color     (sprite_color),
        .sprite_priority  (sprite_priority),

        .final_color      (composed_color)

    );


    // =========================================================
    // COR FINAL
    // =========================================================

    wire [7:0] color_index;


    assign color_index =
        video_active
        ? composed_color
        : 8'd0;


    // =========================================================
    // PALETA
    // =========================================================

    wire [7:0] palette_r;
    wire [7:0] palette_g;
    wire [7:0] palette_b;


    palette_ram palette_inst (

        .clk           (clk),

        .write_enable  (1'b0),
        .write_address (8'd0),
        .write_data    (24'h000000),

        .color_index   (color_index),

        .red           (palette_r),
        .green         (palette_g),
        .blue          (palette_b)

    );


    // =========================================================
    // VGA
    // =========================================================

    assign vga_r =
        video_active ? palette_r : 8'h00;

    assign vga_g =
        video_active ? palette_g : 8'h00;

    assign vga_b =
        video_active ? palette_b : 8'h00;


    assign vga_blank_n =
        video_active;


endmodule