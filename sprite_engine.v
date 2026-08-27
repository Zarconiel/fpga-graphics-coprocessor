module sprite_engine (

    input wire clk,
    input wire reset,

    // Pixel logico atual
    input wire [8:0] logical_x,
    input wire [7:0] logical_y,

    // Escrita dos atributos dos sprites
    input wire        sprite_write_enable,
    input wire [4:0]  sprite_index,
    input wire [3:0]  sprite_field,
    input wire [18:0] sprite_data,

    // Escrita da memoria grafica
    input wire        tile_write_enable,
    input wire [13:0] tile_write_address,
    input wire [7:0]  tile_write_data,

    // Resultado
    output reg       sprite_valid,
    output reg [7:0] sprite_color,
    output reg [1:0] sprite_priority

);


    // =========================================================
    // CAMPOS DOS SPRITES
    // =========================================================

    localparam FIELD_X        = 4'h0;
    localparam FIELD_Y        = 4'h1;
    localparam FIELD_TILE     = 4'h2;
    localparam FIELD_ENABLE   = 4'h3;
    localparam FIELD_PRIORITY = 4'h4;
    localparam FIELD_HFLIP    = 4'h5;
    localparam FIELD_VFLIP    = 4'h6;
    localparam FIELD_PALETTE  = 4'h7;


    // =========================================================
    // MEMORIA DE ATRIBUTOS
    //
    // 32 sprites
    // =========================================================

    reg [8:0] sprite_x [0:31];
    reg [7:0] sprite_y [0:31];

    reg [7:0] sprite_tile [0:31];

    reg       sprite_enable_mem [0:31];

    reg [1:0] sprite_prio [0:31];

    reg       sprite_hflip [0:31];
    reg       sprite_vflip [0:31];

    reg [3:0] sprite_palette [0:31];


    // =========================================================
    // MEMORIA DE PADROES
    //
    // 256 tiles
    // 8x8 pixels por tile
    //
    // 256 * 64 = 16384 pixels
    // =========================================================

    reg [7:0] pattern_memory [0:16383];


    integer init_tile;
    integer init_x;
    integer init_y;


    // =========================================================
    // INICIALIZACAO DA MEMORIA
    // =========================================================

    initial begin

        // Todos os tiles transparentes inicialmente

        for (init_tile = 0;
             init_tile < 256;
             init_tile = init_tile + 1) begin

            for (init_y = 0;
                 init_y < 8;
                 init_y = init_y + 1) begin

                for (init_x = 0;
                     init_x < 8;
                     init_x = init_x + 1) begin

                    pattern_memory[
                        (init_tile * 64) +
                        (init_y * 8) +
                        init_x
                    ] = 8'd0;

                end

            end

        end


        // =====================================================
        // SPRITE DE TESTE
        //
        // Um sprite 16x16 utiliza quatro tiles:
        //
        // 16   17
        // 18   19
        //
        // =====================================================

        for (init_y = 0;
             init_y < 8;
             init_y = init_y + 1) begin

            for (init_x = 0;
                 init_x < 8;
                 init_x = init_x + 1) begin

                pattern_memory[
                    (16 * 64) +
                    (init_y * 8) +
                    init_x
                ] = 8'h01;


                pattern_memory[
                    (17 * 64) +
                    (init_y * 8) +
                    init_x
                ] = 8'h02;


                pattern_memory[
                    (18 * 64) +
                    (init_y * 8) +
                    init_x
                ] = 8'h03;


                pattern_memory[
                    (19 * 64) +
                    (init_y * 8) +
                    init_x
                ] = 8'h04;

            end

        end

    end


    // =========================================================
    // RESET / ESCRITA DOS ATRIBUTOS
    // =========================================================

    integer reset_index;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            for (
                reset_index = 0;
                reset_index < 32;
                reset_index = reset_index + 1
            ) begin

                sprite_x[reset_index] <= 9'd0;
                sprite_y[reset_index] <= 8'd0;

                sprite_tile[reset_index] <= 8'd0;

                sprite_enable_mem[reset_index] <= 1'b0;

                sprite_prio[reset_index] <= 2'd0;

                sprite_hflip[reset_index] <= 1'b0;
                sprite_vflip[reset_index] <= 1'b0;

                sprite_palette[reset_index] <= 4'd0;

            end


            // =================================================
            // SPRITE 0 DE TESTE
            //
            // Aparece em:
            //
            // X = 130
            // Y = 150
            //
            // tamanho 16x16
            // =================================================

            sprite_x[0] <= 9'd130;
            sprite_y[0] <= 8'd150;

            sprite_tile[0] <= 8'd16;

            sprite_enable_mem[0] <= 1'b1;

            sprite_prio[0] <= 2'd3;

            sprite_hflip[0] <= 1'b0;
            sprite_vflip[0] <= 1'b0;

            sprite_palette[0] <= 4'd0;

        end

        else begin

            // =================================================
            // ALTERACAO DOS ATRIBUTOS
            // =================================================

            if (sprite_write_enable) begin

                case (sprite_field)

                    FIELD_X: begin

                        sprite_x[sprite_index]
                            <= sprite_data[8:0];

                    end


                    FIELD_Y: begin

                        sprite_y[sprite_index]
                            <= sprite_data[7:0];

                    end


                    FIELD_TILE: begin

                        sprite_tile[sprite_index]
                            <= sprite_data[7:0];

                    end


                    FIELD_ENABLE: begin

                        sprite_enable_mem[sprite_index]
                            <= sprite_data[0];

                    end


                    FIELD_PRIORITY: begin

                        sprite_prio[sprite_index]
                            <= sprite_data[1:0];

                    end


                    FIELD_HFLIP: begin

                        sprite_hflip[sprite_index]
                            <= sprite_data[0];

                    end


                    FIELD_VFLIP: begin

                        sprite_vflip[sprite_index]
                            <= sprite_data[0];

                    end


                    FIELD_PALETTE: begin

                        sprite_palette[sprite_index]
                            <= sprite_data[3:0];

                    end


                    default: begin

                    end

                endcase

            end


            // =================================================
            // ALTERACAO DA MEMORIA GRAFICA
            // =================================================

            if (tile_write_enable) begin

                pattern_memory[tile_write_address]
                    <= tile_write_data;

            end

        end

    end


    // =========================================================
    // PRIMEIRA ETAPA
    //
    // Encontrar qual sprite ocupa o pixel atual.
    //
    // Aqui NAO acessamos pattern_memory 32 vezes.
    //
    // Apenas comparamos:
    //
    // X
    // Y
    // enable
    // prioridade
    // =========================================================

    integer scan_index;


    reg       selected_valid;
    reg [4:0] selected_sprite;

    reg [1:0] selected_priority;


    always @(*) begin

        selected_valid    = 1'b0;
        selected_sprite   = 5'd0;
        selected_priority = 2'd0;


        for (
            scan_index = 0;
            scan_index < 32;
            scan_index = scan_index + 1
        ) begin

            if (
                sprite_enable_mem[scan_index] &&

                (logical_x >= sprite_x[scan_index]) &&
                (logical_x <
                    sprite_x[scan_index] + 9'd16) &&

                (logical_y >= sprite_y[scan_index]) &&
                (logical_y <
                    sprite_y[scan_index] + 8'd16)
            ) begin


                // Primeiro sprite encontrado

                if (!selected_valid) begin

                    selected_valid =
                        1'b1;

                    selected_sprite =
                        scan_index;

                    selected_priority =
                        sprite_prio[scan_index];

                end


                // Sprite de maior prioridade vence
                //
                // Empate:
                // maior indice vence.

                else if (
                    sprite_prio[scan_index] >=
                    selected_priority
                ) begin

                    selected_sprite =
                        scan_index;

                    selected_priority =
                        sprite_prio[scan_index];

                end

            end

        end

    end


    // =========================================================
    // COORDENADA LOCAL DO SPRITE SELECIONADO
    // =========================================================

    reg [4:0] local_x;
    reg [4:0] local_y;

    reg [4:0] real_x;
    reg [4:0] real_y;


    always @(*) begin

        local_x = 5'd0;
        local_y = 5'd0;

        real_x = 5'd0;
        real_y = 5'd0;


        if (selected_valid) begin

            local_x =
                logical_x -
                sprite_x[selected_sprite];


            local_y =
                logical_y -
                sprite_y[selected_sprite];


            // =================================================
            // FLIP HORIZONTAL
            // =================================================

            if (sprite_hflip[selected_sprite])
                real_x = 5'd15 - local_x;

            else
                real_x = local_x;


            // =================================================
            // FLIP VERTICAL
            // =================================================

            if (sprite_vflip[selected_sprite])
                real_y = 5'd15 - local_y;

            else
                real_y = local_y;

        end

    end


    // =========================================================
    // ESCOLHA DO TILE
    //
    // Sprite 16x16:
    //
    // base       base+1
    //
    // base+2     base+3
    //
    // =========================================================

    reg [1:0] tile_offset;


    always @(*) begin

        tile_offset = 2'd0;


        if (selected_valid) begin

            if (real_y < 8) begin

                if (real_x < 8)
                    tile_offset = 2'd0;

                else
                    tile_offset = 2'd1;

            end

            else begin

                if (real_x < 8)
                    tile_offset = 2'd2;

                else
                    tile_offset = 2'd3;

            end

        end

    end


    // =========================================================
    // ENDERECO DA MEMORIA
    // =========================================================

    wire [7:0] selected_tile_number;


    assign selected_tile_number =

        sprite_tile[selected_sprite]
        +
        tile_offset;


    wire [13:0] pattern_address;


    assign pattern_address = {

        selected_tile_number,

        real_y[2:0],

        real_x[2:0]

    };


    // =========================================================
    // LEITURA
    //
    // Agora existe somente UM acesso à memoria de padroes
    // para o pixel selecionado.
    // =========================================================

    wire [7:0] selected_texel;


    assign selected_texel =
        pattern_memory[pattern_address];


    // =========================================================
    // SAIDA
    //
    // texel 0 = transparente
    // =========================================================

    always @(*) begin

        sprite_valid    = 1'b0;
        sprite_color    = 8'd0;
        sprite_priority = 2'd0;


        if (
            selected_valid &&
            (selected_texel[3:0] != 4'd0)
        ) begin

            sprite_valid = 1'b1;


            sprite_priority =
                selected_priority;


            sprite_color = {

                sprite_palette[selected_sprite],

                selected_texel[3:0]

            };

        end

    end


endmodule