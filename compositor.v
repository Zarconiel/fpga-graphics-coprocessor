module compositor (

    // Background
    input wire [7:0] background_color,

    // Poligonos
    input wire       polygon_valid,
    input wire [7:0] polygon_color,
    input wire [1:0] polygon_priority,

    // Sprites
    input wire       sprite_valid,
    input wire [7:0] sprite_color,
    input wire [1:0] sprite_priority,

    // Resultado final
    output reg [7:0] final_color

);


    always @(*) begin

        // Background e a camada base
        final_color = background_color;


        // =====================================================
        // POLIGONO
        //
        // Cor zero = transparente
        // =====================================================

        if (
            polygon_valid &&
            (polygon_color != 8'd0)
        ) begin

            final_color = polygon_color;

        end


        // =====================================================
        // SPRITE
        //
        // Sprite substitui o poligono quando:
        //
        // nao existe poligono
        //
        // OU
        //
        // prioridade sprite >= prioridade poligono
        // =====================================================

        if (
            sprite_valid &&
            (sprite_color != 8'd0)
        ) begin

            if (
                (!polygon_valid) ||
                (sprite_priority >= polygon_priority)
            ) begin

                final_color = sprite_color;

            end

        end

    end


endmodule