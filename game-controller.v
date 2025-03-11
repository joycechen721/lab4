module game_controller(
    input clk,                      // System clock
    input reset,                    // Reset signal
    input select,                   // Mode select button
    input [15:0] switches,          // Switches for user input
    input [3:0] joystick_direction, // Direction from joystick
    input clk_1Hz,                  // 1Hz clock
    input clk_2Hz,                  // 2Hz clock
    input clk_5Hz,                  // 5Hz clock
    input clk_10Hz,                 // 10Hz clock
    output reg player_clk,          // Clock for player interaction (varies with level)
    output reg [15:0] sequence_leds,// LEDs to display the sequence
    output reg [15:0] game_over_leds,// LEDs for game over indication
    output reg [15:0] current_leds, // Current LED state
    output reg [2:0] current_round, // Current round (1-7)
    output reg [2:0] highest_round, // Highest round achieved
    output reg [31:0] display_value,// Value to display on seven segment
    output reg [1:0] game_state,    // Game state
    output reg says_showing,        // Indicates when "SAYS" is being shown
    output reg says_sequence_complete, // Indicates when "SAYS" sequence is complete
    output reg says_times_odd,      // Indicates if "SAYS" has been shown odd times
    output reg sequence_complete,   // Indicates when sequence showing is complete
    output reg input_valid,         // Indicates when player input is valid
    output reg input_correct,       // Indicates if player input is correct
    output reg game_over,           // Indicates game over state
    output reg display_mode         // 0: game mode, 1: score mode
);

    // Game states
    localparam STATE_INIT = 2'b00;
    localparam STATE_SHOW_SEQUENCE = 2'b01;
    localparam STATE_PLAYER_INPUT = 2'b10;
    localparam STATE_GAME_OVER = 2'b11;
    
    // Direction values
    localparam DIR_NONE = 4'd0;
    localparam DIR_UP = 4'd1;
    localparam DIR_DOWN = 4'd2;
    localparam DIR_LEFT = 4'd3;
    localparam DIR_RIGHT = 4'd4;
    
    // Constants
    localparam MAX_SEQUENCE_LENGTH = 32;
    localparam MAX_ROUND = 3'd7;          // Maximum round (1-7)
    
    // Memory to store sequence (both LED and direction sequences)
    reg [15:0] led_sequence[0:MAX_SEQUENCE_LENGTH-1];
    reg [3:0] dir_sequence[0:MAX_SEQUENCE_LENGTH-1];
    reg [5:0] sequence_length;            // Current sequence length
    reg [5:0] sequence_position;          // Current position in sequence
    reg [3:0] says_count;                 // Number of times "SAYS" has shown
    reg [3:0] max_says_count;             // Target number of times to show "SAYS"
    reg says_displayed;                   // Flag to track if "SAYS" has been displayed
    
    // Player input tracking
    reg [15:0] player_switches;           // Previous switch state for edge detection
    reg [3:0] player_direction;           // Previous direction for edge detection
    reg player_input_required;            // Flag indicating if player needs to input
    reg [1:0] input_type;                 // 0: none, 1: switches, 2: joystick
    
    // Random sequence generation
    reg [31:0] random_value;
    
    // Mode tracking
    reg select_pressed;                   // Previous select button state
    reg select_debounce;                  // Debounce flag for select button
    reg [19:0] select_counter;            // Debounce counter
    
    // Previous clock state for edge detection
    reg player_clk_prev;
    
    // Clock selection based on level
    always @(*) begin
        case (current_round)
            3'd1, 3'd2: player_clk = clk_1Hz;   // Rounds 1-2: 1Hz
            3'd3, 3'd4: player_clk = clk_2Hz;   // Rounds 3-4: 2Hz
            3'd5, 3'd6: player_clk = clk_5Hz;   // Rounds 5-6: 5Hz
            3'd7: player_clk = clk_10Hz;        // Round 7: 10Hz
            default: player_clk = clk_1Hz;
        endcase
    end
    
    // Simple pseudo-random number generator
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            random_value <= 32'hABCDEF01; // Seed value
        end else begin
            random_value <= {random_value[30:0], random_value[31] ^ random_value[27] ^ random_value[23] ^ random_value[19]};
        end
    end
    
    // Update previous clock state
    always @(posedge clk) begin
        player_clk_prev <= player_clk;
    end
    
    // Main game controller state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all registers
            game_state <= STATE_INIT;
            sequence_leds <= 0;
            game_over_leds <= 0;
            current_leds <= 0;
            current_round <= 1;
            highest_round <= 1;
            display_value <= 0;
            says_showing <= 0;
            says_sequence_complete <= 0;
            says_times_odd <= 0;
            sequence_complete <= 0;
            input_valid <= 0;
            input_correct <= 0;
            game_over <= 0;
            display_mode <= 0;
            sequence_length <= 0;
            sequence_position <= 0;
            says_count <= 0;
            max_says_count <= 1; // Default to 1 time
            says_displayed <= 0;
            player_switches <= 0;
            player_direction <= 0;
            player_input_required <= 0;
            input_type <= 0;
            select_pressed <= 0;
            select_debounce <= 0;
            select_counter <= 0;
            
            // Initialize first sequence
            generate_new_sequence(1);
        end else begin
            // Handle select button for mode switching with debouncing
            if (select && !select_pressed && !select_debounce) begin
                select_debounce <= 1;
                select_counter <= 0;
            end
            
            if (select_debounce) begin
                if (select_counter >= 200000) begin // 2ms debounce at 100MHz
                    select_debounce <= 0;
                    if (select) begin
                        display_mode <= ~display_mode;
                    end
                end else begin
                    select_counter <= select_counter + 1;
                end
            end
            
            select_pressed <= select;
            
            // Game state machine
            case (game_state)
                STATE_INIT: begin
                    // Initialize a new round
                    current_leds <= 0;
                    says_showing <= 0;
                    says_sequence_complete <= 0;
                    says_times_odd <= 0;
                    sequence_complete <= 0;
                    input_valid <= 0;
                    input_correct <= 0;
                    game_over <= 0;
                    sequence_position <= 0;
                    says_count <= 0;
                    says_displayed <= 0;
                    player_input_required <= 0;
                    
                    // Determine how many times to show "SAYS" (odd number 1-9)
                    max_says_count <= ((random_value[3:0] % 5) * 2) + 1; // 1,3,5,7,9
                    
                    // Move to sequence display state
                    game_state <= STATE_SHOW_SEQUENCE;
                end
                
                STATE_SHOW_SEQUENCE: begin
                    // Handle showing "SAYS" and the sequence
                    if (!says_displayed) begin
                        // Show "SAYS" on seven segment display
                        says_showing <= 1;
                        display_value <= 32'h53415953; // "SAYS" in ASCII
                        
                        // Count the number of times "SAYS" has been shown
                        if (player_clk && !player_clk_prev) begin
                            says_count <= says_count + 1;
                            if (says_count >= max_says_count) begin
                                says_displayed <= 1;
                                says_sequence_complete <= 1;
                                says_times_odd <= (says_count % 2 == 1);
                                says_showing <= 0;
                                display_value <= 0;
                                sequence_position <= 0;
                            end
                        end
                    end else begin
                        // Show the sequence on LEDs and seven segment
                        says_showing <= 0;
                        
                        if (player_clk && !player_clk_prev) begin
                            if (sequence_position < sequence_length) begin
                                // Display current step in sequence
                                if (sequence_position % 2 == 0) begin
                                    // Even positions: show the pattern
                                    if (input_type[sequence_position] == 1) begin
                                        // Show LED pattern
                                        current_leds <= led_sequence[sequence_position];
                                        display_value <= 0;
                                    end else begin
                                        // Show direction on display
                                        current_leds <= 0;
                                        case (dir_sequence[sequence_position])
                                            DIR_UP: display_value <= 32'h00550000; // "U"
                                            DIR_DOWN: display_value <= 32'h00440000; // "D"
                                            DIR_LEFT: display_value <= 32'h004C0000; // "L"
                                            DIR_RIGHT: display_value <= 32'h00520000; // "R"
                                            default: display_value <= 0;
                                        endcase
                                    end
                                end else begin
                                    // Odd positions: clear display between steps
                                    current_leds <= 0;
                                    display_value <= 0;
                                end
                                sequence_position <= sequence_position + 1;
                            end else begin
                                // Sequence complete, ready for player input
                                current_leds <= 0;
                                display_value <= current_round;
                                sequence_complete <= 1;
                                game_state <= STATE_PLAYER_INPUT;
                                sequence_position <= 0;
                                player_input_required <= 1;
                            end
                        end
                    end
                end
                
                STATE_PLAYER_INPUT: begin
                    // Handle player input
                    if (player_input_required) begin
                        // Check if player tried to input before "SAYS" appeared or when it appeared even times
                        if (!says_sequence_complete || (says_sequence_complete && !says_times_odd)) begin
                            if ((switches != player_switches) || (joystick_direction != DIR_NONE && joystick_direction != player_direction)) begin
                                // Player tried to input at wrong time
                                game_over <= 1;
                                game_state <= STATE_GAME_OVER;
                            end
                        end else begin
                            // Process player input at correct time
                            input_valid <= 1;
                            
                            // Check if current sequence step is switch or joystick
                            if (input_type[sequence_position] == 1) begin
                                // Check switch input
                                if (switches != player_switches) begin
                                    player_switches <= switches;
                                    if (switches == led_sequence[sequence_position]) begin
                                        input_correct <= 1;
                                        sequence_position <= sequence_position + 1;
                                    end else begin
                                        input_correct <= 0;
                                        game_over <= 1;
                                        game_state <= STATE_GAME_OVER;
                                    end
                                end
                            end else if (input_type[sequence_position] == 2) begin
                                // Check joystick input
                                if (joystick_direction != player_direction && joystick_direction != DIR_NONE) begin
                                    player_direction <= joystick_direction;
                                    if (joystick_direction == dir_sequence[sequence_position]) begin
                                        input_correct <= 1;
                                        sequence_position <= sequence_position + 1;
                                    end else begin
                                        input_correct <= 0;
                                        game_over <= 1;
                                        game_state <= STATE_GAME_OVER;
                                    end
                                end
                            end
                            
                            // Check if player completed the sequence correctly
                            if (sequence_position >= sequence_length) begin
                                // Player successfully completed the sequence
                                if (current_round < MAX_ROUND) begin
                                    current_round <= current_round + 1;
                                    if (current_round >= highest_round) begin
                                        highest_round <= current_round + 1;
                                    end
                                end
                                
                                // Generate new sequence if needed
                                if (current_round % 3 == 0) begin
                                    // Every 3 rounds, generate a completely new sequence
                                    generate_new_sequence(current_round + 1);
                                end else begin
                                    // Otherwise, extend the existing sequence
                                    extend_sequence();
                                end
                                
                                // Return to init state to start next round
                                game_state <= STATE_INIT;
                            end
                        end
                    end
                end
                
                STATE_GAME_OVER: begin
                    // Flash all LEDs to indicate game over
                    if (clk_2Hz) begin
                        game_over_leds <= 16'hFFFF;
                    end else begin
                        game_over_leds <= 16'h0000;
                    end
                    
                    current_leds <= game_over_leds;
                    
                    // Wait for reset button to restart
                    if (reset) begin
                        game_state <= STATE_INIT;
                        current_round <= 1;
                        generate_new_sequence(1);
                    end
                end
                
                default: game_state <= STATE_INIT;
            endcase
        end
    end
    
    // Task to generate a new sequence
    task generate_new_sequence;
        input [2:0] round;
        integer i;
        begin
            sequence_length <= round;
            for (i = 0; i < MAX_SEQUENCE_LENGTH; i = i + 1) begin
                // Generate random LED and direction sequences
                // For early rounds (1-3), use either all LEDs or all directions
                if (round <= 3) begin
                    if (random_value[31] == 1) begin
                        // LED sequence (switches)
                        input_type[i] <= 1;
                        led_sequence[i] <= 16'h0001 << (random_value[3:0] % 16); // One hot LED
                        dir_sequence[i] <= DIR_NONE;
                    end else begin
                        // Direction sequence (joystick)
                        input_type[i] <= 2;
                        led_sequence[i] <= 16'h0000;
                        dir_sequence[i] <= (random_value[1:0] % 4) + 1; // 1-4 for U/D/L/R
                    end
                end else begin
                    // For later rounds, mix LED and direction inputs
                    if (i % 2 == 0) begin
                        // LED sequence (switches)
                        input_type[i] <= 1;
                        led_sequence[i] <= 16'h0001 << (random_value[3:0] % 16); // One hot LED
                        dir_sequence[i] <= DIR_NONE;
                    end else begin
                        // Direction sequence (joystick)
                        input_type[i] <= 2;
                        led_sequence[i] <= 16'h0000;
                        dir_sequence[i] <= (random_value[1:0] % 4) + 1; // 1-4 for U/D/L/R
                    end
                end
                
                // Shift random value for next iteration
                random_value <= {random_value[30:0], random_value[31] ^ random_value[21] ^ random_value[1] ^ random_value[0]};
            end
        end
    endtask
    
    // Task to extend an existing sequence
    task extend_sequence;
        begin
            sequence_length <= sequence_length + 1;
            
            // Add a new random step
            if (random_value[31] == 1) begin
                // LED sequence (switches)
                input_type[sequence_length] <= 1;
                led_sequence[sequence_length] <= 16'h0001 << (random_value[3:0] % 16); // One hot LED
                dir_sequence[sequence_length] <= DIR_NONE;
            end else begin
                // Direction sequence (joystick)
                input_type[sequence_length] <= 2;
                led_sequence[sequence_length] <= 16'h0000;
                dir_sequence[sequence_length] <= (random_value[1:0] % 4) + 1; // 1-4 for U/D/L/R
            end
            
            // Shift random value for next use
            random_value <= {random_value[30:0], random_value[31] ^ random_value[21] ^ random_value[1] ^ random_value[0]};
        end
    endtask

endmodule