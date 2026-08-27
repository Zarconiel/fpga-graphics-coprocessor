module tilemap_ram (

    input  wire        clk,

    // =========================================================
    // LEITURA
    // =========================================================

    input  wire [10:0] read_address,
    output wire [7:0]  tile_index,


    // =========================================================
    // ESCRITA
    //
    // Futuramente será controlada pelos comandos da GPU.
    // =========================================================

    input  wire        write_enable,
    input  wire [10:0] write_address,
    input  wire [7:0]  write_data

);


    // =========================================================
    // TILEMAP
    //
    // 40 colunas
    // 30 linhas
    //
    // 40 * 30 = 1200 entradas
    //
    // Cada entrada contém o índice de um tile.
    // =========================================================

    reg [7:0] tilemap [0:1199];


    integer x;
    integer y;
    integer address;


    // =========================================================
    // MAPA INICIAL PARA TESTE
    //
    // Estamos criando apenas um cenário de diagnóstico.
    //
    // O hardware NÃO depende desse mapa.
    //
    // Posteriormente cada posição poderá ser alterada pelo
    // processador/comandos.
    // =========================================================

    initial begin

        // Inicializa tudo primeiro.
        for (address = 0; address < 1200; address = address + 1)
            tilemap[address] = 8'd0;


        // -----------------------------------------------------
        // Criamos um padrão variado para enxergar os tiles.
        // -----------------------------------------------------

        for (y = 0; y < 30; y = y + 1) begin

            for (x = 0; x < 40; x = x + 1) begin

                // Cada grupo muda o tile utilizado.

                if ((x + y) % 6 == 0)

                    tilemap[(y * 40) + x] = 8'd0;


                else if ((x + y) % 6 == 1)

                    tilemap[(y * 40) + x] = 8'd1;


                else if ((x + y) % 6 == 2)

                    tilemap[(y * 40) + x] = 8'd2;


                else if ((x + y) % 6 == 3)

                    tilemap[(y * 40) + x] = 8'd3;


                else if ((x + y) % 6 == 4)

                    tilemap[(y * 40) + x] = 8'd4;


                else

                    tilemap[(y * 40) + x] = 8'd5;

            end

        end

    end


    // =========================================================
    // ESCRITA
    // =========================================================

    always @(posedge clk) begin

        if (write_enable)
            tilemap[write_address] <= write_data;

    end


    // =========================================================
    // LEITURA
    // =========================================================

    assign tile_index = tilemap[read_address];


endmodule
