module simple_ram_tb;

    reg clk;
    reg [3:0] addr;
    reg [7:0] data_in;
    reg we;

    wire [7:0] data_out;

    simple_ram uut (
        .clk(clk),
        .addr(addr),
        .data_in(data_in),
        .we(we),
        .data_out(data_out)
    );

    // Clock de 10 ns
    always #5 clk = ~clk;

    initial begin

        clk = 0;
        addr = 0;
        data_in = 0;
        we = 0;

        // -------------------------
        // Escrever AA no endereço 3
        // -------------------------

        #10;

        addr = 4'd3;
        data_in = 8'hAA;
        we = 1;

        #10;

        we = 0;

        // -------------------------
        // Ler endereço 3
        // -------------------------

        addr = 4'd3;

        #10;

        $display("Endereco 3 = %h", data_out);

        // -------------------------
        // Escrever 55 no endereço 7
        // -------------------------

        addr = 4'd7;
        data_in = 8'h55;
        we = 1;

        #10;

        we = 0;

        // -------------------------
        // Ler endereço 7
        // -------------------------

        addr = 4'd7;

        #10;

        $display("Endereco 7 = %h", data_out);

        #10;

        $finish;

    end

endmodule
