module clock_divider(
    input clk,              // 100MHz system clock
    input reset,            // Reset signal
    output reg clk_1Hz,     // 1Hz clock for slow operations
    output reg clk_2Hz,     // 2Hz clock
    output reg clk_5Hz,     // 5Hz clock
    output reg clk_10Hz     // 10Hz clock for faster operations
);

    // Counter registers for each clock frequency
    reg [26:0] counter_1Hz;
    reg [25:0] counter_2Hz;
    reg [24:0] counter_5Hz;
    reg [23:0] counter_10Hz;
    
    // Constants for dividing 100MHz clock to target frequencies
    // 100,000,000 / 2 / TARGET_FREQ (accounting for toggling)
    localparam COUNT_1HZ = 50_000_000;  // 50M for 1Hz
    localparam COUNT_2HZ = 25_000_000;  // 25M for 2Hz
    localparam COUNT_5HZ = 10_000_000;  // 10M for 5Hz
    localparam COUNT_10HZ = 5_000_000;  // 5M for 10Hz
    
    // 1Hz clock divider
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_1Hz <= 0;
            clk_1Hz <= 0;
        end else begin
            if (counter_1Hz == COUNT_1HZ - 1) begin
                counter_1Hz <= 0;
                clk_1Hz <= ~clk_1Hz;
            end else begin
                counter_1Hz <= counter_1Hz + 1;
            end
        end
    end
    
    // 2Hz clock divider
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_2Hz <= 0;
            clk_2Hz <= 0;
        end else begin
            if (counter_2Hz == COUNT_2HZ - 1) begin
                counter_2Hz <= 0;
                clk_2Hz <= ~clk_2Hz;
            end else begin
                counter_2Hz <= counter_2Hz + 1;
            end
        end
    end
    
    // 5Hz clock divider
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_5Hz <= 0;
            clk_5Hz <= 0;
        end else begin
            if (counter_5Hz == COUNT_5HZ - 1) begin
                counter_5Hz <= 0;
                clk_5Hz <= ~clk_5Hz;
            end else begin
                counter_5Hz <= counter_5Hz + 1;
            end
        end
    end
    
    // 10Hz clock divider
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_10Hz <= 0;
            clk_10Hz <= 0;
        end else begin
            if (counter_10Hz == COUNT_10HZ - 1) begin
                counter_10Hz <= 0;
                clk_10Hz <= ~clk_10Hz;
            end else begin
                counter_10Hz <= counter_10Hz + 1;
            end
        end
    end

endmodule
