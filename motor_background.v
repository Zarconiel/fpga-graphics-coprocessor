// motor_background.v
// Motor de renderizacao de plano de fundo (background) baseado em tiles de 8x8.
// Gerencia um mapa de 40 colunas x 30 linhas (320x240 pixels logicos).

module motor_background (
    input  wire        clk,             // Clock de pixel de 25 MHz
    input  wire        reset_n,         // Reset ativo em baixo
    input  wire [8:0]  x_logico,        // Coordenada x de desenho (0 a 319)
    input  wire [7:0]  y_logico,        // Coordenada y de desenho (0 a 239)
    input  wire        paridade_x,      // Paridade do contador fisico de pixel (bit 0 de coord_x_vga):
                                         // 0 = 1o ciclo fisico do pixel logico atual, 1 = 2o ciclo
    input  wire [3:0]  controle_sw,     // Chaves sw[3:0] de controle de movimento
    output reg  [7:0]  indice_cor       // Indice de cor de 8 bits para o compositor
);

    // Registradores para deslocamento (scrolling)
    reg [8:0] scroll_h;                 // Deslocamento horizontal (0 a 319)
    reg [7:0] scroll_v;                 // Deslocamento vertical (0 a 239)

    // Divisor de clock para velocidade da rolagem (aprox. 60 Hz para suavidade)
    reg [19:0] contador_velocidade;
    wire pulso_rolagem = (contador_velocidade == 20'd400_000); // 25MHz / 400k = ~62.5 Hz

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            contador_velocidade <= 20'd0;
        end else begin
            if (contador_velocidade >= 20'd400_000)
                contador_velocidade <= 20'd0;
            else
                contador_velocidade <= contador_velocidade + 20'd1;
        end
    end

    // Atualizacao dos registradores de scroll baseado nas chaves deslizantes (Tile-by-Tile)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            scroll_h <= 9'd0;
            scroll_v <= 8'd0;
        end else if (pulso_rolagem) begin
            // Controle horizontal: sw[3] = esquerda, sw[0] = direita
            if (controle_sw[3]) begin
                if (scroll_h < 9'd8) 
                    scroll_h <= 9'd312; // Wrap para o ultimo bloco de tiles horizontal (320 - 8)
                else 
                    scroll_h <= scroll_h - 9'd8; // Salto de 1 tile (8 pixels)
            end else if (controle_sw[0]) begin
                if (scroll_h >= 9'd312) 
                    scroll_h <= 9'd0;
                else 
                    scroll_h <= scroll_h + 9'd8; // Salto de 1 tile (8 pixels)
            end

            // Controle vertical: sw[1] = cima, sw[2] = baixo
            if (controle_sw[1]) begin
                if (scroll_v < 8'd8) 
                    scroll_v <= 8'd232; // Wrap para o ultimo bloco de tiles vertical (240 - 8)
                else 
                    scroll_v <= scroll_v - 8'd8; // Salto de 1 tile (8 pixels)
            end else if (controle_sw[2]) begin
                if (scroll_v >= 8'd232) 
                    scroll_v <= 8'd0;
                else 
                    scroll_v <= scroll_v + 8'd8; // Salto de 1 tile (8 pixels)
            end
        end
    end

   // Compensacao de latencia do pipeline de memoria (3 ciclos fisicos de
   // 25 MHz, ver bloco de sincronizacao mais abaixo).
   wire [1:0] avanco_logico = paridade_x ? 2'd2 : 2'd1;
   wire [8:0] x_somado = x_logico + {7'd0, avanco_logico};
   wire wrap_linha = (x_somado >= 9'd320);
   wire [8:0] x_logico_adiantado = wrap_linha ? (x_somado - 9'd320) : x_somado;
   wire [7:0] y_logico_adiantado = wrap_linha ?
                                        ((y_logico == 8'd239) ? 8'd0 : y_logico + 8'd1) :
                                        y_logico;

   // Calculo da coordenada absoluta com wrapping
   wire [8:0] abs_x = (x_logico_adiantado + scroll_h >= 9'd320) ? (x_logico_adiantado + scroll_h - 9'd320) : (x_logico_adiantado + scroll_h);
   wire [7:0] abs_y = (y_logico_adiantado + scroll_v >= 8'd240) ? (y_logico_adiantado + scroll_v - 8'd240) : (y_logico_adiantado + scroll_v);

   // Mapeamento para obter o ID da coluna (0 a 39) e ID da linha (0 a 29) no tilemap
   wire [5:0] col_tile = abs_x[8:3];   // Divisao inteira por 8
   wire [4:0] row_tile = abs_y[7:3];   // Divisao inteira por 8

   // Otimizacao de multiplicacao row_tile * 40 sem blocos DSP:
   // row_tile * 40 = (row_tile * 32) + (row_tile * 8)
   wire [10:0] offset_linha = ({6'd0, row_tile} << 5) + ({6'd0, row_tile} << 3);
   wire [10:0] tile_addr = offset_linha + {5'd0, col_tile}; // Endereco na RAM de 1200 posicoes

   // Coordenadas locais pixel-a-pixel dentro do tile de 8x8 (0 a 7)
   wire [2:0] pixel_x = abs_x[2:0];
   wire [2:0] pixel_y = abs_y[2:0];


   // PIPELINE DE SINCRONIZACAO DE MEMORIA (2 CICLOS DE LATENCIA TOTAL)
    
   // Ciclo 1: Registramos pixel_x e pixel_y locais para casar com a saida da RAM
   reg [2:0] pixel_x_delayed;
   reg [2:0] pixel_y_delayed;

   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         pixel_x_delayed <= 3'd0;
         pixel_y_delayed <= 3'd0;
      end else begin
         pixel_x_delayed <= pixel_x;
         pixel_y_delayed <= pixel_y;
      end
   end

   // Instanciacao da memoria RAM de layout de tiles (1200 posicoes, 8 bits)
   // Latencia de leitura síncrona: 1 ciclo de clock
   wire [7:0] tile_id_lido;
   tilemap_ram map_ram (
      .address (tile_addr),
      .clock   (clk),
      .data    (8'd0),        // Entrada de dados para escrita (desativada no motor)
      .rden    (1'b1),        // Sinalizador de leitura ativo
      .wren    (1'b0),        // Escrita desativada para renderizacao comum
      .q       (tile_id_lido) // ID do padrao de tile retornado síncronamente no ciclo seguinte
   );

   // Ciclo 2: O ID lido e as coordenadas de pixel locais atrasadas sao concatenados
   // para formar o endereco de 14 bits para a ROM de texturas.
   // Endereco: {ID_do_Tile[7:0], linha_local[2:0], coluna_local[2:0]}
   wire [13:0] pattern_rom_addr = {tile_id_lido, pixel_y_delayed, pixel_x_delayed};

   // Instanciacao da memoria ROM de padroes graficos (16384 posicoes, 8 bits)
   // Latencia de leitura síncrona: 1 ciclo de clock
   wire [7:0] cor_do_tile_lida;
   tile_pattern_rom pattern_rom (
      .address (pattern_rom_addr),
      .clock   (clk),
      .rden    (1'b1),            // Leitura permanentemente ativa
      .q       (cor_do_tile_lida) // Indice de cor retornado síncronamente no ciclo seguinte
   );

   // Ajuste final de registro da cor lida para sincronia com o pipeline de video
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
         indice_cor <= 8'd0;
      end else begin
         indice_cor <= cor_do_tile_lida;
      end
   end

endmodule