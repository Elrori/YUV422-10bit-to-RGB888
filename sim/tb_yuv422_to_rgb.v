//~ `New testbench
`timescale  1ns / 1ps

module tb_yuv422_to_rgb;

// yuv422_to_rgb Parameters
parameter PERIOD  = 10;
parameter ROW = 297;
parameter COLUMN = 678;
// yuv422_to_rgb Inputs
reg   clk                                  = 0 ;
reg   cke                                  = 0 ;
reg   yuv_hs                               = 0 ;
reg   yuv_vs                               = 0 ;
reg   yuv_de                               = 0 ;
reg   [9 :0]  yuv_y                        = 0 ;
reg   [9 :0]  yuv_c                        = 0 ;

// yuv422_to_rgb Outputs
wire  rgb_hs                               ;
wire  rgb_vs                               ;
wire  rgb_de                               ;
wire  [23:0]  rgb_dat                      ;
wire [7:0]rgb_r = rgb_dat[23:16];
wire [7:0]rgb_g = rgb_dat[15:8];
wire [7:0]rgb_b = rgb_dat[7:0];

always #(PERIOD/2)  clk=~clk;
always @(posedge clk)  cke<=~cke;



yuv422_to_rgb  u_yuv422_to_rgb (
    .clk                     ( clk             ),
    .cke                     ( 1             ),

    .yuv_hs                  ( yuv_hs          ),
    .yuv_vs                  ( yuv_vs          ),
    .yuv_de                  ( yuv_de          ),
    .yuv_y                   ( yuv_y    [9 :0] ),
    .yuv_c                   ( yuv_c    [9 :0] ),

    .rgb_hs                  ( rgb_hs          ),
    .rgb_vs                  ( rgb_vs          ),
    .rgb_de                  ( rgb_de          ),
    .rgb_dat                 ( rgb_dat  [23:0] )
);

// YUV444
reg [7:0]mem_y[0:ROW*COLUMN-1];
reg [7:0]mem_u[0:ROW*COLUMN-1];
reg [7:0]mem_v[0:ROW*COLUMN-1];
// YUV422
reg [9:0]sou_y[0:ROW*COLUMN-1];
reg [9:0]sou_uv[0:ROW*COLUMN-1];

reg [9:0]buff;
integer i;
integer x;
integer y;


integer fr;
integer fg;
integer fb;
always @(posedge clk) begin
    if (rgb_de) begin
        $fwrite(fr,"%x\n",rgb_r);
        $fwrite(fg,"%x\n",rgb_g);
        $fwrite(fb,"%x\n",rgb_b);
    end
end
initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0,tb_yuv422_to_rgb);
    $readmemh("./yuv_source/y.txt",mem_y);
    $readmemh("./yuv_source/u.txt",mem_u);
    $readmemh("./yuv_source/v.txt",mem_v);
    fr=$fopen("./rgb_recover/r.txt","w");
    fg=$fopen("./rgb_recover/g.txt","w");
    fb=$fopen("./rgb_recover/b.txt","w");

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    // YUV444 to YUV422
    for (i = 0;i<ROW*COLUMN;i=i+1 ) begin
        sou_y[i]=mem_y[i]<<2;
        if (i%2==0) begin
            sou_uv[i]=mem_u[i]<<2;
            buff=mem_v[i]<<2;
        end else begin
            sou_uv[i]=buff;
        end
        if (i<100) begin
            $display("sou_y[%0d]%0d sou_uv[%0d]%0d",i,sou_y[i],i,sou_uv[i]);
        end
        
    end

    for (x = 0;x<ROW;x=x+1 ) begin
        for (y = 0;y<COLUMN;y=y+1 ) begin
            @(posedge clk);
            if (1) begin
                #0 yuv_de=1;
                yuv_y=sou_y[x*COLUMN+y];
                yuv_c=sou_uv[x*COLUMN+y];
            end          
        end
        @(posedge clk);
        #0 yuv_de=0;
        @(posedge clk);
        @(posedge clk);
    end

    wait(rgb_de==0);
    $fclose(fr);
    $fclose(fg);
    $fclose(fb);
    $finish;
end

endmodule