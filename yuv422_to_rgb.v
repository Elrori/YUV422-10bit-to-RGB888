/***********************************************************************************\
*   Name    :3GSDI(1080P60)-yuv422 to rgb888,
*            10bit 3G-SDI YUV422 input, 4 to 1019 (00416 to 3FB16) inclusive,
*            0–3 and 1020–1023 (3FC16–3FF16) are reserved and may not appear anywhere in the payload.
*            R = 1.164(Y−16)+1.596(V−128)
*            G = 1.164(Y−16)−0.813(V−128)−0.391(U−128)
*            B = 1.164(Y−16)+2.018(U−128)
*            RGB range [0,255],Y range [16,235],UV range [16,239]
*   Origin  :210427
*   Author  :helrori2011@gmail.com
*   Reference:
\***********************************************************************************/
module yuv422_to_rgb
(
    input       wire        clk     ,
    input       wire        cke     ,

    input       wire        yuv_hs  ,
    input       wire        yuv_vs  ,
    input       wire        yuv_de  ,
    input       wire [9 :0] yuv_y   ,
    input       wire [9 :0] yuv_c   ,

    output      wire        rgb_hs  ,
    output      wire        rgb_vs  ,
    output      wire        rgb_de  ,
    output      wire [23:0] rgb_dat
);
/*************************************************************************\
*
*   YUV422 to YUV444
*
\*************************************************************************/
reg        cr         = 1'd0;
reg [1 :0] sft_hs     = 'd0;
reg [1 :0] sft_vs     = 'd0;
reg [1 :0] sft_de     = 'd0;
reg [9 :0] yuv_y_r    = 'd0;

wire       yuv444_hs  = sft_hs[1];
wire       yuv444_vs  = sft_vs[1];
wire       yuv444_de  = sft_de[1];
reg [9 :0] yuv444_y   = 'd0;
reg [9 :0] yuv444_cb  = 'd0;
reg [9 :0] yuv444_cr  = 'd0;
always @(posedge clk) begin
    if (cke) begin
        yuv_y_r   <= yuv_y;
        yuv444_y  <= yuv_y_r;
        sft_hs    <= {sft_hs, yuv_hs};
        sft_vs    <= {sft_vs, yuv_vs};
        sft_de    <= {sft_de, yuv_de};
    end
end
always @(posedge clk) begin
    if(cke)begin
        if (yuv_de) begin
            cr <= ~cr;
        end else begin
            cr <= 1'd0;
        end
    end
end
reg signed [9:0]buffer_cb='d0;
always @(posedge clk) begin
    if(cke&&yuv_de)begin
        if (cr==0) begin
            buffer_cb <= yuv_c;
        end else begin
            yuv444_cb <= buffer_cb;
            yuv444_cr <= yuv_c;
        end
    end
end
/*************************************************************************\
*
*   YUV444 to RGB888
*
\*************************************************************************/
wire        [7 :0] yuv444_8b_y   =  (yuv444_y[9:2] < 16 )?16  :
                                    (yuv444_y[9:2] > 235)?235 :
                                     yuv444_y[9:2];
wire        [7 :0] yuv444_8b_cb  =  (yuv444_cb[9:2] < 16 )?16 :
                                    (yuv444_cb[9:2] > 239)?239:
                                     yuv444_cb[9:2];      
wire        [7 :0] yuv444_8b_cr  =  (yuv444_cr[9:2] < 16 )?16 :
                                    (yuv444_cr[9:2] > 239)?239:
                                     yuv444_cr[9:2];  


reg signed [8 :0]y_coe=0;
reg signed [8 :0]u_coe=0;
reg signed [8 :0]v_coe=0;
reg signed [19:0]rgb_int0=0;
reg signed [19:0]rgb_int1=0;
reg signed [19:0]rgb_int2=0;
reg signed [19:0]rgb_int3=0;
reg signed [19:0]rgb_int4=0;
reg signed [19:0]rgb_b=0;
reg signed [19:0]rgb_g=0;
reg signed [19:0]rgb_r=0;

wire signed[9:0]rgb_b_cut=rgb_b>>10;
wire signed[9:0]rgb_g_cut=rgb_g>>10;
wire signed[9:0]rgb_r_cut=rgb_r>>10;

reg signed [7 :0]rgb_8b_b=0;
reg signed [7 :0]rgb_8b_g=0;
reg signed [7 :0]rgb_8b_r=0;

reg        [3:0]sft_yuv444_hs  = 'd0;
reg        [3:0]sft_yuv444_vs  = 'd0;
reg        [3:0]sft_yuv444_de  = 'd0;
assign rgb_hs = sft_yuv444_hs[3];
assign rgb_vs = sft_yuv444_vs[3];
assign rgb_de = sft_yuv444_de[3];
assign rgb_dat = {rgb_8b_r,rgb_8b_g,rgb_8b_b};



always @(posedge clk) begin
    if (cke) begin
        y_coe <= yuv444_8b_y  -  16;
        u_coe <= yuv444_8b_cb - 128;
        v_coe <= yuv444_8b_cr - 128;

        // rgb_r <= 1192*y_coe + 1634*v_coe;
        // rgb_g <= 1192*y_coe -  833*v_coe - 400*u_coe ;
        // rgb_b <= 1192*y_coe + 2066*u_coe;
        rgb_int0 <= 1192*y_coe;
        rgb_int1 <= 1634*v_coe;
        rgb_int2 <= 833 *v_coe;
        rgb_int3 <= 400 *u_coe;
        rgb_int4 <= 2066*u_coe;
        rgb_r    <= rgb_int0 + rgb_int1;
        rgb_g    <= rgb_int0 - rgb_int2 - rgb_int3;
        rgb_b    <= rgb_int0 + rgb_int4;

        rgb_8b_b <= (rgb_b_cut>255)?255:
                    (rgb_b_cut<  0)?0  :
                     rgb_b_cut[7:0];
        rgb_8b_g <= (rgb_g_cut>255)?255:
                    (rgb_g_cut<  0)?0  :
                     rgb_g_cut[7:0];
        rgb_8b_r <= (rgb_r_cut>255)?255:
                    (rgb_r_cut<  0)?0  :
                     rgb_r_cut[7:0];

        sft_yuv444_hs <= {sft_yuv444_hs,yuv444_hs};
        sft_yuv444_vs <= {sft_yuv444_vs,yuv444_vs};
        sft_yuv444_de <= {sft_yuv444_de,yuv444_de};
    end
end

endmodule
