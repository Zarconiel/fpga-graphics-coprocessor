module rectangle_rasterizer (

    // Pixel lógico atual
    input  wire [8:0] pixel_x,
    input  wire [7:0] pixel_y,

    // Retângulo
    input  wire [8:0] x0,
    input  wire [7:0] y0,

    input  wire [8:0] x1,
    input  wire [7:0] y1,

    // Aparência
    input  wire [7:0] color,
    input  wire [1:0] priority,

    input  wire       enable,

    // Resultado
    output wire       pixel_valid,
    output wire [7:0] pixel_color,
    output wire [1:0] pixel_priority

);


    // =========================================================
    // TESTE DE PERTENCIMENTO
    //
    // O pixel pertence ao retângulo quando:
    //
    // x0 <= x <= x1
    // y0 <= y <= y1
    //
    // O retângulo é preenchido.
    // =========================================================

    wire inside_rectangle;


    assign inside_rectangle =

        (pixel_x >= x0) &&
        (pixel_x <= x1) &&

        (pixel_y >= y0) &&
        (pixel_y <= y1);


    // =========================================================
    // SAÍDAS
    //
    // Cor 0 é transparente.
    // =========================================================

    assign pixel_valid =
        enable &&
        inside_rectangle &&
        (color != 8'd0);


    assign pixel_color =
        pixel_valid ? color : 8'd0;


    assign pixel_priority =
        pixel_valid ? priority : 2'd0;


endmodule