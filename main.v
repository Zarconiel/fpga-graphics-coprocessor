// ============================================================================
// Copyright (c) 2013 by Terasic Technologies Inc.
// ============================================================================
//
// Adaptado para o PBL01 - Núcleo gráfico
//
// ============================================================================


// ============================================================
// PERIFÉRICOS HABILITADOS NESTA ETAPA
// ============================================================

`define ENABLE_CLOCK
`define ENABLE_KEY
`define ENABLE_LEDR
`define ENABLE_VGA


module main(

      /* CLOCK */
    `ifdef ENABLE_CLOCK
      input              CLOCK_50,
    `endif


      /* KEY */
    `ifdef ENABLE_KEY
      input       [3:0]  KEY,
    `endif


      /* LEDR */
    `ifdef ENABLE_LEDR
      output      [9:0]  LEDR,
    `endif


      /* VGA */
    `ifdef ENABLE_VGA
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS
    `endif

);


// ============================================================
// REG / WIRE DECLARATIONS
// ============================================================


// ------------------------------------------------------------
// Reset
//
// KEY[0] é ativo em nível baixo.
// Internamente usamos reset ativo em nível alto.
// ------------------------------------------------------------

wire gpu_reset;


// ------------------------------------------------------------
// Clock de pixel VGA
//
// CLOCK_50 = 50 MHz
// pixel_clk = 25 MHz
// ------------------------------------------------------------

reg pixel_clk;


// ------------------------------------------------------------
// Interface temporária de comandos
//
// Futuramente será:
//
// ARM
//  ↓
// MMIO
//  ↓
// GPU
//
// Neste momento usamos este gerador para testar.
// ------------------------------------------------------------

reg  [31:0] command_data;
reg         command_valid;

wire        command_ready;


// ------------------------------------------------------------
// Estado do gerador temporário de comandos
// ------------------------------------------------------------

reg [2:0] command_state;


// ============================================================
// STRUCTURAL CODING
// ============================================================


// ============================================================
// RESET
// ============================================================

assign gpu_reset = ~KEY[0];


// ============================================================
// CLOCK VGA 25 MHz
//
// Divide CLOCK_50 por 2.
// ============================================================

always @(posedge CLOCK_50 or posedge gpu_reset) begin

    if (gpu_reset)
        pixel_clk <= 1'b0;

    else
        pixel_clk <= ~pixel_clk;

end


assign VGA_CLK = pixel_clk;


// ============================================================
// GERADOR TEMPORÁRIO DE COMANDOS
//
// Formato definido:
// 
// [31:28] = OPCODE
// [27:20] = endereço do registrador
// [19:0]  = dado
//
// OPCODE:
// 0x1 = WRITE_REGISTER
//
// Registradores:
// 0x01 = SCROLL_X
// 0x02 = SCROLL_Y
//
// Comandos enviados:
//
// SCROLL_X = 40
// SCROLL_Y = 24
//
// ============================================================

always @(posedge CLOCK_50 or posedge gpu_reset) begin

    if (gpu_reset) begin

        command_state <= 3'd0;

        command_valid <= 1'b0;

        command_data <= 32'd0;

    end

    else begin

        // ----------------------------------------------------
        // Por padrão command_valid fica desligado.
        //
        // Ele será ligado apenas durante o envio de um comando.
        // ----------------------------------------------------

        command_valid <= 1'b0;


        case (command_state)


            // =================================================
            // ESTADO 0
            //
            // Pequena espera após reset.
            // =================================================

            3'd0: begin

                command_state <= 3'd1;

            end


            // =================================================
            // ESTADO 1
            //
            // WRITE_REGISTER
            //
            // SCROLL_X = 40
            //
            // opcode:
            // 1
            //
            // endereço:
            // 01
            //
            // dado:
            // 40 decimal = 0x28
            //
            // Palavra:
            //
            // 0x10100028
            // =================================================

            3'd1: begin

                if (command_ready) begin

                    command_data <= 32'h10100028;

                    command_valid <= 1'b1;

                    command_state <= 3'd2;

                end

            end


            // =================================================
            // ESTADO 2
            //
            // Espera um ciclo entre os comandos.
            // =================================================

            3'd2: begin

                command_state <= 3'd3;

            end


            // =================================================
            // ESTADO 3
            //
            // WRITE_REGISTER
            //
            // SCROLL_Y = 24
            //
            // opcode:
            // 1
            //
            // endereço:
            // 02
            //
            // dado:
            // 24 decimal = 0x18
            //
            // Palavra:
            //
            // 0x10200018
            // =================================================

            3'd3: begin

                if (command_ready) begin

                    command_data <= 32'h10200018;

                    command_valid <= 1'b1;

                    command_state <= 3'd4;

                end

            end


            // =================================================
            // ESTADO 4
            //
            // Todos os comandos foram enviados.
            // =================================================

            3'd4: begin

                command_valid <= 1'b0;

            end


            // =================================================
            // SEGURANÇA
            // =================================================

            default: begin

                command_state <= 3'd0;

            end

        endcase

    end

end


// ============================================================
// GPU CORE
// ============================================================

gpu_core gpu_inst (

    // --------------------------------------------------------
    // Clocks
    // --------------------------------------------------------

    .clk           (CLOCK_50),

    .pixel_clk     (pixel_clk),


    // --------------------------------------------------------
    // Reset
    // --------------------------------------------------------

    .reset         (gpu_reset),


    // --------------------------------------------------------
    // Interface de comandos
    // --------------------------------------------------------

    .command_valid (command_valid),

    .command_data  (command_data),

    .command_ready (command_ready),


    // --------------------------------------------------------
    // VGA
    // --------------------------------------------------------

    .vga_r         (VGA_R),

    .vga_g         (VGA_G),

    .vga_b         (VGA_B),

    .vga_hs        (VGA_HS),

    .vga_vs        (VGA_VS),

    .vga_blank_n   (VGA_BLANK_N)

);


// ============================================================
// VGA SYNC
//
// Composite Sync não utilizado.
// ============================================================

assign VGA_SYNC_N = 1'b0;


// ============================================================
// LEDs DE DEBUG
//
// LEDR[0] = reset
// LEDR[1] = command_valid
// LEDR[2] = command_ready
//
// Isso ajuda a verificar o funcionamento na placa.
// ============================================================

assign LEDR[0] = gpu_reset;

assign LEDR[1] = command_valid;

assign LEDR[2] = command_ready;

assign LEDR[9:3] = 7'b0000000;


endmodule