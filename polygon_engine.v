module polygon_engine (

    // =========================================================
    // PIXEL LÓGICO
    // =========================================================

    input wire [8:0] logical_x,
    input wire [7:0] logical_y,


    // =========================================================
    // RETÂNGULO
    // =========================================================

    input wire       rect_enable,

    input wire [8:0] rect_x0,
    input wire [7:0] rect_y0,

    input wire [8:0] rect_x1,
    input wire [7:0] rect_y1,

    input wire [7:0] rect_color,
    input wire [1:0] rect_priority,


    // =========================================================
    // TRIÂNGULO
    // =========================================================

    input wire       tri_enable,

    input wire [8:0] tri_x0,
    input wire [7:0] tri_y0,

    input wire [8:0] tri_x1,
    input wire [7:0] tri_y1,

    input wire [8:0] tri_x2,
    input wire [7:0] tri_y2,

    input wire [7:0] tri_color,
    input wire [1:0] tri_priority,


    // =========================================================
    // SAÍDA FINAL
    // =========================================================

    output reg       polygon_valid,
    output reg [7:0] polygon_color,
    output reg [1:0] polygon_priority

);


    // =========================================================
    // RETÂNGULO
    // =========================================================

    wire       rectangle_valid;
    wire [7:0] rectangle_color;
    wire [1:0] rectangle_priority;


    rectangle_rasterizer rectangle_inst (

        .pixel_x        (logical_x),
        .pixel_y        (logical_y),

        .x0             (rect_x0),
        .y0             (rect_y0),

        .x1             (rect_x1),
        .y1             (rect_y1),

        .color          (rect_color),
        .priority       (rect_priority),

        .enable         (rect_enable),

        .pixel_valid    (rectangle_valid),
        .pixel_color    (rectangle_color),
        .pixel_priority (rectangle_priority)

    );


    // =========================================================
    // TRIÂNGULO
    // =========================================================

    wire       triangle_pixel_valid;
    wire [7:0] triangle_pixel_color;
    wire [1:0] triangle_pixel_priority;


    triangle_rasterizer triangle_inst (

        .pixel_x        (logical_x),
        .pixel_y        (logical_y),

        .x0             (tri_x0),
        .y0             (tri_y0),

        .x1             (tri_x1),
        .y1             (tri_y1),

        .x2             (tri_x2),
        .y2             (tri_y2),

        .color          (tri_color),
        .priority       (tri_priority),

        .enable         (tri_enable),

        .pixel_valid    (triangle_pixel_valid),
        .pixel_color    (triangle_pixel_color),
        .pixel_priority (triangle_pixel_priority)

    );


    // =========================================================
    // SELEÇÃO ENTRE OS POLÍGONOS
    //
    // Se os dois ocuparem o mesmo pixel:
    //
    // ganha o de maior prioridade.
    //
    // Em caso de empate:
    //
    // triângulo ganha do retângulo.
    //
    // Essa regra precisa ser documentada.
    // =========================================================

    always @(*) begin

        polygon_valid    = 1'b0;
        polygon_color    = 8'd0;
        polygon_priority = 2'd0;


        // -----------------------------------------------------
        // Só retângulo
        // -----------------------------------------------------

        if (rectangle_valid && !triangle_pixel_valid) begin

            polygon_valid    = 1'b1;
            polygon_color    = rectangle_color;
            polygon_priority = rectangle_priority;

        end


        // -----------------------------------------------------
        // Só triângulo
        // -----------------------------------------------------

        else if (!rectangle_valid && triangle_pixel_valid) begin

            polygon_valid    = 1'b1;
            polygon_color    = triangle_pixel_color;
            polygon_priority = triangle_pixel_priority;

        end


        // -----------------------------------------------------
        // Os dois
        // -----------------------------------------------------

        else if (rectangle_valid && triangle_pixel_valid) begin

            polygon_valid = 1'b1;


            // Triângulo ganha em empate
            if (triangle_pixel_priority >= rectangle_priority) begin

                polygon_color =
                    triangle_pixel_color;

                polygon_priority =
                    triangle_pixel_priority;

            end

            else begin

                polygon_color =
                    rectangle_color;

                polygon_priority =
                    rectangle_priority;

            end

        end

    end


endmodule