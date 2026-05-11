`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 09:30:42 PM
// Design Name: 
// Module Name: design
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


module alu #(
parameter N=8)(
input wire CLK,
input wire RST,
input wire [1:0]INP_VALID,
input wire MODE,
input wire [3:0]CMD,
input wire CE,
input wire [N-1:0]OPA,
input wire [N-1:0]OPB,
input wire CIN,
output reg ERR,
output reg [(2*N)-1:0]RES,
output reg OFLOW,
output reg COUT,
output reg G,
output reg L,
output reg E
);

reg [1:0]count;
wire [N-1:0]diff=$signed(OPA_TEMP)-$signed(OPB_TEMP);
wire [N-1:0]sum=$signed(OPA_TEMP)+$signed(OPB_TEMP);
reg [N-1:0]OPA_TEMP,OPB_TEMP;
reg CIN_TEMP;
reg [3:0]CMD_TEMP;
reg MODE_TEMP;
reg [1:0]INP_VALID_TEMP;
reg [N-1:0] MUL_OPA, MUL_OPB;
reg BUSY;


always @(posedge CLK or posedge RST)
begin
    if (RST)
        count<=2'b00;
    else
    begin
        if (CMD_TEMP==4'd9||CMD_TEMP==4'd10)
        begin
            if (count==2'd1)
                count<=2'b00;
            else
                count<=count+1;
        end
        else
            count<=2'b00;
    end
end

always @(posedge CLK or posedge RST)
begin
    if(RST)
    begin
        OPA_TEMP<=0;
        OPB_TEMP<=0;
        CIN_TEMP<=0;
        CMD_TEMP<=0;
        MODE_TEMP<=0;
        INP_VALID_TEMP<=0;
        MUL_OPA<=0;
        MUL_OPB<=0;
        BUSY<=0;
        count<=0;
    end
    else if(CE)
    begin
        if(!BUSY && MODE &&(CMD==4'd9 || CMD==4'd10))
        begin
            BUSY<=1'b1;
            count<=0;
            MUL_OPA<=OPA;
            MUL_OPB<=OPB;
            CMD_TEMP<=CMD;
            MODE_TEMP<=MODE;
            INP_VALID_TEMP<=INP_VALID;
        end
        else if(BUSY)
        begin
            if(!(MODE && (CMD==4'd9 || CMD==4'd10)))
            begin
                BUSY<=1'b0;
                count<=0;
                OPA_TEMP<=OPA;
                OPB_TEMP<=OPB;
                CIN_TEMP<=CIN;
                CMD_TEMP<=CMD;
                MODE_TEMP<=MODE;
                INP_VALID_TEMP<=INP_VALID;
            end
            else
            begin
                count<=count+1;
                if(count == 2'd0)
                begin
                    BUSY<=1'b0;
                    OPA_TEMP<=OPA;
                    OPB_TEMP<=OPB;
                    CIN_TEMP<=CIN;
                    CMD_TEMP<=CMD;
                    MODE_TEMP<=MODE;
                    INP_VALID_TEMP<=INP_VALID;
                end
            end
        end
        else
        begin
            OPA_TEMP<=OPA;
            OPB_TEMP<=OPB;
            CIN_TEMP<=CIN;
            CMD_TEMP<=CMD;
            MODE_TEMP<=MODE;
            INP_VALID_TEMP<=INP_VALID;
        end
    end
end
always @(posedge CLK or posedge RST)
begin
    if(RST)
    begin
        RES<= {(2*N){1'b0}};
        ERR<= 1'b0;
        OFLOW<= 1'b0;
        COUT <= 1'b0;
        G <= 1'b0;
        L <= 1'b0;
        E <= 1'b0;
    end
    else if(!CE)
    begin
        RES <= RES;
        ERR <= ERR;
        OFLOW <= OFLOW;
        COUT <= COUT;
        G <= G;
        L <= L;
        E <= E;
    end
    else
    begin
        if(MODE_TEMP)
        begin
            case(CMD_TEMP)

            4'd0:
            begin
                if(INP_VALID_TEMP==2'b11)
                begin
                    RES <= OPA_TEMP + OPB_TEMP;
                    COUT <= ({1'b0,OPA_TEMP}+{1'b0,OPB_TEMP}) >> N;
                    OFLOW <= 1'b0;
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end
            
            4'd1:
            begin
                if(INP_VALID_TEMP==2'b11)
                begin
                    RES<={{N{1'b0}},OPA_TEMP - OPB_TEMP};
                    COUT<= (OPA_TEMP >= OPB_TEMP);
                    OFLOW<= !(OPA_TEMP >= OPB_TEMP);
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd2:
            begin
                if(INP_VALID_TEMP==2'b11)
                begin
                    RES <= OPA_TEMP + OPB_TEMP + CIN_TEMP;
                    COUT <= ({1'b0,OPA_TEMP}+{1'b0,OPB_TEMP}+CIN_TEMP) >> N;
                    OFLOW <= 1'b0;
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd3:
            begin
                if(INP_VALID_TEMP==2'b11)
                begin
                    RES <= {{N{1'b0}},OPA_TEMP - OPB_TEMP - CIN_TEMP};
                    COUT <= ({1'b0,OPA_TEMP} >= ({1'b0,OPB_TEMP}+CIN_TEMP));
                    OFLOW <= !({1'b0,OPA_TEMP} >= ({1'b0,OPB_TEMP}+CIN_TEMP));
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd4:
            begin
                if(INP_VALID_TEMP[0])
                begin
                    RES <= OPA_TEMP + 1;
                    COUT <= ({1'b0,OPA_TEMP}+1'b1) >> N;
                    OFLOW <= 1'b0;
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd5:
            begin
                if(INP_VALID_TEMP[0])
                begin
                    RES <= {{N{1'b0}},OPA_TEMP - 1};
                    COUT <= 1'b0;
                    OFLOW <= (OPA_TEMP == 0);
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd6:
            begin
                if(INP_VALID_TEMP[1])
                begin
                    RES <= OPB_TEMP + 1;
                    COUT <= ({1'b0,OPB_TEMP}+1'b1) >> N;
                    OFLOW <= 1'b0;
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd7:
            begin
                if(INP_VALID_TEMP[1])
                begin
                    RES <= {{N{1'b0}},OPB_TEMP - 1};
                    COUT <= 1'b0;
                    OFLOW <= (OPB_TEMP == 0);
                    {ERR,G,L,E} <= 4'b0000;
                end
                else
                    ERR <= 1'b1;
            end

            4'd8:
            begin
                if(INP_VALID_TEMP==2'b11)
                begin
                    RES <= {(2*N){1'b0}};
                    {ERR,COUT,OFLOW} <= 3'b000;
                    {G,L,E} <= {(OPA_TEMP>OPB_TEMP),(OPA_TEMP<OPB_TEMP),(OPA_TEMP==OPB_TEMP)};
                end
                else
                    ERR <= 1'b1;
            end

            4'd9:
            begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES <= (count==2'd1) ?((MUL_OPA+1)*(MUL_OPB+1)) :RES;
                {ERR,COUT,OFLOW,G,L,E} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
            end 

            4'd10:
            begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES <= (count==2'd1) ? (((MUL_OPA<<1)+1)*(MUL_OPB+1)):RES;
                {ERR,COUT,OFLOW,G,L,E} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
            end
            
            4'd11:
            begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES <= $signed(OPA_TEMP) + $signed(OPB_TEMP);
                COUT <= RES[N-1];
                OFLOW <= (OPA_TEMP[N-1] == OPB_TEMP[N-1]) &&(sum[N-1] != OPA_TEMP[N-1]);
                G <= ($signed(OPA_TEMP) > $signed(OPB_TEMP));
                L <= ($signed(OPA_TEMP) < $signed(OPB_TEMP));
                E <= (OPA_TEMP == OPB_TEMP);
                ERR <= 1'b0;
            end 
            else
                ERR <= 1'b1;
            end
            
            4'd12:
            begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES <= $signed(OPA_TEMP) - $signed(OPB_TEMP);
                COUT <= RES[N-1];
                OFLOW <= (OPA_TEMP[N-1] != OPB_TEMP[N-1]) &&(diff[N-1] != OPA_TEMP[N-1]);
                G <= ($signed(OPA_TEMP) > $signed(OPB_TEMP));
                L <= ($signed(OPA_TEMP) < $signed(OPB_TEMP));
                E <= (OPA_TEMP == OPB_TEMP);
        
                ERR <= 1'b0;
            end
            else
                ERR <= 1'b1;
            end 

            endcase
        end
        else
        begin
        case(CMD_TEMP)
        4'd0:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES[N-1:0] <= (OPA_TEMP & OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
    
        4'd1:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES[N-1:0] <= ~(OPA_TEMP & OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd2:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES[N-1:0] <= (OPA_TEMP | OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd3:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES[N-1:0] <= ~(OPA_TEMP | OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd4:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES[N-1:0] <= (OPA_TEMP ^ OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd5:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                RES[N-1:0] <= ~(OPA_TEMP ^ OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd6:
        begin
            if(INP_VALID_TEMP[0])
            begin
                RES[N-1:0] <= ~(OPA_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd7:
        begin
            if(INP_VALID_TEMP[1])
            begin
                RES[N-1:0] <= ~(OPB_TEMP);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd8:
        begin
            if(INP_VALID_TEMP[0])
            begin
                RES[N-1:0] <= (OPA_TEMP >> 1);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd9:
        begin
            if(INP_VALID_TEMP[0])
            begin
                RES[N-1:0] <= (OPA_TEMP << 1);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd10:
        begin
            if(INP_VALID_TEMP[1])
            begin
                RES[N-1:0] <= (OPB_TEMP >> 1);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd11:
        begin
            if(INP_VALID_TEMP[1])
            begin
                RES[N-1:0] <= (OPB_TEMP << 1);
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
            else
                ERR <= 1'b1;
        end
        
        4'd12:
        begin
        if(INP_VALID_TEMP==2'b11)
        begin
            if(OPB_TEMP[7:4] != 4'b0000)
            begin
                ERR <= 1'b1;
            end
            else
            begin
                case(OPB_TEMP[2:0])
                    3'd0: RES[N-1:0] <= OPA_TEMP;
                    3'd1: RES[N-1:0] <= {OPA_TEMP[N-2:0], OPA_TEMP[N-1]};
                    3'd2: RES[N-1:0] <= {OPA_TEMP[N-3:0], OPA_TEMP[N-1:N-2]};
                    3'd3: RES[N-1:0] <= {OPA_TEMP[N-4:0], OPA_TEMP[N-1:N-3]};
                    3'd4: RES[N-1:0] <= {OPA_TEMP[N-5:0], OPA_TEMP[N-1:N-4]};
                    3'd5: RES[N-1:0] <= {OPA_TEMP[N-6:0], OPA_TEMP[N-1:N-5]};
                    3'd6: RES[N-1:0] <= {OPA_TEMP[N-7:0], OPA_TEMP[N-1:N-6]};
                    3'd7: RES[N-1:0] <= {OPA_TEMP[N-8:0], OPA_TEMP[N-1:N-7]};
                endcase
                {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
            end
        end
        else
            ERR <= 1'b1;
        end
    
        4'd13:
        begin
            if(INP_VALID_TEMP==2'b11)
            begin
                if(OPB_TEMP[7:4] != 4'b0000)
                begin
                    ERR <= 1'b1;
                end
                else
                begin
                    case(OPB_TEMP[2:0])
                        3'd0: RES[N-1:0] <= OPA_TEMP;
                        3'd1: RES[N-1:0] <= {OPA_TEMP[0], OPA_TEMP[N-1:1]};
                        3'd2: RES[N-1:0] <= {OPA_TEMP[1:0], OPA_TEMP[N-1:2]};
                        3'd3: RES[N-1:0] <= {OPA_TEMP[2:0], OPA_TEMP[N-1:3]};
                        3'd4: RES[N-1:0] <= {OPA_TEMP[3:0], OPA_TEMP[N-1:4]};
                        3'd5: RES[N-1:0] <= {OPA_TEMP[4:0], OPA_TEMP[N-1:5]};
                        3'd6: RES[N-1:0] <= {OPA_TEMP[5:0], OPA_TEMP[N-1:6]};
                        3'd7: RES[N-1:0] <= {OPA_TEMP[6:0], OPA_TEMP[N-1:7]};
                    endcase
                    {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
                end
            end
            else
                ERR <= 1'b1;
        end 
    
        default:
        begin
            RES[N-1:0] <= {(2*N){1'b0}};
            {ERR,G,L,E,COUT,OFLOW} <= 6'b000000;
        end
        endcase
    end
    end
end
endmodule

