module palette_ram (

    input  wire        clk,

    // Escrita futura da paleta
    input  wire        write_enable,
    input  wire [7:0]  write_address,
    input  wire [23:0] write_data,

    // Índice de cor usado pela GPU
    input  wire [7:0]  color_index,

    // Saída RGB
    output wire [7:0]  red,
    output wire [7:0]  green,
    output wire [7:0]  blue
);

    // =========================================================
    // PALETA
    //
    // 256 posições
    // Cada posição possui 24 bits:
    //
    // [23:16] = vermelho
    // [15:8]  = verde
    // [7:0]   = azul
    // =========================================================

    reg [23:0] palette [0:255];

    integer i;


    // =========================================================
    // INICIALIZAÇÃO
    //
    // Apenas para o primeiro teste da GPU.
    // Futuramente a paleta poderá ser alterada pelos comandos
    // enviados através da interface MMIO.
    // =========================================================

    initial begin

        // Inicializa toda a memória como preta
        for (i = 0; i < 256; i = i + 1)
            palette[i] = 24'h000000;


        // Algumas cores para teste

        palette[0] = 24'h000000; // preto

        palette[1] = 24'hFFFFFF; // branco

        palette[2] = 24'hFF0000; // vermelho

        palette[3] = 24'h00FF00; // verde

        palette[4] = 24'h0000FF; // azul

        palette[5] = 24'hFFFF00; // amarelo

        palette[6] = 24'h00FFFF; // ciano

        palette[7] = 24'hFF00FF; // magenta

        palette[8] = 24'h808080; // cinza

        palette[9] = 24'hFF8000; // laranja

    end


    // =========================================================
    // ESCRITA DA PALETA
    //
    // Ainda não será utilizada nesta primeira etapa.
    // Depois virá do command_decoder.
    // =========================================================

    always @(posedge clk) begin

        if (write_enable)
            palette[write_address] <= write_data;

    end


    // =========================================================
    // LEITURA DA PALETA
    // =========================================================

    assign red   = palette[color_index][23:16];

    assign green = palette[color_index][15:8];

    assign blue  = palette[color_index][7:0];


endmodule
