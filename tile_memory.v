module tile_memory (

    input  wire        clk,

    // =========================================================
    // LEITURA
    // =========================================================

    input  wire [13:0] read_address,
    output wire [7:0]  pixel_data,

    // =========================================================
    // ESCRITA
    // Futuramente será usada pelo command_decoder / MMIO
    // =========================================================

    input  wire        write_enable,
    input  wire [13:0] write_address,
    input  wire [7:0]  write_data

);


    // =========================================================
    // MEMÓRIA DE TILES
    //
    // 256 tiles
    // 8 x 8 pixels por tile
    //
    // 256 * 64 = 16384 pixels
    //
    // Cada pixel guarda um índice de cor de 8 bits.
    // =========================================================

    reg [7:0] memory [0:16383];


    integer tile;
    integer x;
    integer y;


    // =========================================================
    // INICIALIZAÇÃO
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // Inicializa os 256 tiles.
        //
        // Evitamos um único loop de 16384 iterações,
        // pois algumas versões do Quartus limitam loops
        // de síntese a 5000 iterações.
        // -----------------------------------------------------

        for (tile = 0; tile < 256; tile = tile + 1) begin

            for (y = 0; y < 8; y = y + 1) begin

                for (x = 0; x < 8; x = x + 1) begin

                    // Por padrão, branco
                    memory[(tile * 64) + (y * 8) + x] = 8'd1;

                end

            end

        end


        // =====================================================
        // TILE 0 - VERMELHO
        // =====================================================

        for (y = 0; y < 8; y = y + 1) begin

            for (x = 0; x < 8; x = x + 1) begin

                memory[(0 * 64) + (y * 8) + x] = 8'd2;

            end

        end


        // =====================================================
        // TILE 1 - VERDE
        // =====================================================

        for (y = 0; y < 8; y = y + 1) begin

            for (x = 0; x < 8; x = x + 1) begin

                memory[(1 * 64) + (y * 8) + x] = 8'd3;

            end

        end


        // =====================================================
        // TILE 2 - AZUL
        // =====================================================

        for (y = 0; y < 8; y = y + 1) begin

            for (x = 0; x < 8; x = x + 1) begin

                memory[(2 * 64) + (y * 8) + x] = 8'd4;

            end

        end


        // =====================================================
        // TILE 3 - AMARELO
        // =====================================================

        for (y = 0; y < 8; y = y + 1) begin

            for (x = 0; x < 8; x = x + 1) begin

                memory[(3 * 64) + (y * 8) + x] = 8'd5;

            end

        end


        // =====================================================
        // TILE 4 - QUADRICULADO VERMELHO / BRANCO
        // =====================================================

        for (y = 0; y < 8; y = y + 1) begin

            for (x = 0; x < 8; x = x + 1) begin

                if ((x + y) % 2 == 0)

                    memory[(4 * 64) + (y * 8) + x] = 8'd2;

                else

                    memory[(4 * 64) + (y * 8) + x] = 8'd1;

            end

        end


        // =====================================================
        // TILE 5 - QUADRICULADO AZUL / CIANO
        // =====================================================

        for (y = 0; y < 8; y = y + 1) begin

            for (x = 0; x < 8; x = x + 1) begin

                if ((x + y) % 2 == 0)

                    memory[(5 * 64) + (y * 8) + x] = 8'd4;

                else

                    memory[(5 * 64) + (y * 8) + x] = 8'd6;

            end

        end

    end


    // =========================================================
    // ESCRITA
    // =========================================================

    always @(posedge clk) begin

        if (write_enable)
            memory[write_address] <= write_data;

    end


    // =========================================================
    // LEITURA
    // =========================================================

    assign pixel_data = memory[read_address];


endmodule