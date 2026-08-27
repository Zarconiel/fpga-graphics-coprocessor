module simple_ram (
    input wire clk,
    input wire [3:0] addr,   // Endereço de 4 bits (16 locations)
    input wire [7:0] data_in, // Dados de entrada de 8 bits
    input wire we,            // Write Enable
    output reg [7:0] data_out // Dados de saída
);

    // Declaração da memória: 16 posições, 8 bits cada
    reg [7:0] mem [0:15];

    // Processo de escrita e leitura
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in; // Escreve no endereço especificado
        end
        data_out <= mem[addr];    // Lê do endereço especificado (sincronizado)
    end

endmodule   
