module background_engine (

    input  wire        clk,

    // =========================================================
    // COORDENADAS LÓGICAS
    //
    // 320 x 240
    // =========================================================

    input  wire [8:0]  logical_x,
    input  wire [7:0]  logical_y,


    // =========================================================
    // SCROLL
    //
    // scroll_x esperado: 0 - 319
    // scroll_y esperado: 0 - 239
    //
    // Futuramente virão dos registradores da GPU.
    // =========================================================

    input  wire [8:0]  scroll_x,
    input  wire [7:0]  scroll_y,


    // =========================================================
    // ESCRITA DO TILEMAP
    //
    // Futuramente command_decoder -> aqui
    // =========================================================

    input  wire        tilemap_write_enable,
    input  wire [10:0] tilemap_write_address,
    input  wire [7:0]  tilemap_write_data,


    // =========================================================
    // ESCRITA DA MEMÓRIA DE TILES
    // =========================================================

    input  wire        tile_write_enable,
    input  wire [13:0] tile_write_address,
    input  wire [7:0]  tile_write_data,


    // =========================================================
    // SAÍDA
    //
    // Índice de cor do background
    // =========================================================

    output wire [7:0]  background_color

);


    // =========================================================
    // APLICAÇÃO DO SCROLL
    //
    // A resolução lógica possui:
    //
    // largura  = 320
    // altura   = 240
    //
    // Estamos utilizando repetição (wrap).
    // =========================================================

    wire [9:0] x_sum;
    wire [8:0] y_sum;

    reg  [8:0] scrolled_x;
    reg  [7:0] scrolled_y;


    assign x_sum = logical_x + scroll_x;
    assign y_sum = logical_y + scroll_y;


    always @(*) begin

        // -----------------------------------------------------
        // Horizontal wrap
        // -----------------------------------------------------

        if (x_sum >= 10'd320)
            scrolled_x = x_sum - 10'd320;
        else
            scrolled_x = x_sum[8:0];


        // -----------------------------------------------------
        // Vertical wrap
        // -----------------------------------------------------

        if (y_sum >= 9'd240)
            scrolled_y = y_sum - 9'd240;
        else
            scrolled_y = y_sum[7:0];

    end


    // =========================================================
    // DESCOBRIR QUAL TILE ESTAMOS ACESSANDO
    //
    // Como cada tile possui 8 pixels:
    //
    // tile_x = pixel_x / 8
    // tile_y = pixel_y / 8
    //
    // Como 8 = 2^3, basta remover os 3 bits inferiores.
    // =========================================================

    wire [5:0] tile_x;
    wire [4:0] tile_y;


    assign tile_x = scrolled_x >> 3;

    assign tile_y = scrolled_y >> 3;


    // =========================================================
    // POSIÇÃO DO PIXEL DENTRO DO TILE
    //
    // equivalente a:
    //
    // pixel_x = x % 8
    // pixel_y = y % 8
    //
    // Os 3 bits inferiores já representam isso.
    // =========================================================

    wire [2:0] pixel_in_tile_x;
    wire [2:0] pixel_in_tile_y;


    assign pixel_in_tile_x = scrolled_x[2:0];

    assign pixel_in_tile_y = scrolled_y[2:0];


    // =========================================================
    // ENDEREÇO DO TILEMAP
    //
    // endereço =
    //
    // tile_y * 40 + tile_x
    //
    // Evitamos multiplicação genérica:
    //
    // 40 = 32 + 8
    //
    // portanto:
    //
    // tile_y * 40 =
    // tile_y * 32 + tile_y * 8
    // =========================================================

    wire [10:0] tilemap_read_address;


    assign tilemap_read_address =
        (tile_y << 5)
        +
        (tile_y << 3)
        +
        tile_x;


    // =========================================================
    // TILEMAP
    // =========================================================

    wire [7:0] selected_tile;


    tilemap_ram tilemap_inst (

        .clk           (clk),

        .read_address  (tilemap_read_address),

        .tile_index    (selected_tile),

        .write_enable  (tilemap_write_enable),

        .write_address (tilemap_write_address),

        .write_data    (tilemap_write_data)

    );


    // =========================================================
    // ENDEREÇO DO PIXEL NA TILE MEMORY
    //
    // Cada tile tem 64 pixels.
    //
    // endereço =
    //
    // tile * 64
    // +
    // pixel_y * 8
    // +
    // pixel_x
    //
    //
    // Como temos:
    //
    // tile       = 8 bits
    // pixel_y    = 3 bits
    // pixel_x    = 3 bits
    //
    // podemos simplesmente concatenar:
    //
    // {tile, pixel_y, pixel_x}
    //
    // 8 + 3 + 3 = 14 bits
    // =========================================================

    wire [13:0] tile_read_address;


    assign tile_read_address = {
        selected_tile,
        pixel_in_tile_y,
        pixel_in_tile_x
    };


    // =========================================================
    // MEMÓRIA DOS PADRÕES
    // =========================================================

    tile_memory tile_memory_inst (

        .clk           (clk),

        .read_address  (tile_read_address),

        .pixel_data    (background_color),

        .write_enable  (tile_write_enable),

        .write_address (tile_write_address),

        .write_data    (tile_write_data)

    );


endmodule