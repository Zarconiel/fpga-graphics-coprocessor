module command_decoder (

    input wire clk,
    input wire reset,

    input wire        command_valid,
    input wire [31:0] command_data,

    output wire command_ready,


    // =========================================================
    // REGISTRADORES
    // =========================================================

    output reg         reg_write_enable,
    output reg [7:0]   reg_write_address,
    output reg [19:0]  reg_write_data,


    // =========================================================
    // TILEMAP
    // =========================================================

    output reg         tilemap_write_enable,
    output reg [10:0]  tilemap_write_address,
    output reg [7:0]   tilemap_write_data,


    // =========================================================
    // TILE
    // =========================================================

    output reg         tile_write_enable,
    output reg [13:0]  tile_write_address,
    output reg [7:0]   tile_write_data,


    // =========================================================
    // SPRITE
    // =========================================================

    output reg         sprite_write_enable,
    output reg [4:0]   sprite_index,
    output reg [3:0]   sprite_field,
    output reg [18:0]  sprite_data,


    output reg invalid_command

);


    // =========================================================
    // OPCODES
    // =========================================================

    localparam CMD_NOP       = 4'h0;
    localparam CMD_WRITE_REG = 4'h1;

    localparam CMD_TILEMAP   = 4'h2;
    localparam CMD_TILE      = 4'h3;

    localparam CMD_SPRITE    = 4'h5;


    assign command_ready = 1'b1;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            reg_write_enable <= 1'b0;

            reg_write_address <= 8'd0;
            reg_write_data    <= 20'd0;


            tilemap_write_enable <= 1'b0;
            tilemap_write_address <= 11'd0;
            tilemap_write_data <= 8'd0;


            tile_write_enable <= 1'b0;
            tile_write_address <= 14'd0;
            tile_write_data <= 8'd0;


            sprite_write_enable <= 1'b0;
            sprite_index <= 5'd0;
            sprite_field <= 4'd0;
            sprite_data  <= 19'd0;


            invalid_command <= 1'b0;

        end

        else begin

            // Todos sao pulsos de um ciclo

            reg_write_enable     <= 1'b0;
            tilemap_write_enable <= 1'b0;
            tile_write_enable    <= 1'b0;
            sprite_write_enable  <= 1'b0;

            invalid_command <= 1'b0;


            if (command_valid) begin

                case (command_data[31:28])


                    // =========================================
                    // NOP
                    // =========================================

                    CMD_NOP: begin

                    end


                    // =========================================
                    // WRITE REGISTER
                    //
                    // [31:28] opcode
                    // [27:20] endereco
                    // [19:0] dado
                    // =========================================

                    CMD_WRITE_REG: begin

                        reg_write_enable <= 1'b1;

                        reg_write_address <=
                            command_data[27:20];

                        reg_write_data <=
                            command_data[19:0];

                    end


                    // =========================================
                    // WRITE TILEMAP
                    //
                    // [26:16] endereco
                    // [7:0] tile
                    // =========================================

                    CMD_TILEMAP: begin

                        tilemap_write_enable <= 1'b1;

                        tilemap_write_address <=
                            command_data[26:16];

                        tilemap_write_data <=
                            command_data[7:0];

                    end


                    // =========================================
                    // WRITE TILE PIXEL
                    //
                    // [27:14] endereco
                    // [7:0] pixel
                    // =========================================

                    CMD_TILE: begin

                        tile_write_enable <= 1'b1;

                        tile_write_address <=
                            command_data[27:14];

                        tile_write_data <=
                            command_data[7:0];

                    end


                    // =========================================
                    // WRITE SPRITE ATTRIBUTE
                    //
                    // [27:23] sprite
                    // [22:19] campo
                    // [18:0] dado
                    // =========================================

                    CMD_SPRITE: begin

                        sprite_write_enable <= 1'b1;

                        sprite_index <=
                            command_data[27:23];

                        sprite_field <=
                            command_data[22:19];

                        sprite_data <=
                            command_data[18:0];

                    end


                    // =========================================
                    // COMANDO INVALIDO
                    // =========================================

                    default: begin

                        invalid_command <= 1'b1;

                    end

                endcase

            end

        end

    end


endmodule