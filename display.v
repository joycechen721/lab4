module display(
    input clk,
    input reset,
    input [1:0] display_type, // 0 - direction, 1 - score, 2 - says
    input [3:0] first,
    input [3:0] second,
    input [3:0] third, 
    input [3:0] fourth, // 0 - UP, 1 - RIGHT, 2 - DOWN, 3 - LEFT, 4 - SCORE, 5 - SAYS
    output reg [6:0] seg,
    output reg [3:0] an
);
    // For multiplexing the four 7-segment displays
    reg [1:0] digit_select = 0;
   
    // Digit to be displayed
    reg [3:0] digit;
   
    // Update digit selection on clock
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_select <= 0;
        end else begin
            digit_select <= digit_select + 1;
        end
    end
   
    // Select which digit to display
    always @(*) begin
        case (digit_select)
            2'b00: digit = first;
            2'b01: digit = second;
            2'b10: digit = third;
            2'b11: digit = fourth;
        endcase
    end
   
    // Select which display to enable
    always @(*) begin
        if (display_on) begin
            case (digit_select)
                2'b00: an = 4'b0111;
                2'b01: an = 4'b1011;
                2'b10: an = 4'b1101;
                2'b11: an = 4'b1110;
            endcase
        end else begin
            an = 4'b1111; // All displays off for blinking
        end
    end
   
    // Decode digit to 7-segment pattern (active low)
    always @(*) begin
        if (display_type == 2'b00) begin
            case (digit)
                4'h0: seg = 7'b1111110; // "UP"
                4'h1: seg = 7'b0111001; // "RIGHT"
                4'h2: seg = 7'b1110111; // "DOWN"
                4'h3: seg = 7'b0001111; // "LEFT"
                default: seg = 7'b1111111; // blank
            endcase
        end else if (display_type == 2'b01) begin
            case (digit)
                4'h0: seg = 7'b1000000; // "0"
                4'h1: seg = 7'b1111001; // "1"
                4'h2: seg = 7'b0100100; // "2"
                4'h3: seg = 7'b0110000; // "3"
                4'h4: seg = 7'b0011001; // "4"
                4'h5: seg = 7'b0010010; // "5"
                4'h6: seg = 7'b0000010; // "6"
                4'h7: seg = 7'b1111000; // "7"
                4'h8: seg = 7'b0000000; // "8"
                4'h9: seg = 7'b0010000; // "9"
                default: seg = 7'b1111111; // blank
            endcase
        end else if (display_type == 2'b10) begin
            case (digit)
                4'h0: seg = 7'b1000000; // "S"
                4'h1: seg = 7'b1111001; // "A"
                4'h2: seg = 7'b0100100; // "Y"
                4'h3: seg = 7'b0110000; // "S"
                default: seg = 7'b1111111; // blank
            endcase
        end else begin
            seg = 7'b1111111;
        end
    end
endmodule