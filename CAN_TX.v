`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2024 16:28:11
// Design Name: 
// Module Name: CAN TX
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


module CAN_TX(
        input wire clk,
        input wire sig, //this signal is physically connected to the btn1 on the board
            
        output reg can_tx,reg rst_n,
        output reg [1:0] led,
        output reg [14:0] crc_reg,         // CRC register
        output reg [3:0] dlc,              // Data Length Code (DLC)
        output reg [10:0] id,
        output reg [3:0] current_state,
        output reg [15:0]bit_counter ,
        output reg [63:0] data,
        output reg send_frame=0, sending_frame=0,idle=1      
    );



parameter IDLE = 0, SOF = 1, ID_STATE = 2, RTR = 3, IDE = 4, R0 = 5, DLC_STATE = 6, 
          DATA_STATE = 7, CRC_STATE = 8, DEL1 = 9, ACK_STATE = 10, DEL2 = 11, EOF_STATE = 12;

//// Parameters for debouncing
          parameter DEBOUNCE_MAX = 100000; // Adjust this value based on clock speed and button bounce
          
          //// Registers for debouncing
          reg [16:0] debounce_counter;
          reg btn1_stable;
          reg btn1_last;

always @(posedge clk) begin
           // Check if button input has changed
              if (sig != btn1_last) begin
                  // If changed, reset the debounce counter
                  debounce_counter <= DEBOUNCE_MAX;
              end else if (debounce_counter > 0) begin
                  // Count down if button state is stable
                  debounce_counter <= debounce_counter - 1;
              end else begin
                  // Once stable, register button press only once
                  btn1_stable <= sig;
              end
              btn1_last <= sig; // Update last button state
          end
          


// Start of Frame (dominant 0)
reg SOF_BIT = 1'b0;
reg [3:0] next_state;
	
always @(posedge clk)
begin

  if (sig) begin
        rst_n <= 1'b1;
        data <= 64'hAABBCCDDEEFF0001;//
        id <= 11'b10000000001;
        send_frame <= 1'b1;
         led[0] <= 1'b1;
        dlc[3:0] <=4'b1000;
    end        
    else begin
        rst_n <= 1'b0;
         led[0] <= 1'b0;
        data <= 64'b0; // Reset data
        send_frame <= 1'b0;
     end   
end 

// State transition logic
always @ (posedge clk) begin: STATE_MEMORY
    if (!send_frame)
        current_state <= IDLE;
    else if (send_frame)
        current_state <= next_state;
end	

// Next state logic
always @(current_state or sending_frame or bit_counter or dlc or idle) 
begin: NEXT_STATE_LOGIC
    case (current_state)
        IDLE: 
                next_state = SOF;
        SOF: 
            if (send_frame && !idle)
                next_state = ID_STATE;
            else 
                next_state = SOF;
                
        ID_STATE: 
            if (sending_frame && bit_counter == 11)begin 
                next_state = RTR; 
                end
            else 
                next_state = ID_STATE;
        RTR: 
            if (sending_frame) 
                next_state = IDE; 
            else 
                next_state = RTR;
        IDE: 
            if (sending_frame) 
                next_state = R0; 
            else 
                next_state = IDE;
        R0:
            if (sending_frame) 
                next_state = DLC_STATE; 
            else 
                next_state = R0;
        DLC_STATE: 
            if (sending_frame && bit_counter == 4) 
                next_state = DATA_STATE; 
            else 
                next_state = DLC_STATE;
        DATA_STATE: 
            if (sending_frame && bit_counter == (dlc * 8)) 
                next_state = CRC_STATE; 
            else 
                next_state = DATA_STATE;
        CRC_STATE: 
            if (sending_frame && bit_counter == 15) 
                next_state = DEL1; 
            else 
                next_state = CRC_STATE;
        DEL1:
            if (sending_frame) 
                next_state = ACK_STATE; 
            else 
                next_state = DEL1;        
        ACK_STATE: 
            if (sending_frame) 
                next_state = DEL2; 
            else 
                next_state = ACK_STATE;
        DEL2:
            if (sending_frame) 
                next_state = EOF_STATE; 
            else 
                next_state = DEL2;
        EOF_STATE: 
            if (sending_frame && bit_counter == 6) begin
                next_state = IDLE; 
                end
            else 
                next_state = EOF_STATE;
        default: 
            next_state = IDLE;
    endcase
end	

// Output logic
always @ (posedge clk) 
begin: OUTPUT_LOGIC

    if (!rst_n) begin
        can_tx <= 1'b1;         // Idle state (recessive)
        sending_frame <= 1'b0;
        bit_counter <= 0;
        crc_reg <= 15'b0;
    end else begin
        case (current_state)
            IDLE: 
                if (send_frame && !sending_frame && idle) begin
                    sending_frame <= 1'b1;
                    idle<=1'b0;
                    can_tx <= SOF_BIT;    
                     end else begin
                        can_tx <= 1'b1;        
                end
            SOF: begin 
               can_tx <= id[10 - bit_counter];
               
               bit_counter <= bit_counter + 1;
            end
            ID_STATE: 
              begin
                can_tx <= id[10 - bit_counter];  // Transmit CAN ID
//                crc_reg <= nextCRC(can_tx, crc_reg);  // Update CRC
                bit_counter <= bit_counter + 1;
                if (bit_counter == 11) begin
                    can_tx <= 1'b0;
                    bit_counter <= 0;
                end        
              end
            RTR: 
              begin
                    // RTR and IDE both 0
                    can_tx <= 1'b0;
//                crc_reg <= nextCRC(can_tx, crc_reg);
            end
            IDE: 
            begin
                can_tx <= 1'b0;  // RTR and IDE both 0
//                crc_reg <= nextCRC(can_tx, crc_reg);
            end
            R0:
              begin
                can_tx <= dlc[3 - bit_counter];
                 bit_counter <= bit_counter + 1;
//                crc_reg <= nextCRC(can_tx, crc_reg);
            end
            DLC_STATE:
               begin
                can_tx <= dlc[3 - bit_counter];  // Transmit DLC
//                crc_reg <= nextCRC(can_tx, crc_reg);
                bit_counter <= bit_counter + 1;
                if (bit_counter == 4) begin
                    bit_counter <= 1;
                    can_tx <= data[63];
                end  
            end
            DATA_STATE: //7
              begin
                can_tx <= data[63-bit_counter];  // Transmit data bits
//                crc_reg <= nextCRC(can_tx, crc_reg);
                bit_counter <= bit_counter + 1;
                if (bit_counter == (dlc * 8))
                    bit_counter <= 0;
            end
            CRC_STATE: 
            begin
//                can_tx <= crc_reg[14 - bit_counter];  // Transmit CRC bits
                bit_counter <= bit_counter + 1;
                if (bit_counter == 15)
                    bit_counter <= 0;
            end
            DEL1: //9
             begin
                can_tx <= 1'b1; 
//                crc_reg <= nextCRC(can_tx, crc_reg);
            end
            ACK_STATE: 
                can_tx <= 1'b1;  // No ACK (ACK slot is recessive)
            
            DEL2:
            begin
                can_tx <= 1'b1;  
//                crc_reg <= nextCRC(can_tx, crc_reg);
            end
            EOF_STATE: //12 
            begin
                can_tx <= 1'b1;  // Transmit EOF (recessive bits)
                bit_counter <= bit_counter + 1;

                if (bit_counter == 6) begin
                    bit_counter <= 0;
                    sending_frame <= 0;
                    idle <=1'b1;
   
                end
            end
            default:
            can_tx <=1;
        endcase

  end  
end

// CRC calculation function
function [14:0] nextCRC;
    input new_bit;
    input [14:0] crc_in;
    begin
        // Basic linear-feedback shift register (LFSR) for CRC-15 calculation
        nextCRC[14] = crc_in[13] ^ new_bit;
        nextCRC[13] = crc_in[12] ^ crc_in[14] ^ new_bit;
        nextCRC[12] = crc_in[11];
        nextCRC[11] = crc_in[10] ^ crc_in[14] ^ new_bit;
        nextCRC[10] = crc_in[9];
        nextCRC[9]  = crc_in[8]  ^ crc_in[14] ^ new_bit;
        nextCRC[8]  = crc_in[7];
        nextCRC[7]  = crc_in[6];
        nextCRC[6]  = crc_in[5]  ^ crc_in[14] ^ new_bit;
        nextCRC[5]  = crc_in[4];
        nextCRC[4]  = crc_in[3]  ^ crc_in[14] ^ new_bit;
        nextCRC[3]  = crc_in[2];
        nextCRC[2]  = crc_in[1];
        nextCRC[1]  = crc_in[0]  ^ crc_in[14] ^ new_bit;
        nextCRC[0]  = new_bit;
    end
endfunction

endmodule
