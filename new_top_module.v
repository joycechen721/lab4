module simon_says_top(
    input clk,              // 100MHz system clock
    input reset,            // Reset button
    input select,           // Mode select button
    input [15:0] switches,  // 16 switches for user input
    input [3:0] rows,   // Pmod JB pins 10 to 7
    output [3:0] cols,  // Pmod JB pins 4 to 1
    output [15:0] leds,     // 16 LEDs for sequence display
    output [6:0] seg,       // Seven segment display segments
    output [3:0] an         // Seven segment display anodes
);

    // Internal signals
    wire [15:0] sequence_leds;
    wire [15:0] game_over_leds;
    wire [15:0] current_leds;
    wire [2:0] current_round;
    wire [2:0] highest_round;
    wire [3:0] keypad_value;      // Value from keypad (0-F)
    wire keypad_valid;            // Signal indicating valid keypad press
    wire [31:0] display_value;
    wire [1:0] game_state;        // 0: waiting, 1: showing sequence, 2: player input, 3: game over
    wire says_showing;
    wire says_sequence_complete;
    wire says_times_odd;
    wire sequence_complete;
    wire input_valid;
    wire input_correct;
    wire game_over;
    wire display_mode;           // 0: game mode, 1: score mode
    
    // Debug signals
    wire [15:0] debug_switch_toggled;
    wire [15:0] debug_expected_toggle;
    wire [15:0] debug_led_sequence_current;
    wire [15:0] debug_switches;
    wire [15:0] debug_player_switches;
    wire [5:0]  debug_sequence_position;
    
    // Clock divider for generating slower clocks
    wire clk_1Hz, clk_2Hz, clk_3Hz, clk_10Hz;
    wire player_clk; // Clock rate increases with level

    wire [3:0] w_dec;
    
    // Module instantiations
    clock_divider clock_div (
        .clk(clk),
        .reset(reset),
        .clk_1Hz(clk_1Hz),
        .clk_2Hz(clk_2Hz),
        .clk_3Hz(clk_3Hz),
        .clk_10Hz(clk_10Hz)
    );
    
    // Keypad controller for 4x4 matrix keypad
    keypad_controller keypad_ctrl (
        .clk(clk),
        .row(rows),
		.col(cols),
        .dec_out(w_dec)
    );
    
    // Game controller
    game_controller game_ctrl (
        .clk(clk),
        .reset(reset),
        .select(select),
        .switches(switches),
        .keypad_value(w_dec),
        .clk_1Hz(clk_1Hz),
        .clk_2Hz(clk_2Hz),
        .clk_3Hz(clk_3Hz),
        .clk_10Hz(clk_10Hz),
        .player_clk(player_clk),
        .sequence_leds(sequence_leds),
        .game_over_leds(game_over_leds),
        .current_leds(current_leds),
        .current_round(current_round),
        .highest_round(highest_round),
        .display_value(display_value),
        .game_state(game_state),
        .says_showing(says_showing),
        .says_sequence_complete(says_sequence_complete),
        .says_times_odd(says_times_odd),
        .sequence_complete(sequence_complete),
        .input_valid(input_valid),
        .input_correct(input_correct),
        .game_over(game_over),
        .display_mode(display_mode),
        
        // Connect debug outputs
        .debug_switch_toggled(debug_switch_toggled),
        .debug_expected_toggle(debug_expected_toggle),
        .debug_led_sequence_current(debug_led_sequence_current),
        .debug_switches(debug_switches),
        .debug_player_switches(debug_player_switches),
        .debug_sequence_position(debug_sequence_position)
    );
    
    // Seven segment display controller
    seven_segment_controller seg_ctrl (
        .clk(clk),
        .reset(reset),
        .display_mode(display_mode),
        .display_value(display_value),
        .says_showing(says_showing),
        .current_round(current_round),
        .highest_round(highest_round),
        .seg(seg),
        .an(an)
    );
    
    // LED controller
    assign leds = current_leds;

endmodule