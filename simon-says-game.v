module simon_says_top(
    input clk,              // 100MHz system clock
    input reset,            // Reset button
    input select,           // Mode select button
    input [15:0] switches,  // 16 switches for user input
    input JA1,              // PMOD JA pin 1 - MISO (Master In Slave Out)
    output JA2,             // PMOD JA pin 2 - MOSI (Master Out Slave In)
    output JA3,             // PMOD JA pin 3 - SCLK (Serial Clock)
    output JA4,             // PMOD JA pin 4 - SS (Slave Select)
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
    wire [3:0] joystick_direction; // 0: none, 1: up, 2: down, 3: left, 4: right
    wire [7:0] joystick_x, joystick_y;
    wire [31:0] display_value;
    wire [1:0] game_state; // 0: waiting, 1: showing sequence, 2: player input, 3: game over
    wire says_showing;
    wire says_sequence_complete;
    wire says_times_odd;
    wire sequence_complete;
    wire input_valid;
    wire input_correct;
    wire game_over;
    wire display_mode; // 0: game mode, 1: score mode
    
    // Clock divider for generating slower clocks
    wire clk_1Hz, clk_2Hz, clk_5Hz, clk_10Hz;
    wire player_clk; // Clock rate increases with level
    
    // Module instantiations
    clock_divider clock_div (
        .clk(clk),
        .reset(reset),
        .clk_1Hz(clk_1Hz),
        .clk_2Hz(clk_2Hz),
        .clk_5Hz(clk_5Hz),
        .clk_10Hz(clk_10Hz)
    );
    
    // SPI controller for joystick
    spi_controller joystick_spi (
        .clk(clk),
        .reset(reset),
        .miso(JA1),         // Master In Slave Out
        .mosi(JA2),         // Master Out Slave In
        .sclk(JA3),         // Serial Clock
        .ss(JA4),           // Slave Select
        .x_pos(joystick_x), // X position (0-255)
        .y_pos(joystick_y)  // Y position (0-255)
    );
    
    // Joystick direction detector
    joystick_direction_detector joy_dir (
        .clk(clk),
        .reset(reset),
        .x_pos(joystick_x),
        .y_pos(joystick_y),
        .direction(joystick_direction)
    );
    
    // Game controller
    game_controller game_ctrl (
        .clk(clk),
        .reset(reset),
        .select(select),
        .switches(switches),
        .joystick_direction(joystick_direction),
        .clk_1Hz(clk_1Hz),
        .clk_2Hz(clk_2Hz),
        .clk_5Hz(clk_5Hz),
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
        .display_mode(display_mode)
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
