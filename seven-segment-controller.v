module seven_segment_controller(
    input clk,                      // System clock
    input reset,                    // Reset signal
    input display_mode,             // 0: game mode, 1: score mode
    input [31:0] display_value,     // Value to display (e.g., "SAYS", directions, etc.)
    input says_showing,             // Flag indicating "SAYS" is showing
    input [2:0] current_round,      // Current round
    input [2:0] highest_round,      // Highest round achieved
    output reg [6:0] seg,           // Seven segment segments (active low)
    output reg [3:0] an             // Seven segment anodes (active low)
);

    // Constants for segment values (active low)
    // Segments: gfedcba
    localparam CHAR_0 = 7'b1000000;
    localparam CHAR_1 = 7'b1111001;
    localparam CHAR_2 = 7'b0100100;
    localparam CHAR_3 = 7'b0110000;
    localparam CHAR_4 = 7'b0011001;
    localparam CHAR_5 = 7'b0010010;
    localparam CHAR_6 = 7'b0000010;
    localparam CHAR_7 = 7'b1111000;
    localparam CHAR_8 = 7'b0000000;
    localparam CHAR_9 = 7'b0010000;
    localparam CHAR_A = 7'b0001000;
    localparam CHAR_B = 7'b0000011;
    localparam CHAR_C = 7'b1000110;
    localparam CHAR_D = 7'b0100001;
    localparam CHAR_E = 7'b0000110;
    localparam CHAR_F = 7'b0001110;
    localparam CHAR_G = 7'b0010000; // Same as 9
    localparam CHAR_H = 7'b0001001;
    localparam CHAR_I = 7'b1111001; // Same as 1
    localparam CHAR_J = 7'b1100001;
    localparam CHAR_K = 7'b0001010;
    localparam CHAR_L = 7'b1000111;
    localparam CHAR_M = 7'b0101010; // Approximate
    localparam CHAR_N = 7'b0101011; // Approximate
    localparam CHAR_O = 7'b1000000; // Same as 0
    localparam CHAR_P = 7'b0001100;
    localparam CHAR_Q = 7'b0011000;
    localparam CHAR_R = 7'b0101111; // Approximate
    localparam CHAR_S = 7'b0010010; // Same as 5
    localparam CHAR_T = 7'b0000111;
    localparam CHAR_U = 7'b1000001;
    localparam CHAR_V = 7'b1100011; // Approximate
    localparam CHAR_W = 7'b1010101; // Approximate
    localparam CHAR_X = 7'b0001001; // Same as H
    localparam CHAR_Y = 7'b0010001;
    localparam CHAR_Z = 7'b0100100; // Same as 2
    localparam CHAR_BLANK = 7'b1111111;
    
    // Internal registers
    reg [16:0] refresh_counter;      // For digit multiplexing
    reg [1:0] digit_select;          // Current digit being displayed
    reg [7:0] ascii_to_display[3:0]; // ASCII values for each digit
    reg [6:0] segments[3:0];         // Segment values for each digit
    
    // Refresh counter for display multiplexing (~1kHz refresh rate)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            refresh_counter <= 0;
            digit_select <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
            if (refresh_counter >= 100000) begin // 1ms at 100MHz
                refresh_counter <= 0;
                digit_select <= digit_select + 1;
            end
        end
    end
    
    // Determine what to display based on mode
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ascii_to_display[0] <= 8'h00;
            ascii_to_display[1] <= 8'h00;
            ascii_to_display[2] <= 8'h00;
            ascii_to_display[3] <= 8'h00;
        end else begin
            if (display_mode == 0) begin // Game mode
                if (says_showing) begin
                    // Display "SAYS"
                    ascii_to_display[3] <= display_value[31:24]; // 'S'
                    ascii_to_display[2] <= display_value[23:16]; // 'A'
                    ascii_to_display[1] <= display_value[15:8];  // 'Y'
                    ascii_to_display[0] <= display_value[7:0];   // 'S'
                end else if (display_value != 0) begin
                    // Display directions or round number
                    if (display_value >= 32'h20 && display_value <= 32'h7A) begin // ASCII range
                        // This is a direction (U/D/L/R)
                        ascii_to_display[3] <= 8'h00;
                        ascii_to_display[2] <= 8'h00;
                        ascii_to_display[1] <= 8'h00;
                        ascii_to_display[0] <= display_value[15:8]; // Take the 2nd byte for display
                    end else begin
                        // This is a round number
                        ascii_to_display[3] <= 8'h00;
                        ascii_to_display[2] <= 8'h00;
                        ascii_to_display[1] <= 8'h00;
                        ascii_to_display[0] <= 8'h30 + display_value[3:0]; // Convert to ASCII
                    end
                end else begin
                    // Clear display
                    ascii_to_display[3] <= 8'h00;
                    ascii_to_display[2] <= 8'h00;
                    ascii_to_display[1] <= 8'h00;
                    ascii_to_display[0] <= 8'h00;
                end
            end else begin // Score mode
                // Display highest round achieved
                ascii_to_display[3] <= 8'h00;
                ascii_to_display[2] <= 8'h00;
                ascii_to_display[1] <= 8'h00;
                ascii_to_display[0] <= 8'h30 + highest_round; // Convert to ASCII
            end
        end
    end
    
    // Convert ASCII to segments
    always @(*) begin
        for (integer i = 0; i < 4; i = i + 1) begin
            case (ascii_to_display[i])
                8'h00: segments[i] = CHAR_BLANK;
                8'h30: segments[i] = CHAR_0;
                8'h31: segments[i] = CHAR_1;
                8'h32: segments[i] = CHAR_2;
                8'h33: segments[i] = CHAR_3;
                8'h34: segments[i] = CHAR_4;
                8'h35: segments[i] = CHAR_5;
                8'h36: segments[i] = CHAR_6;
                8'h37: segments[i] = CHAR_7;
                8'h38: segments[i] = CHAR_8;
                8'h39: segments[i] = CHAR_9;
                8'h41, 8'h61: segments[i] = CHAR_A; // A/a
                8'h42, 8'h62: segments[i] = CHAR_B; // B/b
                8'h43, 8'h63: segments[i] = CHAR_C; // C/c
                8'h44, 8'h64: segments[i] = CHAR_D; // D/d
                8'h45, 8'h65: segments[i] = CHAR_E; // E/e
                8'h46, 8'h66: segments[i] = CHAR_F; // F/f
                8'h47, 8'h67: segments[i] = CHAR_G; // G/g
                8'h48, 8'h68: segments[i] = CHAR_H; // H/h
                8'h49, 8'h69: segments[i] = CHAR_I; // I/i
                8'h4A, 8'h6A: segments[i] = CHAR_J; // J/j
                8'h4B, 8'h6B: segments[i] = CHAR_K; // K/k
                8'h4C, 8'h6C: segments[i] = CHAR_L; // L/l
                8'h4D, 8'h6D: segments[i] = CHAR_M; // M/m
                8'h4E, 8'h6E: segments[i] = CHAR_N; // N/n
                8'h4F, 8'h6F: segments[i] = CHAR_O; // O/o
                8'h50, 8'h70: segments[i] = CHAR_P; // P/p
                8'h51, 8'h71: segments[i] = CHAR_Q; // Q/q
                8'h52, 8'h72: segments[i] = CHAR_R; // R/r
                8'h53, 8'h73: segments[i] = CHAR_S; // S/s
                8'h54, 8'h74: segments[i] = CHAR_T; // T/t
                8'h55, 8'h75: segments[i] = CHAR_U; // U/u
                8'h56, 8'h76: segments[i] = CHAR_V; // V/v
                8'h57, 8'h77: segments[i] = CHAR_W; // W/w
                8'h58, 8'h78: segments[i] = CHAR_X; // X/x
                8'h59, 8'h79: segments[i] = CHAR_Y; // Y/y
                8'h5A, 8'h7A: segments[i] = CHAR_Z; // Z/z
                default: segments[i] = CHAR_BLANK;
            endcase
        end
    end
    
    // Multiplex the display
    always @(*) begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110;  // Enable rightmost digit
                seg = segments[0];
            end
            2'b01: begin
                an = 4'b1101;  // Enable 2nd digit from right
                seg = segments[1];
            end
            2'b10: begin
                an = 4'b1011;  // Enable 3rd digit from right
                seg = segments[2];
            end
            2'b11: begin
                an = 4'b0111;  // Enable leftmost digit
                seg = segments[3];
            end
        endcase
    end

endmodule
