//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2024 10:31:04
// Design Name: 
// Module Name: CAN_RX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
module CAN_RX (
    input wire clk,
    input wire can_rx_buf, 
    
    output reg SOF_detected=0,
    output reg receiving_frame,
    output reg can_rx,
    output reg [1:0] led,
    output reg [10:0] id_rx,     
    output reg [3:0] dlc_rx,     
    output reg [63:0] crc_rx,
    output reg [63:0] data_rx,   
    output reg [3:0] current_state=0,
    output reg [31:0] state_ascii,
    output reg red,
    output reg green,
    output reg blue,
    output reg debug_led,
    output reg [15:0]bit_counter, 
    output reg frame_valid=0  
);

    reg [14:0] crc_reg;
    reg rtr;

    reg r0;
    reg sof;
    reg [4:0] next_state;

    reg rst_n;

    // State definitions
    parameter IDLE = 0, SOF = 1, ID_STATE = 2, RTR = 3, IDE = 4, R0 = 5, DLC_STATE = 6, 
              DATA_STATE = 7, CRC_STATE = 8, DEL1 = 9, ACK_STATE = 10, DEL2=11, EOF_STATE = 12;
    reg [3:0] data_length;

always @(*) begin

        case (current_state)
            IDLE:       state_ascii = "IDLE"; // ASCII for "IDLE"
            SOF:        state_ascii = "SOF "; // ASCII for "SOF "
            ID_STATE:   state_ascii = "ID  "; // ASCII for "ID  "
            RTR:        state_ascii = "RTR "; // ASCII for "RTR "
            IDE:        state_ascii = "IDE "; // ASCII for "IDE "
            R0:         state_ascii = "R0  "; // ASCII for "R0  "
            DLC_STATE:  state_ascii = "DLC "; // ASCII for "DLC "
            DATA_STATE: state_ascii = "DATA"; // ASCII for "DATA"
            CRC_STATE:  state_ascii = "CRC "; // ASCII for "CRC "
            DEL1:       state_ascii = "DEL1"; // ASCII for "DEL1"
            ACK_STATE:  state_ascii = "ACK "; // ASCII for "ACK "
            DEL2:       state_ascii = "DEL2"; // ASCII for "DEL2"
            EOF_STATE:  state_ascii = "EOF "; // ASCII for "EOF "
            default:    state_ascii = "UNK "; // ASCII for "UNK " (Unknown)
        endcase
    end

always @(posedge clk)
begin   
    if (current_state == IDLE && !can_rx && !SOF_detected)begin
    SOF_detected <=1;
    receiving_frame <= 1'b1;
    end
    else begin
    if (current_state != IDLE && SOF_detected)
    SOF_detected <=1;
    end
 
    if (current_state == EOF_STATE && bit_counter==6 && SOF_detected)
    SOF_detected <=0;
    
end    

always @(negedge clk)
begin   
    if (receiving_frame) begin       
        current_state <= next_state;
    end        
    else begin
        current_state <= IDLE;
     end
end      
 
    always @(can_rx_buf) begin
        can_rx <= can_rx_buf; 
    end

	// Next state logic
    always @(bit_counter or receiving_frame or frame_valid or current_state or can_rx)
    begin: NEXT_STATE_LOGIC
        case (current_state)
            IDLE: 
                if (SOF_detected)
                    next_state <= ID_STATE; 
                else 
                    next_state = IDLE;
            SOF: 
                if (bit_counter == 1) 
                    next_state = ID_STATE; 
                else 
                    next_state = SOF;
            ID_STATE: 
                if (frame_valid && bit_counter == 10) 
                    next_state = RTR; 
                else 
                    next_state = ID_STATE;
            RTR: 
                if (frame_valid)
                    next_state = IDE; 
                else 
                    next_state = RTR;
            IDE: 
                if (frame_valid) 
                    next_state = R0; 
                else 
                    next_state = IDE;
            R0:
                if (frame_valid) 
                    next_state = DLC_STATE; 
                else 
                    next_state = R0;
            DLC_STATE: 
                if (frame_valid && bit_counter == 3) 
                    next_state = DATA_STATE; 
                else 
                    next_state = DLC_STATE;
            DATA_STATE: 
                if (frame_valid && bit_counter == (data_length * 8)) 
                    next_state = CRC_STATE; 
                else 
                    next_state = DATA_STATE;
            CRC_STATE: 
                if (frame_valid && bit_counter == 14) 
                    next_state = DEL1; 
                else 
                    next_state = CRC_STATE;
            DEL1: 
                if (frame_valid) 
                    next_state = ACK_STATE; 
                else 
                    next_state = DEL1;        
            ACK_STATE: 
                if (frame_valid)
                    next_state = DEL2; 
                else 
                    next_state = ACK_STATE;
            DEL2: 
                if (frame_valid) 
                    next_state = EOF_STATE; 
                else 
                    next_state = DEL2;        
            EOF_STATE: 
                if (frame_valid && bit_counter == 6) 
                    next_state = IDLE; 
                else 
                    next_state = EOF_STATE;
            default: 
                next_state = IDLE;
        endcase 
    end	

always @(negedge clk)
begin
  case (current_state)
  IDLE: begin
             if (receiving_frame && !frame_valid) begin
                 frame_valid <= 1'b1;
                 debug_led <= 1'b0;
                 id_rx[10 - bit_counter] <= can_rx;   
                 bit_counter <= bit_counter + 1;
                end else begin
                end 
                end
  SOF: begin
                            red <= 1'b1;
                            green <= 1'b0; 
                            blue <= 1'b1;  
                   id_rx[10 - bit_counter] <= can_rx;          
                   bit_counter <= bit_counter + 1;  
                end
  ID_STATE:  begin
                    id_rx[10 - bit_counter] <= can_rx;
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == 10) begin
                        bit_counter <= 0;
                    end
                end
  
   RTR:   begin
                    
                end
                
                IDE:   begin                           
                end
                
                R0:   begin                        
                end
  DLC_STATE: begin 
              
                    case (bit_counter)
                        0: dlc_rx[3] <= can_rx;  // MSB
                        1: dlc_rx[2] <= can_rx;
                        2: dlc_rx[1] <= can_rx;
                        3: dlc_rx[0] <= can_rx;  // LSB
                    endcase
                   
                    bit_counter <= bit_counter + 1;
                    
                    // Once 4 bits (DLC) are received, mark DLC complete
                    if (bit_counter == 3) begin
                        bit_counter <= 1;
                        red <= 1'b1;
                         green <= 1'b1; 
                         blue <= 1'b0;  
                    end
                end
                            
                DATA_STATE:  begin
                    case (dlc_rx)
                                    4'b0000: data_length = 0;       // 0 bytes
                                    4'b0001: data_length = 1;       // 1 byte
                                    4'b0010: data_length = 2;      // 2 bytes
                                    4'b0011: data_length = 3;      // 3 bytes
                                    4'b0100: data_length = 4;      // 4 bytes
                                    4'b0101: data_length = 5;      // 5 bytes
                                    4'b0110: data_length = 6;      // 6 bytes
                                    4'b0111: data_length = 7;      // 7 bytes
                                    4'b1000: data_length = 8;      // 8 bytes
                           default: data_length = 0;    // Invalid DLC
                     endcase
                    
                    // Continue receiving data bits based on the received DLC
                    data_rx[((data_length*8))-bit_counter] <= can_rx;
                    bit_counter <= bit_counter + 1;

                    // Check if all data is received based on DLC
                    if (bit_counter == (data_length * 8) ) begin
                        bit_counter <= 0;
                        red <= 1'b1;
                            green <= 1'b0; 
                            blue <= 1'b0;  
                    end
                end

                
                CRC_STATE:  begin
                    // Handle CRC capture if needed (skipped here)
                    crc_rx[bit_counter] <= can_rx;
                    bit_counter <= bit_counter + 1;

                    // Check if all data is received based on DLC
                    if (bit_counter == 14) begin
                        bit_counter <= 0;
                    end
                end
                
                DEL1:  begin
                                      
                end
                
                ACK_STATE:   begin
                  
                end
                
                DEL2:  begin
                  
                   red <= 1'b1;
                   green <= 1'b0; 
                   blue <= 1'b0;  
                    
                end
                
                EOF_STATE:  begin
                    if (can_rx == 1'b1)   // Check for EOF (recessive)
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == 4) begin
                        id_rx <= 11'b00000000000;
                        dlc_rx <= 4'b0000;
                    end      
                    if (bit_counter == 6) begin
                        bit_counter <= 0;
                        frame_valid <= 1'b0;  // Frame is valid
                        debug_led <= 1'b1;
                        red <= 1'b0;
                        green <= 1'b1; 
                        blue <= 1'b1;
                    end
   end
   endcase                 
end   

endmodule
