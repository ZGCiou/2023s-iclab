`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
//----- Parameter -----
parameter SEED = 123;
parameter PAT_NUM = 100;
parameter GEN_DAT = 1;

//----- Integer -----
integer pat_cnt;
integer i;
integer price, deliver, total_price, total_fee, exp_per, total_exp, inv_buyer, inv_seller, total_invent;

//================================================================
// wire & registers 
//================================================================
logic [7:0] dram [0:2047];
//s_Info info_table [0:255];

User_id cur_id_user, cur_id_sellr;
Action cur_act;
Money cur_amnt;
Item_id cur_item;
Item_num cur_item_num;



c_INFO info_table [256];
//c_DATA cur_data;
c_IN_DATA cur_input;


logic golden_complete;
Error_Msg golden_err_msg;
logic [31:0] golden_out_info;

//================================================================
// class
//================================================================
class c_INFO;
	// Data Member
	rand Shop_Info shop_info;
	rand User_Info user_info;
	Return_Info return_info;

	// Method
	function new(int seed);
		this.srand(seed);
		return_info = 0;
	endfunction : new
	constraint limit_shop_info {
		(shop_info.level==Platinum) -> shop_info.exp==0;
		(shop_info.level==Gold) -> shop_info.exp inside {[0:3999]};
		(shop_info.level==Silver) -> shop_info.exp inside {[0:2499]};
		(shop_info.level==Copper) => shop_info.exp inside {[1:999]};
	}
	constraint limit_user_info {
		user_info.shop_history.item_ID inside {[1:3]};
	}

	function Error_Msg buy_check(Item_id item, Item_num num);
		//integer price, deliver, total_price, exp_per, total_exp, invent, total_invent;
		// Check invent
		case (item)
			Large: inv_buyer = shop_info.large_num;
			Medium: inv_buyer = shop_info.medium_num;
			Small: inv_buyer = shop_info.small_num;
			default: inv_buyer = 0;
		endcase
		total_invent = inv_buyer + num;
		// Check money
		case (item)
			Large: price = 300;
			Medium: price = 200;
			Small: price = 100;
			default : price = 0;
		endcase
		case (shop_info.level)
			Platinum: deliver = 10;
			Gold: deliver = 30;
			Silver: deliver = 50;
			Copper: deliver = 70;
		endcase
		total_price = price * num ;
		total_fee = total_price = deliver;

		if (total_invent>63)
			return INV_Full;
		if (user_info.money<total_fee)
			return Out_of_money;

		return No_Err;

	endfunction : buy_check

	function void buy(Item_id item, Item_num num, User_id seller);
		//integer price, deliver, total_price, exp_per, total_exp, invent, total_invent;

		// inventory
		case (item)
			Large: shop_info.large_num = total_invent;
			Medium: shop_info.medium_num = total_invent;
			Small: shop_info.small_num = total_invent;
		endcase
		// Money
		user_info.money = user_info.money - total_fee;
		// Level, Exp
		case (item)
			Large: exp_per = 60;
			Medium: exp_per = 40;
			Small: exp_per = 20;
			default : exp_per = 0;
		endcase
		total_exp = exp_per * num + shop_info.exp;

		case (shop_info.level)
			Gold: begin
				if (total_exp>=4000) begin
					shop_info.level = Platinum;
					shop_info.exp = 0;
				end
				else
					shop_info.exp = total_exp;
			end

			Silver: begin
				if (total_exp>=2500) begin
					shop_info.level = Gold;
					shop_info.exp = 0;
				end
				else
					shop_info.exp = total_exp;
			end

			Copper: begin
				if (total_exp>=1000) begin
					shop_info.level = Silver;
					shop_info.exp = 0;
				end
				else
					shop_info.exp = total_exp;
			end
		endcase
		// History
		user_info.shop_history.item_ID = item;
		user_info.shop_history.item_num = num;
		user_info.shop_history.seller_ID = seller;
		return_info.can_return = 1;
		
	endfunction : buy

	function Error_Msg deposit(Money amnt);
		integer total_money;
		total_money = user_info.money + amnt;
		if (total_money>'d65535)
			return Wallet_is_Full;
		user_info.money = total_money;
		return No_Err;
	endfunction : deposit

	function Error_Msg sell_check(Item_id item, Item_num num);
		// Check invent
		case (item)
			Large: inv_seller = shop_info.large_num;
			Medium: inv_seller = shop_info.medium_num;
			Small: inv_seller = shop_info.small_num;
			default: inv_seller = 0;
		endcase
		if (inv_seller<num)
			return INV_Not_Enough;
		return No_Err;

	endfunction : sell_check

	function void sell(Item_id item, Item_num num);
		// Money 
		user_info.money = user_info.money + total_price;
		// Inventory
		case (item)
			Large: shop_info.large_num = shop_info.large_num - num;
			Medium: shop_info.medium_num = shop_info.large_num - num;
			Small: shop_info.small_num = shop_info.large_num - num;
		endcase
	endfunction : sell

	function Error_Msg return_check();
		
	endfunction : return_check

endclass : c_INFO

class c_DATA;
	rand User_id user_id, seller_id;
	rand Action act;
	rand Item_id item;
	rand Item_num item_num;
	rand Money money;
	
	// Constructor
	function new(int seed);
		this.srand(seed);
	endfunction : new
	constraint limit_data {
		act inside {Buy, Check, Deposit, Return};
		item inside {Large, Medium, Small};
	}
	
	// Acessor
	function User_id getId_usr();
		return user_id;
	endfunction : getId_usr
		
	function User_id gerId_slr();
		return seller_id;
	endfunction : gerId_slr

	function Action getAct();
		return act;
	endfunction : getAct

	function Item_id getItem();
		return item;
	endfunction : getItem

	function Item_num getNum();
		return item_num;
	endfunction : getNum

	function Money getMoney();
		return money;
	endfunction : getMoney

	// Method
	function void initial();
		act = No_action;
		item = No_item;
		item_num = 0;
		money = 0;
	endfunction : initial

endclass : c_DATA
	

class c_IN_DATA extends c_DATA;
	rand bit change_id, check_seller;
	rand integer gap[4];
	rand integer next_op_lat;

	function new(int seed, int cnt);
		this.srand(seed);
	endfunction : new
	constraint limit_lat {
		foreach (gap[i]) gap[i] inside {[1:5]};
		(cnt==0) -> change_id == 1;
		(cnt==0) -> next_op_lat inside {[1:5]};
		(cnt!=0) -> next_op_lat inside {[2:20]};
	}

	function bit getChange();
		return change_id;
	endfunction : getChange

	function bit getCheck();
		return check_seller;
	endfunction : getCheck

	function integer getGap(int x);
		return gap[x];
	endfunction : getGap

	function integer getLat();
		return next_op_lat;
	endfunction : getLat

endclass : c_IN_DATA


//================================================================
// initial
//================================================================
initial begin
	dram_task;
	reset_task;
	for (pat_cnt=0; pat_cnt<PAT_NUM; pat_cnt=pat_cnt+1) begin
		input_task;
		wait_out_valid_task;
		cal_ans_task;
		check_ans_task;
	end
end



//================================================================
// task
//================================================================
//----- DRAM -----
task dram_task;
	begin
		foreach (info_table[i]) begin
			info_table[i] = new(SEED);
		end

		if (GEN_DAT==1) begin
			
		end

		$readmemh("../00_TESTBED/DRAM/dram.dat",dram);
		for (i=0; i<256; i=i+1) begin
			info_table[i].shop.large_num = ;
			info_table[i].shop.medium_num = ;
			info_table[i].shop.small_num = ;
			info_table[i].shop.level = ;
			info_table[i].shop.exp = ;

			info_table[i].user.money = ;
			info_table[i].user.shop_history.item_ID = ;
			info_table[i].user.shop_history.item_num = ;
			info_table[i].user.shop_history.seller_ID = ;
		end
	end
endtask : dram_task

//----- Reset -----
task reset_task;
	begin
		inf.rst_n = 1'b1;
		inf.id_valid = 1'b0;
		inf.act_valid = 1'b0;
		inf.item_valid = 1'b0;
		inf.num_valid = 1'b0;
		inf.amnt_valid = 1'b0;
		inf.D = 'dx;

		#10 inf.rst_n = 1'b0;
		#10 inf.rst_n = 1'b1;
	end
endtask

//----- Input -----
task input_task;
	//integer gap, next_op_lat;
	//bit change_id;
	begin
		/*
		// lantency
		if (pat_cnt==0) begin
			next_op_lat = $urandom(SEED) % 5 + 1;
			change_id = 1;
		end
		else begin
			next_op_lat = $urandom(SEED) % 19 + 2;
			change_id = $urandom(SEED) % 2;
		end

		// random action
		cur_act = $urandom_range(,)


		repeat(next_op_lat) @(negedge clk);
		inf.id_valid = (change_id) ? 1'b1 ; 1'b0;
		*/
		cur_input = new(SEED, pat_cnt);
		// Latency between operate
		repeat(cur_input.getLat()) @(negedge clk);
		// ID
		if (cur_input.getChange()) begin
			inf.id_valid = 1;
			inf.D = cur_input.getId_usr();
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
			repeat(cur_input.getLat(0)) @(negedge clk);
		end
		// Action
		inf.act_valid = 1;
		inf.D = cur_input.getAct();
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;

		// Buy or Return
		if (cur_input.getAct()==Buy || cur_input.getAct()==Return) begin
			// Item
			repeat(cur_input.getLat(1)) @(negedge clk);
			inf.item_valid = 1;
			inf.D = cur_input.getItem();
			@(negedge clk);
			inf.item_valid = 0;
			inf.D = 'dx;

			// Item Number
			repeat(cur_input.getLat(2)) @(negedge clk);
			inf.num_valid = 1;
			inf.D = cur_input.getNum();
			@(negedge clk);
			inf.num_valid = 0;
			inf.D = 'dx;

			// Seller id
			repeat(cur_input.getLat(3)) @(negedge clk);
			inf.id_valid = 1;
			inf.D = cur_input.getId_slr();
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
		end

		// Deposit
		else if (cur_input.getAct()==Deposit) begin
			// Money
			repeat(cur_input.getLat(1)) @(negedge clk);
			inf.amnt_valid = 1;
			inf.D = cur_input.getMoney();
			@(negedge clk);
			inf.amnt_valid = 0;
			inf.D = 'dx;
		end

		// Check
		else if (cur_input.getAct()==Check) begin
			// Seller
			if (cur_input.getCheck()) begin
				repeat(cur_input.getLat(1)) @(negedge clk);
				inf.id_valid = 1;
				inf.D = cur_input.getId_slr();
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
			end
			else
				repeat(6) @(negedge clk);
		end
	end
endtask : input_task

//----- Wait Out Valid -----
task wait_out_valid_task;
	begin
		while (~inf.out_valid) begin
			@(negedge clk);
		end
	end
endtask : wait_out_valid_task

//----- Calculate Answer -----
task cal_ans_task;
	User_id user, seller;
	Action act;
	Item_id item;
	Item_num num;
	Money amnt;

	Error_Msg buy_err, sell_err;
	begin
		user = cur_input.getId_usr();
		seller = cur_input.getId_slr();
		act = cur_input.getAct();
		item = cur_input.getItem();
		num = cur_input.getNum();
		amnt = cur_input.getMoney();

		case (act)
			Buy: begin
				buy_err = info_table[user].buy_check(item, num);
				sell_err = info_table[seller].sell_check(item, num);
				if (buy_err==No_Err && sell_err==No_Err) begin
					info_table[user].buy(item, num, seller);
					info_table[seller].sell(item, num);
					golden_complete = 1;
					golden_err_msg = No_Err;
					golden_out_info = info_table[user].user_info;
				end
				else begin
					golden_complete = 0;
					golden_out_info = 0;
					if (buy_err==INV_Full)
						golden_err_msg = INV_Full;
					else if (sell_err==INV_Not_Enough)
						golden_err_msg = INV_Not_Enough;
					else
						golden_err_msg = Out_of_money;
				end 
			end

			Check: begin
				golden_complete = 1;
				golden_err_msg = 0;
				if (cur_input.getCheck())
					golden_out_info = {
						14'b0, 
						info_table[seller].shop_info.large_num, 
						info_table[seller].shop_info.medium_num, 
						info_table[seller].shop_info.small_num
					};
				else
					golden_out_info = {16'b0, info_table[user].user_info.money};
			end

			Deposit: begin
				golden_err_msg = info_table[user].deposit(amnt);
				golden_complete = (golden_err_msg==No_Err) ? 1: 0;
				golden_out_info = {16'b0, info_table[user].user_info.money};
			end

			Return: begin

			end

		endcase
	end
endtask : cal_ans_task

//----- Check Answer -----
task check_ans_task;
	
endtask : check_ans_task

endprogram