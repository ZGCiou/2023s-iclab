//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`include "Usertype_OS.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//covergroup Spec1 @();
//	
//       finish your covergroup here
//	
//	
//endgroup

//declare other cover group
// Cover Point at input port
covergroup cg_in() @(posedge clk);
	cp_Spec1: coverpoint inf.D.d_money iff(inf.amnt_valid) {
		option.at_least = 10;
		bins range1 = {[0:12000]};
		bins range2 = {[12001:24000]};
		bins range3 = {[24001:36000]};
		bins range4 = {[36001:48000]};
		bins range5 = {[48001:60000]};
	}

	cp_Spec2: coverpoint inf.D.d_id[0] iff(inf.id_valid) {
		option.at_least = 2;
		option.auto_bin_max = 256;
	}

	cp_Spec3: coverpoint inf.D.d_act[0] iff(inf.act_valid) {
		option.at_least = 10;
		bins trans[] = (Buy, Check, Deposit, Return => Buy, Check, Deposit, Return);
	}

	cp_Spec4: coverpoint inf.D.d_item[0] iff(inf.item_valid) {
		option.at_least = 20;
		bins item [] = {Large, Medium, Small};
	}
endgroup : cg_in

// Cover Point at output port
covergroup cg_out() @(negedge clk iff(inf.out_valid));
	cp_Spec5: coverpoint inf.err_msg {
		option.at_least = 20;
		ignore_bins ignore = {No_Err, 1, [5:7], 11, [13:14]};
	}

	cp_Spec6: coverpoint inf.complete {
		option.at_least = 200;
	}
endgroup : cg_out

//declare the cover group 
//Spec1 cov_inst_1 = new();
cg_in cov_inst_1 = new();
cg_out cov_inst_2 = new();

//$display("Coverage: %f", $get_coverage);
//cov_inst_1.stop();
//cov_inst_2.stop();
//$display("Instance 1 coverage is %e", cov_inst_1.get_coverage());
//$display("Instance 2 coverage is %e", cov_inst_2.get_coverage());

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0)
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

//write other assertions

//---------- SPEC 1 ----------
// All outputs signals (including OS.sv and bridge.sv) should be zero after reset.
sequence s_out_0;
	//------- OS.sv -------
	// Pattern
	inf.out_valid 	== 'd0 &&
	inf.out_info 	== 'd0 &&
	inf.complete 	== 'd0 &&
	inf.err_msg 	== 'd0 &&
	// Bridge
	inf.C_addr 		== 'd0 &&
	inf.C_r_wb 		== 'd0 &&
	inf.C_in_valid 	== 'd0 &&
	inf.C_data_w 	== 'd0 &&
	//----- bridge.sv -----
	// OS
	inf.C_out_valid == 'd0 &&
	inf.C_data_r 	== 'd0 &&
	// DRAM
	inf.AR_VALID 	== 'd0 &&
	inf.AR_ADDR 	== 'd0 &&
	inf.R_READY 	== 'd0 &&
	inf.AW_VALID 	== 'd0 &&
	inf.AW_ADDR 	== 'd0 &&
	inf.W_VALID 	== 'd0 &&
	inf.W_DATA 		== 'd0 &&
	inf.B_READY 	== 'd0;
endsequence

property p_Spec1;
	@(posedge inf.rst_n) ~inf.rst_n |-> s_out_0;
endproperty

ap_Spec1: assert property (p_Spec1) else $fatal(2, "Assertion 1 is violated");

//---------- SPEC 2 ----------
// If action is completed, err_msg must be 4’b0.
property p_Spec2;
	@(posedge clk) inf.complete |-> (inf.err_msg==No_Err);
endproperty

ap_Spec2: assert property (p_Spec2) else $fatal(2, "Assertion 2 is violated");

//---------- SPEC 3 ----------
// If action is not completed, out_info should be 32’b0.
property p_Spec3;
	@(posedge clk) ~inf.complete |-> (inf.out_info==32'b0);
endproperty

ap_Spec3: assert property (p_Spec3) else $fatal(2, "Assertion 3 is violated");

//---------- SPEC 4 ----------
// All input valid can only be high for exactly one cycle.
property p_Spec4_id;
	@(posedge clk) inf.id_valid |=> ~inf.id_valid;
endproperty

property p_Spec4_act;
	@(posedge clk) inf.act_valid |=> ~inf.act_valid;
endproperty

property p_Spec4_item;
	@(posedge clk) inf.item_valid |=> ~inf.item_valid;
endproperty

property p_Spec4_num;
	@(posedge clk) inf.num_valid |=> ~inf.num_valid;
endproperty

property p_Spec4_amnt;
	@(posedge clk) inf.amnt_valid |=> ~inf.amnt_valid;
endproperty

ap_Spec4_id: 	assert property (p_Spec4_act) 	else $fatal(2, "Assertion 4 is violated");
ap_Spec4_act: 	assert property (p_Spec4_id) 	else $fatal(2, "Assertion 4 is violated");
ap_Spec4_item: 	assert property (p_Spec4_item) 	else $fatal(2, "Assertion 4 is violated");
ap_Spec4_num: 	assert property (p_Spec4_num) 	else $fatal(2, "Assertion 4 is violated");
ap_Spec4_amnt: 	assert property (p_Spec4_amnt) 	else $fatal(2, "Assertion 4 is violated");

//---------- SPEC 5 ----------
// The five valid signals won’t overlap with each other.( id_valid, act_valid, amnt_valid, item_valid , num_valid )
property p_Spec5;
	@(posedge clk) $onehot0({inf.id_valid, inf.act_valid, inf.item_valid, inf.num_valid, inf.amnt_valid});
endproperty

ap_Spec5: assert property (p_Spec5) else $fatal(2, "Assertion 5 is violated");

//---------- SPEC 6 ----------
// The gap between each input valid is at least 1 cycle and at most 5 cycles(including the correct input sequence).
// # Sequence
sequence s_act_buy_return;
	inf.act_valid && (inf.D.d_act[0]==Buy || inf.D.d_act[0]==Return);
endsequence

sequence s_act_dep;
	inf.act_valid && (inf.D.d_act[0]==Deposit);
endsequence

sequence s_act_check_user;
	inf.act_valid && (inf.D.d_act[0]==Check) ##1 ~inf.id_valid [*6];
endsequence

sequence s_act_check_seller;
	inf.act_valid && (inf.D.d_act[0]==Check) ##[2:6] inf.id_valid;
endsequence

sequence s_id_change;
	~(inf.num_valid || inf.act_valid) [*6] ##1 inf.id_valid;// ##[2:6] inf.act_valid;
endsequence

sequence s_no_input;
	~(inf.id_valid || inf.act_valid || inf.item_valid || inf.num_valid || inf.amnt_valid);
endsequence

// # Property
property p_Spec6_id_change;
	@(posedge clk) s_id_change |=> (##[1:5] inf.act_valid);
endproperty

property p_Spec6_buy_return;
	@(posedge clk) s_act_buy_return |=> (##[1:5] inf.item_valid ##[2:6] inf.num_valid ##[2:6] inf.id_valid);
endproperty

property p_Spec6_dep;
	@(posedge clk) s_act_dep |=> (##[1:5] inf.amnt_valid);
endproperty

property p_Spec6_check_user;
	@(posedge clk) s_act_check_user |=> ~inf.id_valid throughout (##[1:$] inf.out_valid);
endproperty

// # Assertion
ap_Spec6_id_change: 	assert property (p_Spec6_id_change) 	else $fatal(2, "Assertion 6 is violated");
ap_Spec6_buy_return: 	assert property (p_Spec6_buy_return) 	else $fatal(2, "Assertion 6 is violated");
ap_Spec6_dep: 			assert property (p_Spec6_dep) 			else $fatal(2, "Assertion 6 is violated");
ap_Spec6_check_user: 	assert property (p_Spec6_check_user) 	else $fatal(2, "Assertion 6 is violated");

//---------- SPEC 7 ----------
// Out_valid will be high for one cycle.
property p_Spec7;
	@(posedge clk) inf.out_valid |=> ~inf.out_valid;
endproperty

ap_Spec7: assert property (p_Spec7) else $fatal(2, "Assertion 7 is violated");

//---------- SPEC 8 ----------
// Next operation will be valid 2-10 cycles after out_valid fall.
property p_Spec8;
	@(posedge clk) $fell(inf.out_valid) |-> (s_no_input ##[1:9] inf.id_valid || inf.act_valid);
endproperty

ap_Spec8: assert property (p_Spec8) else $fatal(2, "Assertion 8 is violated");

//---------- SPEC 9 ----------
// Latency should be less than 10000 cycle for each operation.
property p_Spec9_dep;
	@(posedge clk) s_act_dep |-> (##[1:10000] inf.out_valid);
endproperty

property p_Spec9_check_user;
	@(posedge clk) s_act_check_user |-> (##[1:9995] inf.out_valid);
endproperty

property p_Spec9_check_seller;
	@(posedge clk) s_act_check_seller |-> (##[1:10000] inf.out_valid);
endproperty

property p_Spec9_buy_return;
	@(posedge clk)  s_act_buy_return |-> (##[1:10000] inf.out_valid);
endproperty

ap_Spec9_dep: 			assert property (p_Spec9_dep) 			else $fatal(2, "Assertion 9 is violated");
ap_Spec9_check_user: 	assert property (p_Spec9_check_user) 	else $fatal(2, "Assertion 9 is violated");
ap_Spec9_check_seller: 	assert property (p_Spec9_check_seller) 	else $fatal(2, "Assertion 9 is violated");
ap_Spec9_buy_return: 	assert property (p_Spec9_buy_return) 	else $fatal(2, "Assertion 9 is violated");


endmodule