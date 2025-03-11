module joystick_direction_detector(
    input clk,                      // System clock
    input reset,                    // Reset signal
    input [7:0] x_pos,              // X position from joystick (0-255)
    input [7:0] y_pos,              // Y position from joystick (0-255)
    output reg [3:0] direction      // 0: none, 1: up, 2: down, 3: left, 4: right
);

    // Define thresholds for joystick movement detection
    // Center is typically around 128 (0x80)
    localparam THRESHOLD = 40;      // How far from center to register as a direction
    localparam CENTER = 128;
    
    // Direction values
    localparam DIR_NONE = 4'd0;
    localparam DIR_UP = 4'd1;
    localparam DIR_DOWN = 4'd2;
    localparam DIR_LEFT = 4'd3;
    localparam DIR_RIGHT = 4'd4;
    
    // Debouncing counter and threshold
    reg [19:0] debounce_counter;
    localparam DEBOUNCE_THRESHOLD = 500000; // 5ms at 100MHz
    
    // Previous direction for debouncing
    reg [3:0] prev_direction;
    reg direction_changed;
    
    // Detect joystick direction
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            direction <= DIR_NONE;
            prev_direction <= DIR_NONE;
            debounce_counter <= 0;
            direction_changed <= 0;
        end else begin
            // Determine current raw direction based on joystick position
            if (y_pos < CENTER - THRESHOLD && 
                (x_pos >= CENTER - THRESHOLD && x_pos <= CENTER + THRESHOLD)) begin
                // Up direction - Y is low, X is centered
                if (prev_direction != DIR_UP) begin
                    prev_direction <= DIR_UP;
                    direction_changed <= 1;
                    debounce_counter <= 0;
                end
            end
            else if (y_pos > CENTER + THRESHOLD && 
                    (x_pos >= CENTER - THRESHOLD && x_pos <= CENTER + THRESHOLD)) begin
                // Down direction - Y is high, X is centered
                if (prev_direction != DIR_DOWN) begin
                    prev_direction <= DIR_DOWN;
                    direction_changed <= 1;
                    debounce_counter <= 0;
                end
            end
            else if (x_pos < CENTER - THRESHOLD && 
                    (y_pos >= CENTER - THRESHOLD && y_pos <= CENTER + THRESHOLD)) begin
                // Left direction - X is low, Y is centered
                if (prev_direction != DIR_LEFT) begin
                    prev_direction <= DIR_LEFT;
                    direction_changed <= 1;
                    debounce_counter <= 0;
                end
            end
            else if (x_pos > CENTER + THRESHOLD && 
                    (y_pos >= CENTER - THRESHOLD && y_pos <= CENTER + THRESHOLD)) begin
                // Right direction - X is high, Y is centered
                if (prev_direction != DIR_RIGHT) begin
                    prev_direction <= DIR_RIGHT;
                    direction_changed <= 1;
                    debounce_counter <= 0;
                end
            end
            else if ((x_pos >= CENTER - THRESHOLD && x_pos <= CENTER + THRESHOLD) && 
                    (y_pos >= CENTER - THRESHOLD && y_pos <= CENTER + THRESHOLD)) begin
                // No direction - both X and Y are centered
                if (prev_direction != DIR_NONE) begin
                    prev_direction <= DIR_NONE;
                    direction_changed <= 1;
                    debounce_counter <= 0;
                end
            end
            
            // Handle debouncing
            if (direction_changed) begin
                if (debounce_counter >= DEBOUNCE_THRESHOLD) begin
                    direction <= prev_direction;
                    direction_changed <= 0;
                    debounce_counter <= 0;
                end else begin
                    debounce_counter <= debounce_counter + 1;
                end
            end
        end
    end

endmodule
