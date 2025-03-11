module spi_controller(
    input clk,              // System clock (100MHz)
    input reset,            // Reset signal
    input miso,             // Master In Slave Out (from joystick)
    output reg mosi,        // Master Out Slave In (to joystick)
    output reg sclk,        // Serial clock
    output reg ss,          // Slave select (active low)
    output reg [7:0] x_pos, // X position (0-255)
    output reg [7:0] y_pos  // Y position (0-255)
);

    // SPI parameters
    localparam SPI_CLK_DIV = 100;       // For ~1MHz SPI clock (100MHz/100)
    localparam CMD_SIZE = 8;            // Command size in bits
    localparam DATA_SIZE = 8;           // Data size in bits
    localparam TRANSACTION_SIZE = 40;   // Total bits in transaction
    
    // SPI state machine states
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam DONE = 2'b10;
    
    // Registers
    reg [1:0] state;
    reg [7:0] spi_counter;      // Counts bits in the transaction
    reg [6:0] clk_counter;      // Divides system clock to SPI clock
    reg [7:0] cmd_data;         // Command to send
    reg [39:0] spi_data;        // Data from SPI transaction
    reg spi_clk_enable;         // Enable SPI clock
    
    // Command to send to PmodJSTK - 0x80 is a read command
    localparam [7:0] JOYSTICK_CMD = 8'h80;
    
    // SPI clock generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_counter <= 0;
            sclk <= 0;
        end else if (spi_clk_enable) begin
            if (clk_counter == SPI_CLK_DIV/2 - 1) begin
                sclk <= ~sclk;
                clk_counter <= 0;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end else begin
            sclk <= 0;
            clk_counter <= 0;
        end
    end
    
    // SPI state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            spi_counter <= 0;
            mosi <= 0;
            ss <= 1;             // Deselect slave
            spi_clk_enable <= 0;
            cmd_data <= JOYSTICK_CMD;
            x_pos <= 8'h80;      // Center position
            y_pos <= 8'h80;      // Center position
            spi_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // Start SPI transaction every 10ms (10Hz)
                    if (spi_counter >= 100) begin
                        spi_counter <= 0;
                        state <= TRANSFER;
                        ss <= 0;  // Select slave
                        spi_clk_enable <= 1;
                        cmd_data <= JOYSTICK_CMD;
                        spi_counter <= 0;
                    end else begin
                        spi_counter <= spi_counter + 1;
                    end
                end
                
                TRANSFER: begin
                    // Handle SPI transaction
                    if (sclk == 0 && clk_counter == SPI_CLK_DIV/2 - 1) begin
                        // Prepare to send bit on rising edge
                        if (spi_counter < CMD_SIZE) begin
                            // Send command byte
                            mosi <= cmd_data[CMD_SIZE-1-spi_counter];
                        end else begin
                            // After command, send zeros
                            mosi <= 0;
                        end
                    end else if (sclk == 1 && clk_counter == SPI_CLK_DIV/2 - 1) begin
                        // Sample received bit on falling edge
                        spi_data <= {spi_data[38:0], miso};
                        
                        // Count bits
                        if (spi_counter == TRANSACTION_SIZE - 1) begin
                            state <= DONE;
                            spi_counter <= 0;
                        end else begin
                            spi_counter <= spi_counter + 1;
                        end
                    end
                end
                
                DONE: begin
                    // Transaction complete
                    ss <= 1;  // Deselect slave
                    spi_clk_enable <= 0;
                    
                    // Extract X and Y positions from the received data
                    x_pos <= spi_data[23:16]; // X position is in third byte
                    y_pos <= spi_data[15:8];  // Y position is in second byte
                    
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
