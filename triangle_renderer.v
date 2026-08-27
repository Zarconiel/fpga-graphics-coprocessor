module triangle_renderer (
    input wire [9:0] pixel_x,
    input wire [8:0] pixel_y,

    output wire pixel
);

    // Vértice 0
    parameter X0 = 160;
    parameter Y0 = 30;

    // Vértice 1
    parameter X1 = 60;
    parameter Y1 = 200;

    // Vértice 2
    parameter X2 = 260;
    parameter Y2 = 200;

    integer e0;
    integer e1;
    integer e2;

    always @(*) begin

        // Aresta 0 -> 1
        e0 = (pixel_x - X0) * (Y1 - Y0)
           - (pixel_y - Y0) * (X1 - X0);

        // Aresta 1 -> 2
        e1 = (pixel_x - X1) * (Y2 - Y1)
           - (pixel_y - Y1) * (X2 - X1);

        // Aresta 2 -> 0
        e2 = (pixel_x - X2) * (Y0 - Y2)
           - (pixel_y - Y2) * (X0 - X2);

    end

    assign pixel =
        ((e0 >= 0) && (e1 >= 0) && (e2 >= 0)) ||
        ((e0 <= 0) && (e1 <= 0) && (e2 <= 0));

endmodule