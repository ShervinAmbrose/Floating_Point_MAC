`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2021 11:02:09 AM
// Design Name: 
// Module Name: fp_mac
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


module fp_mac(
    input clk42,rst42, //clock and reset
    input [15:0] A42,B42, //A and B inputs
    output [15:0] acc42 //FP accumulated output
    );
    wire sign42; //stores sign
    reg [15:0] prod42; //stores FP product
    reg [4:0] expoA42;  //Exponent of A
    reg [4:0] expoB42;  //Exponent of B
    reg [4:0] expo42;   //Final Exponent
    reg [10:0] sigA42;  //Significant of A
    reg [10:0] sigB42;  //Significant of B
    reg [20:0] sig42;   // Final Significant
    //Shift registers for multiplication
    reg [15:0] mul42;
    reg [15:0] mul2_42;
    reg [15:0] mul3_42;
    

    reg [10:0] shiftacc42;
    reg [10:0] shiftprod42;

    reg [2:0] pstate42, nstate42; //present state and next state
    
    //Flags
    reg sigDone42;
    reg expoDone42;
    reg manDone42;
    reg sigprodDone42;
    reg signaccDone42;
    reg signreslDone42;
    reg accsignDone42;
    
    parameter s0=4'b0000, s1=4'b0001, s2=4'b0010, s3=4'b0011;
    parameter s4=4'b0100, s5=4'b0101;
 
     
     always @(posedge clk42 or posedge rst42) begin
        if (rst42) pstate42 = s0;
        else pstate42 = nstate42;
      end
      
      always @(pstate42 or sigDone42 or expoDone42 or manDone42 or accsignDone42) begin  //state transition
        case (pstate42)
        s0:  if(rst42) nstate42 = s1;
        s1:  if(sigDone42) nstate42 <= s2;
        s2:  if (expoDone42 == 1'b1) nstate42 = s3;
        s3:  if (manDone42) nstate42 = s4; 
        s4:  if (accsignDone42) nstate42 = s5;
        s5:  nstate42 = s0;
        endcase
        end    

      always @(pstate42) begin  //Output based on state transition
        case (pstate42)
            s0:  begin  //reset
                  sigDone42 = 1'b0; 
                  expoDone42 = 1'b0; 
                  manDone42 = 1'b0;
                  sigprodDone42 = 1'b0;
                  accsignDone42 = 1'b0;
                  
            end
            s1:  begin  //Sign
                    mul42[15] = A42[15] ^ B42[15]; 
                    sigDone42 = 1'b1;
            end
            s2:  begin  //Exponent
                    expoA42 = 15 - A42[14:10]; //exponent of A42
                    expoB42 = 15 - B42[14:10]; // exponent of B42
                    mul42[14:10] = 15 - (expoA42 + expoB42); //Mantissa added to the product
                    mul2_42[15] = mul42[15];
                    expoDone42 = 1'b1;
            end
            s3:  begin  //Significant
                    sigA42 = {1'b1, A42[9:0]}; //Manitissa of A42
                    sigB42 = {1'b1, B42[9:0]}; // Mantissa of B42
                    sig42 = sigA42 * sigB42;
                    mul42 [9:0] = sig42[20:10]; //significant added to the product
                    mul3_42 [15] = mul2_42[15];
                    mul2_42[14:10] = mul42[14:10];
                    manDone42 = 1'b1;
            end
            s4:  begin //Sign of FP addition
                    prod42[15] = mul3_42[15];
                    prod42[14:10] = mul2_42[14:10];
                    prod42[9:0] = mul42[9:0];
                    accsignDone42 = 1'b1;            
            end
            s5:  begin //Significant and exponent of FP addition
                    if (prod42[14:10] > acc42[14:10]) begin
                        shiftacc42 = {1'b1, acc42[9:0]};
                        if ((prod42[14:10] - acc42[14:10]) == 2) shiftacc42 = {1'b0, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 3) shiftacc42 = {2'b00, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 4) shiftacc42 = {3'b000, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 5) shiftacc42 = {4'b0000, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 6) shiftacc42 = {5'b00000, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 7) shiftacc42 = {6'b000000, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 8) shiftacc42 = {7'b0000000, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 9) shiftacc42 = {8'b00000000, acc42[9:0]};
                        else if ((prod42[14:10] - acc42[14:10]) == 10) shiftacc42 = {9'b000000000, acc42[9:0]};                                  
                    end
                    else if (prod42[14:10] < acc42[14:10]) begin
                        shiftprod42 = {1'b1, prod42[9:0]};
                        if ((acc42[14:10] - prod42[14:10]) == 2) shiftprod42 = {1'b0, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 3) shiftprod42 = {2'b00, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 4) shiftprod42 = {3'b000, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 5) shiftprod42 = {4'b0000, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 6) shiftprod42 = {5'b00000, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 7) shiftprod42 = {6'b000000, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 8) shiftprod42 = {7'b0000000, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 9) shiftprod42 = {8'b00000000, prod42[9:0]};
                        else if ((acc42[14:10] - prod42[14:10]) == 10) shiftprod42 = {9'b00000000, prod42[9:0]};                                               
                    end
              end             
     endcase 
  end 
endmodule
