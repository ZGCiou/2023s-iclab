//CC.v
module CC(
	in_s0,
	in_s1, 
	in_s2, 
	in_s3, 
	in_s4, 
	in_s5,
	in_s6,
	opt,
	a,
	b,
	s_id0,
	s_id1,
	s_id2,
	s_id3,
	s_id4,
	s_id5,
	s_id6,
	out
);
input [3:0] in_s0;
input [3:0] in_s1;
input [3:0] in_s2;
input [3:0] in_s3;
input [3:0] in_s4;
input [3:0] in_s5;
input [3:0] in_s6;
input [2:0] opt;
input [1:0] a;
input [2:0] b;
output [2:0] s_id0;
output [2:0] s_id1;
output [2:0] s_id2;
output [2:0] s_id3;
output [2:0] s_id4;
output [2:0] s_id5;
output [2:0] s_id6;
output [2:0] out;
//==================================================================
// reg & wire
//==================================================================
wire signed [4:0] in_s0_se, in_s1_se, in_s2_se, in_s3_se, in_s4_se, in_s5_se, in_s6_se;
wire se0, se1, se2, se3, se4, se5, se6;
reg id0, id1, id2, id3, id4, id5, id6;
wire signed [7:0] s0_lt, s1_lt, s2_lt, s3_lt, s4_lt, s5_lt, s6_lt;
wire signed [7:0] sum, avg;
wire signed [4:0] pass;
reg count0, count1, count2, count3, count4, count5, count6;
wire signed [5:0]s1, s2, s3;
wire signed [6:0]s4, s5;
//==================================================================
// design
//==================================================================
//Signed/Unsigned
assign se0 = (opt[0]) ? in_s0[3] : 1'b0;
assign se1 = (opt[0]) ? in_s1[3] : 1'b0;
assign se2 = (opt[0]) ? in_s2[3] : 1'b0;
assign se3 = (opt[0]) ? in_s3[3] : 1'b0;
assign se4 = (opt[0]) ? in_s4[3] : 1'b0;
assign se5 = (opt[0]) ? in_s5[3] : 1'b0;
assign se6 = (opt[0]) ? in_s6[3] : 1'b0;

assign in_s0_se = {se0, in_s0};
assign in_s1_se = {se1, in_s1};
assign in_s2_se = {se2, in_s2};
assign in_s3_se = {se3, in_s3};
assign in_s4_se = {se4, in_s4};
assign in_s5_se = {se5, in_s5};
assign in_s6_se = {se6, in_s6};

//Sort
Sort sort(
.in0(in_s0_se), .in1(in_s1_se), .in2(in_s2_se), .in3(in_s3_se), .in4(in_s4_se), .in5(in_s5_se), .in6(in_s6_se), .btos(opt[1]),
.id0(s_id0), .id1(s_id1), .id2(s_id2), .id3(s_id3), .id4(s_id4), .id5(s_id5), .id6(s_id6));

//Calculate
assign s1 = in_s0_se + in_s1_se;
assign s2 = in_s2_se + in_s3_se;
assign s3 = in_s4_se + in_s5_se;
assign s4 = s1 + s2 ;
assign s5 = s3 + in_s6_se;
assign sum = s4 + s5;
//assign sum = in_s0_se + in_s1_se + in_s2_se + in_s3_se + in_s4_se + in_s5_se + in_s6_se;
assign avg = sum / $signed(4'd7);
assign pass = avg[4:0] - $signed({2'd0, a});

//Linear transformation
Lt lt0(.score(in_s0_se), .a(a), .b(b), .newscore(s0_lt));
Lt lt1(.score(in_s1_se), .a(a), .b(b), .newscore(s1_lt));
Lt lt2(.score(in_s2_se), .a(a), .b(b), .newscore(s2_lt));
Lt lt3(.score(in_s3_se), .a(a), .b(b), .newscore(s3_lt));
Lt lt4(.score(in_s4_se), .a(a), .b(b), .newscore(s4_lt));
Lt lt5(.score(in_s5_se), .a(a), .b(b), .newscore(s5_lt));
Lt lt6(.score(in_s6_se), .a(a), .b(b), .newscore(s6_lt));


//Count
always @* begin
	if (opt[2]) begin
		count0 <= (s0_lt < pass) ? 1'b1 : 1'b0;
		count1 <= (s1_lt < pass) ? 1'b1 : 1'b0;
		count2 <= (s2_lt < pass) ? 1'b1 : 1'b0;
		count3 <= (s3_lt < pass) ? 1'b1 : 1'b0;
		count4 <= (s4_lt < pass) ? 1'b1 : 1'b0;
		count5 <= (s5_lt < pass) ? 1'b1 : 1'b0;
		count6 <= (s6_lt < pass) ? 1'b1 : 1'b0;
	end
	else begin
		count0 <= (s0_lt < pass) ? 1'b0 : 1'b1;
		count1 <= (s1_lt < pass) ? 1'b0 : 1'b1;
		count2 <= (s2_lt < pass) ? 1'b0 : 1'b1;
		count3 <= (s3_lt < pass) ? 1'b0 : 1'b1;
		count4 <= (s4_lt < pass) ? 1'b0 : 1'b1;
		count5 <= (s5_lt < pass) ? 1'b0 : 1'b1;
		count6 <= (s6_lt < pass) ? 1'b0 : 1'b1;
	end
end
assign out = count0 + count1 + count2 + count3 + count4 + count5 + count6;

endmodule

//Sub Module
/*
module Sort(
	//input
	in0, in1, in2, in3, in4, in5, in6, btos,
	//output
	id0, id1, id2, id3, id4, id5, id6
	);
input [4:0] in0;
input [4:0] in1;
input [4:0] in2;
input [4:0] in3;
input [4:0] in4;
input [4:0] in5;
input [4:0] in6;
input btos;
output [2:0] id0;
output [2:0] id1;
output [2:0] id2;
output [2:0] id3;
output [2:0] id4;
output [2:0] id5;
output [2:0] id6;

//Wire
wire [7:0] id_in0, id_in1, id_in2, id_in3, id_in4, id_in5, id_in6;
wire [7:0] a[1:0], b[1:0], c[1:0], d[1:0], e[1:0], f[1:0], g[1:0], h[1:0], i[1:0], j[1:0], k[1:0], l[1:0], m[1:0], n[1:0], o[1:0], p[1:0];


//Design
assign id_in0 = {3'd0, in0};
assign id_in1 = {3'd1, in1};
assign id_in2 = {3'd2, in2};
assign id_in3 = {3'd3, in3};
assign id_in4 = {3'd4, in4};
assign id_in5 = {3'd5, in5};
assign id_in6 = {3'd6, in6};

Com A(.a(id_in0), .b(id_in1), .big(a[1]), .sml(a[0]), .bts(btos));
Com B(.a(id_in2), .b(id_in3), .big(b[1]), .sml(b[0]), .bts(btos));
Com C(.a(id_in4), .b(id_in5), .big(c[1]), .sml(c[0]), .bts(btos));
Com D(.a(a[1]), .b(b[1]), .big(d[1]), .sml(d[0]), .bts(btos));
Com E(.a(a[0]), .b(b[0]), .big(e[1]), .sml(e[0]), .bts(btos));
Com F(.a(c[1]), .b(id_in6), .big(f[1]), .sml(f[0]), .bts(btos));
Com G(.a(d[0]), .b(e[1]), .big(g[1]), .sml(g[0]), .bts(btos));
Com H(.a(c[0]), .b(f[0]), .big(h[1]), .sml(h[0]), .bts(btos));
Com I(.a(d[1]), .b(f[1]), .big(i[1]), .sml(i[0]), .bts(btos));
Com J(.a(e[0]), .b(h[0]), .big(j[1]), .sml(j[0]), .bts(btos));
Com K(.a(g[0]), .b(h[1]), .big(k[1]), .sml(k[0]), .bts(btos));
Com L(.a(g[1]), .b(k[1]), .big(l[1]), .sml(l[0]), .bts(btos));
Com M(.a(i[0]), .b(l[1]), .big(m[1]), .sml(m[0]), .bts(btos));
Com N(.a(k[0]), .b(j[1]), .big(n[1]), .sml(n[0]), .bts(btos));
Com O(.a(m[0]), .b(l[0]), .big(o[1]), .sml(o[0]), .bts(btos));
Com P(.a(o[0]), .b(n[1]), .big(p[1]), .sml(p[0]), .bts(btos));

assign id0 = (btos) ? i[1][7:5] : j[0][7:5];
assign id1 = (btos) ? m[1][7:5] : n[0][7:5];
assign id2 = (btos) ? o[1][7:5] : p[0][7:5];
assign id3 = p[1][7:5];
assign id4 = (btos) ? p[0][7:5] : o[1][7:5];
assign id5 = (btos) ? n[0][7:5] : m[1][7:5];
assign id6 = (btos) ? j[0][7:5] : i[1][7:5];
*/

module Sort(
	//input
	in0, in1, in2, in3, in4, in5, in6, btos,
	//output
	id0, id1, id2, id3, id4, id5, id6
);
input [4:0] in0;
input [4:0] in1;
input [4:0] in2;
input [4:0] in3;
input [4:0] in4;
input [4:0] in5;
input [4:0] in6;
input btos;
output [2:0] id0;
output [2:0] id1;
output [2:0] id2;
output [2:0] id3;
output [2:0] id4;
output [2:0] id5;
output [2:0] id6;

//Wire
wire [7:0] id_in0, id_in1, id_in2, id_in3, id_in4, id_in5, id_in6;
wire [7:0] r11[1:0], r12[1:0], r13[1:0];
wire [7:0] r21[1:0], r22[1:0], r23[1:0];
wire [7:0] r31[1:0], r32[1:0], r33[1:0];
wire [7:0] r41[1:0], r42[1:0], r43[1:0];
wire [7:0] r51[1:0], r52[1:0], r53[1:0];
wire [7:0] r61[1:0], r62[1:0], r63[1:0];
wire [7:0] r71[1:0], r72[1:0], r73[1:0];

//Design
assign id_in0 = {3'd0, in0};
assign id_in1 = {3'd1, in1};
assign id_in2 = {3'd2, in2};
assign id_in3 = {3'd3, in3};
assign id_in4 = {3'd4, in4};
assign id_in5 = {3'd5, in5};
assign id_in6 = {3'd6, in6};

Com R11(.a(id_in0), .b(id_in1), .big(r11[1]), .sml(r11[0]), .bts(btos));
Com R12(.a(id_in2), .b(id_in3), .big(r12[1]), .sml(r12[0]), .bts(btos));
Com R13(.a(id_in4), .b(id_in5), .big(r13[1]), .sml(r13[0]), .bts(btos));
Com R21(.a(r11[0]), .b(r12[1]), .big(r21[1]), .sml(r21[0]), .bts(btos));
Com R22(.a(r12[0]), .b(r13[1]), .big(r22[1]), .sml(r22[0]), .bts(btos));
Com R23(.a(r13[0]), .b(id_in6), .big(r23[1]), .sml(r23[0]), .bts(btos));
Com R31(.a(r11[1]), .b(r21[1]), .big(r31[1]), .sml(r31[0]), .bts(btos));
Com R32(.a(r21[0]), .b(r22[1]), .big(r32[1]), .sml(r32[0]), .bts(btos));
Com R33(.a(r22[0]), .b(r23[1]), .big(r33[1]), .sml(r33[0]), .bts(btos));
Com R41(.a(r31[0]), .b(r32[1]), .big(r41[1]), .sml(r41[0]), .bts(btos));
Com R42(.a(r32[0]), .b(r33[1]), .big(r42[1]), .sml(r42[0]), .bts(btos));
Com R43(.a(r33[0]), .b(r23[0]), .big(r43[1]), .sml(r43[0]), .bts(btos));
Com R51(.a(r31[1]), .b(r41[1]), .big(r51[1]), .sml(r51[0]), .bts(btos));
Com R52(.a(r41[0]), .b(r42[1]), .big(r52[1]), .sml(r52[0]), .bts(btos));
Com R53(.a(r42[0]), .b(r43[1]), .big(r53[1]), .sml(r53[0]), .bts(btos));
Com R61(.a(r51[0]), .b(r52[1]), .big(r61[1]), .sml(r61[0]), .bts(btos));
Com R62(.a(r52[0]), .b(r53[1]), .big(r62[1]), .sml(r62[0]), .bts(btos));
Com R63(.a(r53[0]), .b(r43[0]), .big(r63[1]), .sml(r63[0]), .bts(btos));
Com R71(.a(r51[1]), .b(r61[1]), .big(r71[1]), .sml(r71[0]), .bts(btos));
Com R72(.a(r61[0]), .b(r62[1]), .big(r72[1]), .sml(r72[0]), .bts(btos));
Com R73(.a(r62[0]), .b(r63[1]), .big(r73[1]), .sml(r73[0]), .bts(btos));

assign id0 = r71[1][7:5];
assign id1 = r71[0][7:5];
assign id2 = r72[1][7:5];
assign id3 = r72[0][7:5];
assign id4 = r73[1][7:5];
assign id5 = r73[0][7:5];
assign id6 = r63[0][7:5];

endmodule

module Com(
	//input
	a, b, bts,
	//output
	big, sml
);
input [7:0] a, b;
input bts;
output reg [7:0] big, sml;

always @* begin
	if (a[3:0] == b[3:0]) begin
		big <= a;
		sml <= b;
	end
	else if ($signed(a[4:0]) < $signed(b[4:0])) begin
		big <= (bts) ? b : a;
		sml <= (bts) ? a : b;
	end
	else begin
		big <= (bts) ? a : b;
		sml <= (bts) ? b : a;
	end
end

endmodule

/*
module Com(
	//input
	a, b, bts,
	//output
	big, sml
);
input [7:0] a, b;
input bts;
output reg [7:0] big, sml;

always @* begin
	if ($signed(a[4:0]) > $signed(b[4:0])) begin
		big = a;
		sml = b;
	end
	else if ($signed(a[4:0]) < $signed(b[4:0])) begin
		big = b;
		sml = a;
	end
	
	else begin
		if (bts) begin
			big = (a[7:5] < b[7:5]) ? a : b;
			sml = (a[7:5] < b[7:5]) ? b : a;
		end
		else begin
			big = (a[7:5] > b[7:5]) ? a : b;
			sml = (a[7:5] > b[7:5]) ? b : a;
		end
	end
end

endmodule
*/
module Lt(
	//input
	score, a, b,
	//output
	newscore
);
input signed [4:0] score;
input [1:0] a;
input [2:0] b;
output reg signed [7:0] newscore;

reg signed [6:0] score_scale;

/*
//new
wire signed [2:0] score_r2;
wire signed [3:0] score_r1;
wire signed [5:0] score_l1;
wire signed [6:0] score_l2;

assign score_r2 = score >>> 2;
assign score_r1 = score >>> 1;
assign score_l1 = score <<< 1;
assign score_l2 = score <<< 2;

always @* begin
	case (a)
			2'b00 : score_scale = score;//a+1=1
			2'b01 : score_scale = (score[4]) ? score_r1 : score_l1;//a+1=2
			2'b10 : score_scale = (score[4]) ? (score / $signed(2'd3)) : (score_l1 + score);//a+1=3
			default : score_scale = (score[4]) ? score_r2 : score_l2;//a+1=4
	endcase
end

assign newscore = score_scale + $signed({1'b0, b});
*/
//old
wire [2:0] aplus;

assign aplus = a + 1'd1;
always @* begin
	if (score[4]==0) begin
		newscore = $signed({1'b0, aplus}) * score + $signed({6'd0, b});
	end
	else begin
		newscore = score / $signed({1'b0, aplus}) + $signed({6'd0, b});
	end
end


endmodule