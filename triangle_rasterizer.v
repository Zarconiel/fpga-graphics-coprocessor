module triangle_rasterizer (

    // =========================================================
    // PIXEL LÓGICO ATUAL
    // =========================================================

    input  wire [8:0] pixel_x,
    input  wire [7:0] pixel_y,


    // =========================================================
    // VÉRTICES DO TRIÂNGULO
    // =========================================================

    input  wire [8:0] x0,
    input  wire [7:0] y0,

    input  wire [8:0] x1,
    input  wire [7:0] y1,

    input  wire [8:0] x2,
    input  wire [7:0] y2,


    // =========================================================
    // APARÊNCIA
    // =========================================================

    input  wire [7:0] color,
    input  wire [1:0] priority,

    input  wire       enable,


    // =========================================================
    // RESULTADO
    // =========================================================

    output wire       pixel_valid,
    output wire [7:0] pixel_color,
    output wire [1:0] pixel_priority

);


    // =========================================================
    // CONVERSÃO PARA VALORES COM SINAL
    //
    // Precisamos de sinal porque as diferenças entre pontos
    // podem ser negativas.
    // =========================================================

    wire signed [10:0] sx;
    wire signed [9:0]  sy;

    wire signed [10:0] sx0;
    wire signed [9:0]  sy0;

    wire signed [10:0] sx1;
    wire signed [9:0]  sy1;

    wire signed [10:0] sx2;
    wire signed [9:0]  sy2;


    assign sx  = {1'b0, pixel_x};
    assign sy  = {1'b0, pixel_y};

    assign sx0 = {1'b0, x0};
    assign sy0 = {1'b0, y0};

    assign sx1 = {1'b0, x1};
    assign sy1 = {1'b0, y1};

    assign sx2 = {1'b0, x2};
    assign sy2 = {1'b0, y2};


    // =========================================================
    // DIFERENÇAS
    // =========================================================

    wire signed [10:0] dx01;
    wire signed [9:0]  dy01;

    wire signed [10:0] dx12;
    wire signed [9:0]  dy12;

    wire signed [10:0] dx20;
    wire signed [9:0]  dy20;


    assign dx01 = sx1 - sx0;
    assign dy01 = sy1 - sy0;

    assign dx12 = sx2 - sx1;
    assign dy12 = sy2 - sy1;

    assign dx20 = sx0 - sx2;
    assign dy20 = sy0 - sy2;


    // =========================================================
    // VETOR DO VÉRTICE ATÉ O PIXEL
    // =========================================================

    wire signed [10:0] px0;
    wire signed [9:0]  py0;

    wire signed [10:0] px1;
    wire signed [9:0]  py1;

    wire signed [10:0] px2;
    wire signed [9:0]  py2;


    assign px0 = sx - sx0;
    assign py0 = sy - sy0;

    assign px1 = sx - sx1;
    assign py1 = sy - sy1;

    assign px2 = sx - sx2;
    assign py2 = sy - sy2;


    // =========================================================
    // EDGE FUNCTIONS
    //
    // edge = dx * py - dy * px
    //
    // Tudo utilizando aritmética inteira.
    // =========================================================

    wire signed [21:0] edge0;
    wire signed [21:0] edge1;
    wire signed [21:0] edge2;


    assign edge0 =
        (dx01 * py0) -
        (dy01 * px0);


    assign edge1 =
        (dx12 * py1) -
        (dy12 * px1);


    assign edge2 =
        (dx20 * py2) -
        (dy20 * px2);


    // =========================================================
    // TESTE DOS SINAIS
    //
    // Se todos forem >= 0
    // OU
    // todos forem <= 0
    //
    // o pixel está dentro do triângulo.
    //
    // Dessa forma funciona independentemente da ordem
    // horária/anti-horária dos vértices.
    // =========================================================

    wire all_positive;
    wire all_negative;


    assign all_positive =

        (edge0 >= 0) &&
        (edge1 >= 0) &&
        (edge2 >= 0);


    assign all_negative =

        (edge0 <= 0) &&
        (edge1 <= 0) &&
        (edge2 <= 0);


    wire inside_triangle;


    assign inside_triangle =
        all_positive || all_negative;


    // =========================================================
    // DETECÇÃO DE TRIÂNGULO DEGENERADO
    //
    // Evita considerar uma linha/ponto como triângulo válido.
    // Calculamos a área orientada:
    //
    // (x1-x0)*(y2-y0) - (y1-y0)*(x2-x0)
    // =========================================================

    wire signed [10:0] area_dx1;
    wire signed [9:0]  area_dy1;

    wire signed [10:0] area_dx2;
    wire signed [9:0]  area_dy2;

    wire signed [21:0] triangle_area;


    assign area_dx1 = sx1 - sx0;
    assign area_dy1 = sy1 - sy0;

    assign area_dx2 = sx2 - sx0;
    assign area_dy2 = sy2 - sy0;


    assign triangle_area =

        (area_dx1 * area_dy2) -
        (area_dy1 * area_dx2);


    wire triangle_valid;


    assign triangle_valid =
        (triangle_area != 0);


    // =========================================================
    // RESULTADO
    // =========================================================

    assign pixel_valid =

        enable &&
        triangle_valid &&
        inside_triangle &&
        (color != 8'd0);


    assign pixel_color =
        pixel_valid ? color : 8'd0;


    assign pixel_priority =
        pixel_valid ? priority : 2'd0;


endmodule