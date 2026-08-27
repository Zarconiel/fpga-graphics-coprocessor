module vga_timing (

    input  wire       pixel_clk,
    input  wire       reset,

    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y,

    output wire       hsync,
    output wire       vsync,
    output wire       video_active,
    output wire       frame_start
);

    // =========================================================
    // VGA 640x480 ~60 Hz
    // Pixel clock = aproximadamente 25 MHz
    // =========================================================

    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;


    // =========================================================
    // Contadores horizontal e vertical
    // =========================================================

    always @(posedge pixel_clk or posedge reset) begin

        if (reset) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end

        else begin

            if (pixel_x == H_TOTAL - 1) begin

                pixel_x <= 10'd0;

                if (pixel_y == V_TOTAL - 1)
                    pixel_y <= 10'd0;
                else
                    pixel_y <= pixel_y + 10'd1;

            end

            else begin
                pixel_x <= pixel_x + 10'd1;
            end

        end

    end


    // Área visível da tela
    assign video_active =
        (pixel_x < H_VISIBLE) &&
        (pixel_y < V_VISIBLE);


    // HSYNC ativo em nível baixo
    assign hsync =
        ~(
            (pixel_x >= H_VISIBLE + H_FRONT) &&
            (pixel_x <  H_VISIBLE + H_FRONT + H_SYNC)
        );


    // VSYNC ativo em nível baixo
    assign vsync =
        ~(
            (pixel_y >= V_VISIBLE + V_FRONT) &&
            (pixel_y <  V_VISIBLE + V_FRONT + V_SYNC)
        );


    // Primeiro pixel de cada quadro
    assign frame_start =
        (pixel_x == 10'd0) &&
        (pixel_y == 10'd0);


endmodule
