//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Spring Course
//   Lab09		 : Online Shopping Platform Simulation (OS)
//   Author    	 : Zheng-Gang Ciou (nycu311511022.ee11@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : OS.sv
//   Module Name : OS
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################ 

`include "Usertype_OS.sv"

module OS (
	input clk, 
	INF.OS_inf inf
);
//---------------------------------------------------------------------
//   Port in INF.sv
//=====================================================================
//	// PATTERN
//	logic 	rst_n ; 
//	logic   id_valid;
//	logic   act_valid;
//	logic   item_valid;
//	logic   num_valid;
//	logic   amnt_valid;
//	DATA  	D;
//	
//	logic   out_valid;
//	logic 	complete;
//	Error_Msg 	err_msg;
//	logic [31:0] out_info;
//	
//	// Bridge
//	logic [7:0]  C_addr;
//	logic [63:0] C_data_w;
//	logic [63:0] C_data_r;
//	logic C_in_valid;
//	logic C_out_valid;
//	logic C_r_wb;
//
//	modport OS_inf(
//		input  
//		// Pattern
//			rst_n, D, id_valid, act_valid, item_valid, amnt_valid, num_valid, 
//		// Bridge
//			C_out_valid, C_data_r,
//
//		output 
//		// Pattern
//			out_valid, err_msg,  complete, out_info, 
//		// Bridge
//			C_addr, C_data_w, C_in_valid, C_r_wb
//	);
//---------------------------------------------------------------------
import usertype::*;

//---------------------------------------------------------------------
//   LOGIC AND TYPE DECLARATION
//---------------------------------------------------------------------
//============================ Logic ==================================
// FSM
logic [2:0] cnt;
logic cnt_ds;
// Data
logic resue_usr, resue_slr;
// Bridge
logic usr_init, slr_init;
logic usr_valid, slr_valid;
// Process
logic [2:0] act_check;
// # buy
logic [5:0] slr_invent, usr_invent, slr_invent_new, usr_invent_new;
logic [6:0] deliver_fee;
logic [8:0] price;
logic [14:0] total_fee;
logic [5:0] exp;
logic [12:0] exp_sum;
logic [11:0] total_exp;
logic level_up;
// # return
logic [255:0] return_valid, usr_history;
logic [7:0] last_buyer[0:255], last_buyer_usr, last_buyer_slr;
logic last_buyer_valid[0:255];
// # deposit
logic wallet_full;
logic [16:0] money_new;
// # Check
logic [17:0] check_info;


//============================ Type ===================================
// FSM
e_State cur_state, next_state;
e_Data_State cur_ds, next_ds;
// Input Data
User_id usr_id_R, usr_id_last_R, slr_id_R, slr_id_last_R;
Action act_R;
Money amnt_R;
Item_id item_R;
Item_num item_num_R;
// Process
Shop_Info usr_shop_info_R, slr_shop_info_R, temp_usr_shop_info_R, temp_slr_shop_info_R;
User_Info usr_user_info_R, slr_user_info_R, temp_usr_user_info_R, temp_slr_user_info_R;

//========================== Integer ==================================
integer i;

//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------
// Current State
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_cur_state
	if(~inf.rst_n)
		cur_state <= S_IDLE;
	else begin
		cur_state <= next_state;
	end
end
// Next State
always_comb begin : proc_next_state
	case (cur_state)
		S_IDLE: begin
			if (inf.act_valid) begin
				case (inf.D.d_act[0])
					No_action: next_state = S_IDLE;
					Check: next_state = S_WAIT_ID;
					Deposit: next_state = S_WAIT_AMNT;
					default : next_state = S_WAIT_ITEM; //Buy, Return
				endcase
			end
			else
				next_state = S_IDLE;
		end

		S_WAIT_ITEM: begin 
			if (inf.item_valid)
				next_state = S_WAIT_ITEM_NUM;
			else
				next_state = S_WAIT_ITEM;
		end

		S_WAIT_ITEM_NUM: begin
			if (inf.num_valid)
				next_state = S_WAIT_ID;
			else
				next_state = S_WAIT_ITEM_NUM;
		end

		S_WAIT_ID: begin
			if (cnt=='d6 && act_R==Check)
				next_state = S_PROC_CHECK_USER;
			else if (inf.id_valid) begin
				case (act_R)
					Buy: next_state = S_PROC_BUY;
					Check: next_state = S_PROC_CHECK_SELLER;
					Deposit: next_state = S_PROC_DEP;
					Return: next_state = S_PROC_RET;
					default : next_state = S_IDLE;
				endcase
			end
			else
				next_state = S_WAIT_ID;
		end

		S_WAIT_AMNT: begin
			if (inf.amnt_valid)
				next_state = S_PROC_DEP;
			else
				next_state = S_WAIT_AMNT;
		end
		/*
		S_PROC_BUY: begin
			if (cur_ds==DS_READY)
				next_state = S_OUT;
			else
				next_state = S_PROC_BUY;
		end
		*/
		S_PROC_BUY, S_PROC_DEP, S_PROC_CHECK_USER, S_PROC_CHECK_SELLER, S_PROC_RET: begin
			if (cur_ds==DS_READY)
				next_state = S_OUT;
			else
				next_state = cur_state;
		end
		/*
		S_PROC_DEP: begin

		end
		
		S_PROC_RET: begin

		end
		*/
		S_OUT: begin
			next_state = S_IDLE;
		end

		default : next_state = cur_state;
	endcase
end
// Counter
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_cnt
	if(~inf.rst_n)
		cnt <= 'd0;
	else begin
		case (cur_state)
			S_WAIT_ID: begin
				cnt <= cnt + 'd1;
			end
			default : cnt <= 'd0;
		endcase
	end
end

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// Current ID
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_usr_id_R
	if(~inf.rst_n) begin
		usr_id_R <= 'd0;
		usr_id_last_R <= 'd0;
	end
	else begin
		if (cur_state==S_IDLE && inf.id_valid) begin
			usr_id_R <= inf.D.d_id[0];
			usr_id_last_R <= usr_id_R;
		end
	end
end
// Seller ID
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_slr_id_R
	if(~inf.rst_n) begin
		slr_id_R <= 'd0;
		slr_id_last_R <= 'd0;
	end
	else begin
		if (cur_state==S_WAIT_ID && inf.id_valid && inf.D.d_id[0]!=slr_id_R) begin
			slr_id_R <= inf.D.d_id[0];
			slr_id_last_R <= slr_id_R;
		end
	end
end
// Action
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_act_R
	if(~inf.rst_n)
		act_R <= No_action;
	else begin
		if (cur_state==S_IDLE && inf.act_valid)
			act_R <= inf.D.d_act[0];
	end
end
// Item
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_item_R
	if(~inf.rst_n)
		item_R <= No_item;
	else begin
		if (cur_state==S_WAIT_ITEM && inf.item_valid)
			item_R <= inf.D.d_item[0];
	end
end
// Number of item
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_item_num_R
	if(~inf.rst_n)
		item_num_R <= 'd0;
	else begin
		if (cur_state==S_WAIT_ITEM_NUM && inf.num_valid)
			item_num_R <= inf.D.d_item_num[5:0];
	end
end
// Money
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_amnt_R
	if(~inf.rst_n)
		amnt_R <= 'd0;
	else begin
		if (cur_state==S_WAIT_AMNT && inf.amnt_valid)
			amnt_R <= inf.D.d_money;
	end
end

//---------------------------------------------------------------------
//   BRIDGE
//---------------------------------------------------------------------
//=========================== Data FSM ================================
// Cur
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_cur_ds
	if(~inf.rst_n)
		cur_ds <= DS_READY;//DS_INT;
	else begin
		cur_ds <= next_ds;
	end
end
// Next
always_comb begin : proc_next_ds
	case (cur_ds)
		DS_INT: begin
			if (inf.id_valid)
				next_ds = DS_READ_USER;
			else
				next_ds = DS_INT;
		end

		DS_READY: begin
			if (cur_state==S_IDLE && inf.id_valid) begin
				if (usr_init)
					next_ds = DS_READ_USER;
				else
					next_ds = DS_WRITE_USER;
				/*
				else if (inf.D.d_id[0]!=usr_id_R)// && inf.D.d_id[0]!=slr_id_R)
					next_ds = DS_WRITE_USER;
				else
					next_ds = DS_READY;
				*/
			end
			else if (cur_state==S_WAIT_ID && inf.id_valid) begin
				if (slr_init)
					next_ds = DS_READ_SELLER;
				else if (inf.D.d_id[0]==slr_id_R)
					next_ds = DS_READY;
				else
					next_ds = DS_WRITE_SELLER;
				/*
				else if (inf.D.d_id[0]!=slr_id_R && inf.D.d_id[0]!=usr_id_R)
					next_ds = DS_WRITE_SELLER;
				else
					next_ds = DS_READY;
				*/
			end
			else
				next_ds = DS_READY;
			
			/*
			if (~usr_valid) begin
				if (usr_init)
					next_ds = DS_READ_USER;
				else
					next_ds = DS_WRITE_USER;
			end
			else if (~slr_valid) begin
				if (slr_init)
					next_ds = DS_READ_SELLER;
				else
					next_ds = DS_WRITE_SELLER;
			end
			else
				next_ds = DS_READY;
			*/
		end

		DS_WRITE_USER: begin
			if (inf.C_out_valid)
				if (resue_slr)
					if (cur_state==S_WAIT_ID && inf.id_valid) begin
						if (inf.D.d_id[0]==slr_id_R)
							next_ds = DS_READY;
						else
							next_ds = DS_WRITE_SELLER;
					end
					else
						if (slr_valid)
							next_ds = DS_READY;
						else
							next_ds = DS_WRITE_SELLER;
				else
					next_ds = DS_READ_USER;
			else
				next_ds = DS_WRITE_USER;
		end

		DS_READ_USER: begin
			if (inf.C_out_valid) begin
				if ((cur_state==S_WAIT_ID && inf.id_valid) || ~slr_valid) begin
					if (slr_init)
						next_ds = DS_READ_SELLER;
					else if ((inf.D.d_id[0]!=slr_id_R && inf.D.d_id[0]!=usr_id_R) || ~slr_valid)
						next_ds = DS_WRITE_SELLER;
					else
						next_ds = DS_READY;
				end
				else if (~slr_valid)
					next_ds = DS_WRITE_SELLER;
				else
					next_ds = DS_READY;
				/*
				if (slr_valid)
					next_ds = DS_READY;
				else begin
					if (slr_init)
						next_ds = DS_READ_SELLER;
					else
						next_ds = DS_WRITE_SELLER;
				end
				*/
			end
			else
				next_ds = DS_READ_USER;
		end

		DS_WRITE_SELLER: begin
			if (inf.C_out_valid)
				if (resue_usr)
					next_ds = DS_READY;
				else
					next_ds = DS_READ_SELLER;
			else
				next_ds = DS_WRITE_SELLER;
		end

		DS_READ_SELLER: begin
			if (inf.C_out_valid)
				next_ds = DS_READY;
			else
				next_ds = DS_READ_SELLER;
		end

		default : next_ds = cur_ds;
	endcase
end

// Counter
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_cnt_ds
	if(~inf.rst_n)
		cnt_ds <= 'd0;
	else begin
		if (next_ds==cur_ds)
			cnt_ds <= 'd1;
		else
			cnt_ds <= 'd0;
	end
end

// User Valid
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_usr_valid
	if(~inf.rst_n)
		usr_valid <= 1'b1;
	//else if (cur_ds==DS_INT)
	//	usr_valid <= 1'b0;
	else begin
		if (cur_state==S_IDLE && inf.id_valid && (inf.D.d_id[0]!=usr_id_R && inf.D.d_id[0]!=slr_id_R || usr_init))
			usr_valid <= 1'b0;
		else if (cur_ds==DS_READ_USER && inf.C_out_valid)
			usr_valid <= 1'b1;
	end
end
// Seller Valid
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_slr_valid
	if(~inf.rst_n)
		slr_valid <= 1'b1;
	//else if (cur_ds==DS_INT)
	//	slr_valid <= 1'b0;
	else begin
		if (cur_state==S_WAIT_ID && inf.id_valid && (inf.D.d_id[0]!=usr_id_R && inf.D.d_id[0]!=slr_id_R || slr_init))
			slr_valid <= 1'b0;
		else if (cur_ds==DS_READ_SELLER && inf.C_out_valid)
			slr_valid <= 1'b1;
	end
end
//=========================== Data Read ===============================
// User Info
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_usr_info
	if(~inf.rst_n) begin
		usr_init <= 1'b1;
		usr_shop_info_R <= 'd0;
		usr_user_info_R <= 'd0;
	end 
	else begin
		
		if (cur_state==S_IDLE && inf.id_valid && inf.D.d_id[0]==slr_id_R && ~slr_init) begin
			usr_shop_info_R <= slr_shop_info_R;
			usr_user_info_R <= slr_user_info_R;
		end
		
		else if (cur_ds==DS_READ_USER && inf.C_out_valid) begin
			usr_init <= 1'b0;
			usr_shop_info_R <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24]};
			usr_user_info_R <= {inf.C_data_r[39:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
		end
		
		else begin
			case (cur_state)
				S_PROC_BUY: begin
					if (cur_ds==DS_READY && act_check=='d0) begin
						// ---------
						// Shop Info
						// - Inventory
						case (item_R)
							Large: usr_shop_info_R.large_num <= usr_invent_new;
							Medium: usr_shop_info_R.medium_num <= usr_invent_new;
							Small: usr_shop_info_R.small_num <= usr_invent_new;
						endcase
						// - Level
						usr_shop_info_R.level <= (level_up) ? usr_shop_info_R.level - 1'd1 : usr_shop_info_R.level;
						// - Exp
						usr_shop_info_R.exp <= ((level_up)) ? 'd0 : exp_sum;
						// ---------
						// User Info
						// - Money
						usr_user_info_R.money <= usr_user_info_R.money - total_fee - deliver_fee;
						// - Shop History
						usr_user_info_R.shop_history.item_ID <= item_R;
						usr_user_info_R.shop_history.item_num <= item_num_R;
						usr_user_info_R.shop_history.seller_ID <= slr_id_R;
					end
				end

				S_PROC_DEP: begin
					usr_user_info_R.money <= (wallet_full) ? usr_user_info_R.money : money_new;
				end

				S_PROC_RET: begin
					if (cur_ds==DS_READY && act_check=='d0) begin
						// ---------
						// Shop Info
						// - Inventory
						case (item_R)
							Large: usr_shop_info_R.large_num <= usr_invent_new;
							Medium: usr_shop_info_R.medium_num <= usr_invent_new;
							Small: usr_shop_info_R.small_num <= usr_invent_new;
						endcase
						// ---------
						// User Info
						// - Money
						usr_user_info_R.money <= usr_user_info_R.money + total_fee;
					end
				end
			endcase
		end
		
	end
end
// Seller Info
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_slr_info
	if(~inf.rst_n) begin
		slr_init <= 1'b1;
		slr_shop_info_R <= 'd0;
		slr_user_info_R <= 'd0;
	end 
	else begin
		if (cur_state==S_WAIT_ID && inf.id_valid && inf.D.d_id[0]==slr_id_R && ~usr_init) begin
			slr_shop_info_R <= slr_shop_info_R;
			slr_user_info_R <= slr_user_info_R;
		end
		
		else if (cur_state==S_WAIT_ID && inf.id_valid && inf.D.d_id[0]==usr_id_R && ~usr_init) begin
			slr_shop_info_R <= usr_shop_info_R;
			slr_user_info_R <= usr_user_info_R;
		end
		
		else if (cur_ds==DS_READ_SELLER && inf.C_out_valid) begin
			slr_init <= 1'b0;
			slr_shop_info_R <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24]};
			slr_user_info_R <= {inf.C_data_r[39:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
		end
		
		else begin
			case (cur_state)
				S_PROC_BUY: begin
					if (cur_ds==DS_READY && act_check=='d0) begin
						// ---------
						// Shop Info
						//  - Inventory
						case (item_R)
							Large: slr_shop_info_R.large_num <= slr_invent_new;
							Medium: slr_shop_info_R.medium_num <= slr_invent_new;
							Small: slr_shop_info_R.small_num <= slr_invent_new;
						endcase
						// ---------
						// User Info
						// - Money
						slr_user_info_R.money <= (wallet_full) ? 16'd65535 : money_new;
					end
				end

				S_PROC_RET: begin
					if (cur_ds==DS_READY && act_check=='d0) begin
						// ---------
						// Shop Info
						//  - Inventory
						case (item_R)
							Large: slr_shop_info_R.large_num <= slr_invent_new;
							Medium: slr_shop_info_R.medium_num <= slr_invent_new;
							Small: slr_shop_info_R.small_num <= slr_invent_new;
						endcase
						// ---------
						// User Info
						// - Money
						slr_user_info_R.money <= slr_user_info_R.money - total_fee;
					end
				end
			endcase
		end
		
	end
end

// Temp
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_temp
	if(~inf.rst_n) begin
		temp_usr_shop_info_R <= 'd0;
		temp_usr_user_info_R <= 'd0;
		temp_slr_shop_info_R <= 'd0;
		temp_slr_user_info_R <= 'd0;
		resue_usr <= 1'b0;
		resue_slr <= 1'b0;
	end 
	else begin
		case (cur_state)
			S_IDLE: begin
				if (inf.id_valid && inf.D.d_id[0]==slr_id_R && ~slr_init)begin
					temp_usr_shop_info_R <= usr_shop_info_R;
					temp_usr_user_info_R <= usr_user_info_R;
					resue_slr <= 1'b1;
				end
			end

			S_WAIT_ID: begin
				if (inf.id_valid && inf.D.d_id[0]==usr_id_R && ~usr_init) begin
					temp_slr_shop_info_R <= slr_shop_info_R;
					temp_slr_user_info_R <= slr_user_info_R;
					resue_usr <= 1'b1;
				end
			end

			S_OUT: begin
				resue_slr <= 1'b0;
				resue_usr <= 1'b0;
			end

		endcase
	end
end

//---------------------------------------------------------------------
//   PROCESS
//---------------------------------------------------------------------
// Action Check
always_comb begin
	case (cur_state)
		S_PROC_BUY: begin
			if (cur_ds==DS_READY) begin
				if (usr_invent + item_num_R > 'd63)
					act_check = 'd1;
				else if (slr_invent < item_num_R)
					act_check = 'd2;
				else if (total_fee + deliver_fee > usr_user_info_R.money)
					act_check = 'd3;
				else
					act_check = 'd0;
			end
			else
				act_check = 'd0;
		end

		S_PROC_DEP: begin
			if (wallet_full)
				act_check = 'd1;
			else
				act_check = 'd0;
		end

		S_PROC_RET: begin
			if (~return_valid[usr_id_R])
				act_check = 'd1;
			else if (slr_id_R!=usr_user_info_R.shop_history.seller_ID)
				act_check = 'd2;
			else if (item_num_R!=usr_user_info_R.shop_history.item_num)
				act_check = 'd3;
			else if (item_R!=usr_user_info_R.shop_history.item_ID)
				act_check = 'd4;
			else
				act_check = 'd0;
		end

		default : act_check = 'd0;
	endcase
end
//============================ Buy ====================================
// Deliver Fee
always_comb begin
	if (cur_state==S_PROC_BUY) begin
		case (usr_shop_info_R.level)
			Platinum: deliver_fee = 'd10;
			Gold: deliver_fee = 'd30;
			Silver: deliver_fee = 'd50;
			default : deliver_fee = 'd70;
		endcase
	end
	else
		deliver_fee = 'd0;
end
// Inventory
always_comb begin
	if (cur_state==S_PROC_BUY || cur_state==S_PROC_RET) begin
		case (item_R)
			Large: begin
				slr_invent = slr_shop_info_R.large_num;
				usr_invent = usr_shop_info_R.large_num;
				price = 'd300;
				exp = 'd60;
			end
			
			Medium: begin
				slr_invent = slr_shop_info_R.medium_num;
				usr_invent = usr_shop_info_R.medium_num;
				price = 'd200;
				exp = 'd40;
			end

			Small: begin
				slr_invent = slr_shop_info_R.small_num;
				usr_invent = usr_shop_info_R.small_num;
				price = 'd100;
				exp = 'd20;
			end

			default : begin
				slr_invent = 'd0;
				usr_invent = 'd0;
				price = 'd0;
				exp = 'd0;
			end
		endcase
	end
	else begin
		slr_invent = 'd0;
		usr_invent = 'd0;
		price = 'd0;
		exp = 'd0;
	end
end
// usr_invent_new, slr_invent_new
//assign usr_invent_new = usr_invent + item_num_R;
//assign slr_invent_new = slr_invent - item_num_R;
always_comb begin
	if (cur_ds==DS_READY) begin
		case (cur_state)
			S_PROC_BUY: begin
				usr_invent_new = usr_invent + item_num_R;
				slr_invent_new = slr_invent - item_num_R;
			end

			S_PROC_RET: begin
				usr_invent_new = usr_invent - item_num_R;
				slr_invent_new = slr_invent + item_num_R;
			end
			default : begin
				usr_invent_new = 'd0;
				slr_invent_new = 'd0;
			end
		endcase
	end
	else begin
		usr_invent_new = 'd0;
		slr_invent_new = 'd0;
	end
end

assign total_fee = item_num_R  * price;
assign total_exp = item_num_R * exp;
assign exp_sum = (usr_shop_info_R.level==Platinum) ? 'd0 : usr_shop_info_R.exp + total_exp;
// Level
always_comb begin
	if (cur_state==S_PROC_BUY && cur_ds==DS_READY) begin
		case (usr_shop_info_R.level)
			Gold: level_up = (exp_sum < 'd4000) ? 1'b0 : 1'b1;
			Silver: level_up = (exp_sum < 'd2500) ? 1'b0 : 1'b1;
			Copper: level_up = (exp_sum < 'd1000) ? 1'b0 : 1'b1;
			default : level_up = 1'b0;
		endcase
	end
	else
		level_up = 1'b0;
end
//=========================== Check ===================================
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_check_info
	if (~inf.rst_n)
		check_info <= 'd0;
	else begin
		if (cur_ds==DS_READY) begin
			case (cur_state)
				S_PROC_CHECK_USER: check_info <= {2'b0, usr_user_info_R.money};
				S_PROC_CHECK_SELLER: check_info <= {slr_shop_info_R.large_num, slr_shop_info_R.medium_num, slr_shop_info_R.small_num};
			endcase
		end
	end
end

// User


// Seller

//========================== Deposit ==================================
// New Money
always_comb begin
	if (cur_ds==DS_READY) begin
		case (cur_state)
			S_PROC_BUY: money_new = slr_user_info_R.money + total_fee;
			S_PROC_DEP: money_new = usr_user_info_R.money + amnt_R;
			default : money_new = 'd0;
		endcase
	end
	else
		money_new = 'd0;
end
// Wellet Full
always_comb begin
	case (cur_state)
		S_PROC_BUY: begin
			if (cur_ds==DS_READY && (money_new < 'd65535))
				wallet_full = 1'b0;
			else
				wallet_full = 1'b1;
		end

		S_PROC_DEP: begin
			if (cur_ds==DS_READY && (money_new < 'd65535))
				wallet_full = 1'b0;
			else
				wallet_full = 1'b1;
		end
		default : wallet_full = 1'b0;
	endcase
end

//========================== Return ===================================
// Return Valid
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_return_valid
	if(~inf.rst_n) begin
		return_valid <= 'd0;
	end 
	else begin
		case (cur_state)
			S_PROC_BUY: begin
				if (next_state==S_OUT && act_check=='d0) begin
					return_valid[usr_id_R] <= 1'b1;
					return_valid[slr_id_R] <= 1'b0;

					//return_valid[last_buyer_usr] <= (last_buyer_valid[usr_id_R]) ? 1'b0 : return_valid[last_buyer_usr];
					//return_valid[last_buyer_slr] <= (last_buyer_valid[slr_id_R]) ? 1'b0 : return_valid[last_buyer_slr];

					
					if (last_buyer_valid[usr_id_R] && last_buyer_usr!=usr_id_R)
						return_valid[last_buyer_usr] <= 1'b0;
					if (last_buyer_valid[slr_id_R] && last_buyer_slr!=usr_id_R)
						return_valid[last_buyer_slr] <= 1'b0;
					
					/*
					if (usr_history[usr_id_R])
						return_valid[usr_user_info_R.shop_history.seller_ID] <= 1'b0;
					if (usr_history[slr_id_R])
						return_valid[slr_user_info_R.shop_history.seller_ID] <= 1'b0;
					*/
				end
			end

			S_PROC_CHECK_USER, S_PROC_DEP: begin
				if (next_state==S_OUT && act_check=='d0) begin
					return_valid[usr_id_R] <= 1'b0;
					if (last_buyer_valid[usr_id_R])
						return_valid[last_buyer_usr] <= 1'b0;
					/*
					if (usr_history[usr_id_R])
						return_valid[usr_user_info_R.shop_history.seller_ID] <= 1'b0;
					*/
				end
			end
			/*
			S_PROC_CHECK_SELLER: begin
				return_valid[usr_id_R] <= 1'b0;
				return_valid[slr_id_R] <= 1'b0;
				return_valid[usr_user_info_R.shop_history.seller_ID] <= 1'b0;
				return_valid[slr_user_info_R.shop_history.seller_ID] <= 1'b0;
			end
			
			S_PROC_DEP: begin
				return_valid[usr_id_R] <= 1'b0;
				return_valid[usr_user_info_R.shop_history.seller_ID] <= 1'b0;
			end
			*/
			S_PROC_RET, S_PROC_CHECK_SELLER: begin
				if (next_state==S_OUT && act_check=='d0) begin
					return_valid[usr_id_R] <= 1'b0;
					return_valid[slr_id_R] <= 1'b0;
					if (last_buyer_valid[usr_id_R])
						return_valid[last_buyer_usr] <= 1'b0;
					if (last_buyer_valid[slr_id_R])
						return_valid[last_buyer_slr] <= 1'b0;
					/*
					if (usr_history[usr_id_R])
						return_valid[usr_user_info_R.shop_history.seller_ID] <= 1'b0;
					if (usr_history[slr_id_R])
						return_valid[slr_user_info_R.shop_history.seller_ID] <= 1'b0;
					*/
				end
			end
			
		endcase
	end
end

// Last Buyer
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_last_buyer
	if(~inf.rst_n) begin
		for (i=0; i<256; i=i+1) begin
			last_buyer[i] <= 'd0;
			last_buyer_valid[i] <= 1'b0;
		end
	end 
	else begin
		if (cur_state==S_PROC_BUY && next_state==S_OUT && act_check=='d0) begin
			last_buyer_valid[slr_id_R] <= 1'b1;
			if (last_buyer[usr_user_info_R.shop_history.seller_ID]==usr_id_R && usr_user_info_R.shop_history.seller_ID!=slr_id_R)
				last_buyer_valid[usr_user_info_R.shop_history.seller_ID] <= 1'b0;
			last_buyer[slr_id_R] <= usr_id_R;
		end
	end
end
assign last_buyer_usr = last_buyer[usr_id_R];
assign last_buyer_slr = last_buyer[slr_id_R];
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
//=========================== Bridge ==================================
// C_addr
always_comb begin : proc_C_addr
	case (cur_ds)
		DS_WRITE_USER: inf.C_addr = usr_id_last_R;
		DS_READ_USER: inf.C_addr = usr_id_R;
		DS_WRITE_SELLER: inf.C_addr = slr_id_last_R;
		DS_READ_SELLER: inf.C_addr = slr_id_R;
		default : inf.C_addr = 'd0;
	endcase
end
// C_r_wb
always_comb begin : proc_C_r_wb
	case (cur_ds)
		DS_READ_USER, DS_READ_SELLER: inf.C_r_wb = 1'b1;
		default : inf.C_r_wb = 1'b0;
	endcase
end
// C_in_valid
always_comb begin : proc_C_in_valid
	if (cnt_ds=='d0) begin
		case (cur_ds)
			DS_WRITE_USER, DS_READ_USER, DS_WRITE_SELLER, DS_READ_SELLER: inf.C_in_valid = 1'b1;
			default : inf.C_in_valid = 1'b0;
		endcase
	end
	else
		inf.C_in_valid = 1'b0;
end
// C_data_w
always_comb begin : proc_C_data
	case (cur_ds)
		//usr_shop_info_R <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24]};
		//usr_user_info_R <= {inf.C_data_r[39:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
		DS_WRITE_USER: begin
			if (~resue_slr)
				inf.C_data_w = {usr_user_info_R[7:0], usr_user_info_R[15:8], usr_user_info_R[23:16], usr_user_info_R[31:24],usr_shop_info_R[7:0], usr_shop_info_R[15:8], usr_shop_info_R[23:16], usr_shop_info_R[31:24]};
			else
				inf.C_data_w = {temp_usr_user_info_R[7:0], temp_usr_user_info_R[15:8], temp_usr_user_info_R[23:16], temp_usr_user_info_R[31:24],temp_usr_shop_info_R[7:0], temp_usr_shop_info_R[15:8], temp_usr_shop_info_R[23:16], temp_usr_shop_info_R[31:24]};
		end

		DS_WRITE_SELLER: begin
			if (~resue_usr)
				inf.C_data_w = {slr_user_info_R[7:0], slr_user_info_R[15:8], slr_user_info_R[23:16], slr_user_info_R[31:24], slr_shop_info_R[7:0], slr_shop_info_R[15:8], slr_shop_info_R[23:16], slr_shop_info_R[31:24]};
			else
				inf.C_data_w = {temp_slr_user_info_R[7:0], temp_slr_user_info_R[15:8], temp_slr_user_info_R[23:16], temp_slr_user_info_R[31:24], temp_slr_shop_info_R[7:0], temp_slr_shop_info_R[15:8], temp_slr_shop_info_R[23:16], temp_slr_shop_info_R[31:24]};
		end

		default : inf.C_data_w = 'd0;
	endcase
end
//=========================== Pattern =================================
// Out Valid
always_comb begin : proc_out_valid
	if (cur_state==S_OUT)
		inf.out_valid = 1'b1;
	else
		inf.out_valid = 1'b0;
end
// Out Info
always_comb begin : proc_out_info
	if (cur_state==S_OUT)
		case (act_R)
			Buy: begin
				if (inf.complete)
					inf.out_info = usr_user_info_R;
				else
					inf.out_info = 'd0;
			end

			Check: begin
				inf.out_info = {14'b0, check_info};
			end

			Deposit: begin
				if (inf.complete)
					inf.out_info = {16'b0, usr_user_info_R.money};
				else
					inf.out_info = 'd0;
			end

			Return: begin
				if (inf.complete)
					inf.out_info = {14'd0, usr_shop_info_R.large_num, usr_shop_info_R.medium_num, usr_shop_info_R.small_num};
				else
					inf.out_info = 'd0;
			end
			default : inf.out_info = 'd0;
		endcase
	else
		inf.out_info = 'd0;
end
// Err_msg
//assign inf.err_msg = No_Err;
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_err_msg
	if(~inf.rst_n)
		inf.err_msg <= No_Err;
	else begin
		if (next_state==S_OUT) begin
			case (act_R)
				Buy: begin
					case (act_check)
						'd1: inf.err_msg <= INV_Full;
						'd2: inf.err_msg <= INV_Not_Enough;
						'd3: inf.err_msg <= Out_of_money;
						default : inf.err_msg <= No_Err;
					endcase
				end

				Check: begin
					inf.err_msg <= No_Err;
				end

				Deposit: begin
					if (act_check=='d1)
						inf.err_msg <= Wallet_is_Full;
				end

				Return: begin
					case (act_check)
						'd1: inf.err_msg <= Wrong_act;
						'd2: inf.err_msg <= Wrong_ID;
						'd3: inf.err_msg <= Wrong_Num;
						'd4: inf.err_msg <= Wrong_Item;
						default : inf.err_msg <= No_Err;
					endcase
				end
				default: inf.err_msg <= No_Err;
			endcase
		end
		else
			inf.err_msg <= No_Err;
	end
end

// Complete
//assign inf.complete = 'd0;
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_complete
	if(~inf.rst_n) begin
		inf.complete <= 1'b0;
		usr_history <= 'd0;
	end
	else begin
		if (next_state==S_OUT && act_check=='d0) begin
			inf.complete <= 1'b1;
			if (act_R==Buy)
				usr_history[usr_id_R] <= 'b1;
		end
		else
			inf.complete <= 1'b0;
	end
end

endmodule