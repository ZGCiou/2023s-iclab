`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"
`include "CHECKER.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// PARAMETER AND INTEGER DECLARATION
//================================================================
//---------- Parameter ----------
//++++++++++ User modification ++++++++++
parameter PAT_NUM = 1500;
parameter GEN_DAT = 0;
parameter SEED = 456;
parameter DRAM_PATH = "../00_TESTBED/DRAM/dram.dat";
//+++++++++++++++++++++++++++++++++++++++

//---------- Integer ----------
integer outFile;
integer pat_cnt = 0;
integer i;
//================================================================
// LOGIC AND USERTYPE DECLARATION 
//================================================================
//---------- Logic ----------
logic [7:0] dram ['h10000:'h107ff];

//---------- UserType ----------
s_OS_Output golden;

//================================================================
// CLASS DEFINITION
//================================================================
class c_INPUT_DATA;
	// Data Member
	rand User_id buyer_id;
	rand User_id seller_id;
	rand Action act;
	rand Item_id item;
	rand Item_num item_num;
	rand Money money;

	rand bit change_id;
	rand bit check_seller;
	rand integer gap[4];
	rand integer next_op_lat;
	
	// Constructor
	function new(int seed);
		this.srandom(seed);
		randomize();
	endfunction : new
	constraint limit_data {
		act inside {Buy, Check, Deposit, Return};
		item inside {Large, Medium, Small};
	}
	constraint limit_lat {
		foreach (gap[i]) gap[i] inside {[1:5]};
		(pat_cnt==0) -> change_id == 1;
		(pat_cnt==0) -> next_op_lat inside {[1:5]};
		(pat_cnt!=0) -> next_op_lat inside {[2:10]};
	}
	
	// Member Function
	function void setData(bit cid, User_id bid, User_id sid, Action a, Item_id i, Item_num n, Money m);
		change_id = cid;
		buyer_id = bid;
		seller_id = sid;
		act = a;
		item = i;
		item_num = n;
		money = m;
	endfunction : setData
	// Acessor
	function User_id getId_buyer();
		return buyer_id;
	endfunction : getId_buyer
		
	function User_id getId_slr();
		return seller_id;
	endfunction : getId_slr

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

	function void print();
		$display("-------------------");
		$display("Input No.%0d", pat_cnt);
		$display("change\t= %0d", change_id);
		$display("buyer id\t= %0d", buyer_id);
		$display("seller id\t= %0d", seller_id);
		$display("action\t= %0d", act);
		$display("item\t= %0d", item);
		$display("num\t= %0d", item_num);
		$display("amnt\t= %0d", money);
		$display("-------------------");
	endfunction : print

endclass : c_INPUT_DATA

class c_DATA;
	s_Proc_Data cur_data;
	c_INPUT_DATA new_data;

	// Constructor
	function new();
		cur_data = 0;
		new_data = new(SEED);
	endfunction : new

	// Member Function
	function void get_new_data();
		new_data.randomize();
		while (new_data.seller_id==cur_data.buyer || new_data.seller_id==new_data.buyer_id) new_data.randomize();
		if (new_data.change_id) cur_data.buyer = new_data.buyer_id;
		cur_data.seller = new_data.seller_id;
		cur_data.act = new_data.act;
		cur_data.item = new_data.item;
		cur_data.num = new_data.item_num;
		cur_data.amnt = new_data.money;
	endfunction : get_new_data

	function void get_new_data_set(bit cid, User_id bid, User_id sid, Action a, Item_id i, Item_num n, Money m);
		new_data.randomize();
		new_data.setData(cid, bid, sid, a, i, n, m);
		if (new_data.change_id) cur_data.buyer = new_data.buyer_id;
		cur_data.seller = new_data.seller_id;
		cur_data.act = new_data.act;
		cur_data.item = new_data.item;
		cur_data.num = new_data.item_num;
		cur_data.amnt = new_data.money;
	endfunction : get_new_data_set
endclass : c_DATA

class c_ACCOUNT_INFO;
	// Data Member
	rand Shop_Info shop_info;
	rand User_Info user_info;
	Return_Info return_info;

	// Method
	function new(int seed);
		this.srandom(seed);
		randomize();
		return_info = 'd0;
	endfunction : new
	constraint limit_shop_info {
		(shop_info.level==Platinum) -> shop_info.exp==0;
		(shop_info.level==Gold) -> shop_info.exp inside {[0:3999]};
		(shop_info.level==Silver) -> shop_info.exp inside {[0:2499]};
		(shop_info.level==Copper) -> shop_info.exp inside {[1:999]};
	}
	constraint limit_user_info {
		user_info.shop_history.item_ID inside {[1:3]};
	}

	function void setData(Shop_Info shopInfo, User_Info usrInfo);
		shop_info = shopInfo;
		user_info = usrInfo;
	endfunction : setData
endclass : c_ACCOUNT_INFO

class c_ONLINE_SHOP;
	// Data Member
	c_ACCOUNT_INFO account[256];
	User_id buyer, seller;
	t_Out_Info os_out_info;

	// Constructor
	function new();
		foreach (account[i]) begin
			account[i] = new(SEED+i);
		end
		buyer = 0;
		seller = 0;
		os_out_info = 0;
	endfunction : new

	// Member Function
	function void setBuyer(User_id buyer_id);
		buyer = buyer_id;
	endfunction : setBuyer

	function void setSeller(User_id seller_id);
		seller = seller_id;
	endfunction : setSeller

	function void setData_from_DRAM();
		integer addr, base = 'h10000;
		for (i=0; i<256; i=i+1) begin
			addr = base + i*8;
			account[i].shop_info = {dram[addr], dram[addr+1], dram[addr+2], dram[addr+3]};
			account[i].user_info = {dram[addr+4], dram[addr+5], dram[addr+6], dram[addr+7]};
		end
	endfunction : setData_from_DRAM

	function void dump_dat();
		integer addr, base = 'h10000;
		logic [31:0] data_shop, data_user;
		outFile = $fopen(DRAM_PATH,"w");
		for (i=0; i<256; i=i+1) begin
			addr = base + i*8;
			data_shop = {account[i].shop_info.large_num, account[i].shop_info.medium_num, account[i].shop_info.small_num, account[i].shop_info.level, account[i].shop_info.exp};
			data_user = {account[i].user_info.money, account[i].user_info.shop_history.item_ID, account[i].user_info.shop_history.item_num, account[i].user_info.shop_history.seller_ID};
			$fwrite(outFile,"@%5h\n",addr);
			$fwrite(outFile,"%h %h %h %h\n", data_shop[31:24], data_shop[23:16], data_shop[15:8], data_shop[7:0]);
			$fwrite(outFile,"@%5h\n",addr+4);
			$fwrite(outFile,"%h %h %h %h\n", data_user[31:24], data_user[23:16], data_user[15:8], data_user[7:0]);
		end
		$fclose(outFile);
	endfunction : dump_dat

	function t_Out_Info getOut_info();
		return os_out_info;
	endfunction : getOut_info

	function Error_Msg check(bit check_seller);
		logic [17:0] seller_stock;
		seller_stock = {account[seller].shop_info.large_num, account[seller].shop_info.medium_num, account[seller].shop_info.small_num};
		if (check_seller)
			account[seller].return_info.last_act = Other;
		account[buyer].return_info.last_act = Other;

		os_out_info = (check_seller) ? {14'b0, seller_stock} : {16'b0, account[buyer].user_info.money};
		return No_Err;
	endfunction : check

	function Error_Msg deposit(Money dep_amnt);
		integer money_new;
		os_out_info = 0;
		money_new = account[buyer].user_info.money + dep_amnt;
		if (money_new>65535)
			return Wallet_is_Full;
		account[buyer].user_info.money = money_new;

		account[buyer].return_info.last_act = Other;

		os_out_info = {16'b0, account[buyer].user_info.money};
		return No_Err;
	endfunction : deposit

	function Error_Msg buy(Item_id item, Item_num num);
		integer inv_buyer;
		integer price, deliver, total_price, total_fee;
		integer exp_per, total_exp;
		integer inv_seller;
		// Err Check
		os_out_info = 0;
		// User's inventory is full (1)
		case (item)
			Large: inv_buyer = account[buyer].shop_info.large_num;
			Medium: inv_buyer = account[buyer].shop_info.medium_num;
			Small: inv_buyer = account[buyer].shop_info.small_num;
			default : inv_buyer = 0;
		endcase
		if (inv_buyer+num > 63)
			return INV_Full;
		// Seller's inventory is not enough (2)
		case (item)
			Large: inv_seller = account[seller].shop_info.large_num;
			Medium: inv_seller = account[seller].shop_info.medium_num;
			Small: inv_seller = account[seller].shop_info.small_num;
			default : inv_seller = 0;
		endcase
		if (num > inv_seller)
			return INV_Not_Enough;
		// Out of money (3)
		case (item)
			Large: price = 300;
			Medium: price = 200;
			Small: price = 100;
			default : price = 0;
		endcase
		case (account[buyer].shop_info.level)
			Platinum: deliver = 10;
			Gold: deliver = 30;
			Silver: deliver = 50;
			Copper: deliver = 70;
		endcase
		total_price = price * num ;
		total_fee = total_price + deliver;
		if (total_fee > account[buyer].user_info.money)
			return Out_of_money;

		// Success
		// Buyer
		// - Inventory
		case (item)
			Large: account[buyer].shop_info.large_num = inv_buyer + num;
			Medium: account[buyer].shop_info.medium_num = inv_buyer + num;
			Small: account[buyer].shop_info.small_num = inv_buyer + num;
		endcase
		// - Money
		account[buyer].user_info.money = account[buyer].user_info.money - total_fee;
		// Level and Exp
		case (item)
			Large: exp_per = 60;
			Medium: exp_per = 40;
			Small: exp_per = 20;
			default : exp_per = 0;
		endcase
		total_exp = exp_per * num + account[buyer].shop_info.exp;
		case (account[buyer].shop_info.level)
			Gold: begin
				if (total_exp>=4000) begin
					account[buyer].shop_info.level = Platinum;
					account[buyer].shop_info.exp = 0;
				end
				else
					account[buyer].shop_info.exp = total_exp;
			end

			Silver: begin
				if (total_exp>=2500) begin
					account[buyer].shop_info.level = Gold;
					account[buyer].shop_info.exp = 0;
				end
				else
					account[buyer].shop_info.exp = total_exp;
			end

			Copper: begin
				if (total_exp>=1000) begin
					account[buyer].shop_info.level = Silver;
					account[buyer].shop_info.exp = 0;
				end
				else
					account[buyer].shop_info.exp = total_exp;
			end
		endcase
		// - Shop History
		account[buyer].user_info.shop_history.item_ID = item;
		account[buyer].user_info.shop_history.item_num = num;
		account[buyer].user_info.shop_history.seller_ID = seller;

		// Seller
		// - Inventory
		case (item)
			Large: account[seller].shop_info.large_num = account[seller].shop_info.large_num - num;
			Medium: account[seller].shop_info.medium_num = account[seller].shop_info.medium_num - num;
			Small: account[seller].shop_info.small_num = account[seller].shop_info.small_num - num;
		endcase
		// - Money
		if (account[seller].user_info.money + total_price < 65535)
			account[seller].user_info.money = account[seller].user_info.money + total_price;
		else
			account[seller].user_info.money = 65535;
		
		account[buyer].return_info.last_act = Buy_last;
		account[buyer].return_info.last_deal_id = seller;
		account[seller].return_info.last_act = Sell_last;
		account[seller].return_info.last_deal_id = buyer;

		os_out_info = account[buyer].user_info;
		return No_Err;
	endfunction : buy

	function Error_Msg return_deal(Item_id item, Item_num num);
		integer price, total_price;
		integer user_stock;
		logic return_sucess;
		return_sucess = (account[buyer].return_info.last_act==Buy_last && account[account[buyer].user_info.shop_history.seller_ID].return_info.last_act==Sell_last && account[account[buyer].user_info.shop_history.seller_ID].return_info.last_deal_id==buyer) ? 1'b1 : 1'b0;
		os_out_info = 0;
		// Err Check
		// Wrong operation (1)
		if (~return_sucess)
			return Wrong_act;
		// Wrong seller ID (2)
		if (account[buyer].user_info.shop_history.seller_ID!=seller)
			return Wrong_ID;
		// Wrong number (3)
		if (account[buyer].user_info.shop_history.item_num!=num)
			return Wrong_Num;
		// Wrong item (4)
		if (account[buyer].user_info.shop_history.item_ID!=item)
			return Wrong_Item;

		// Success
		// Buyer
		// - Inventory
		case (item)
			Large: account[buyer].shop_info.large_num = account[buyer].shop_info.large_num - num;
			Medium: account[buyer].shop_info.medium_num = account[buyer].shop_info.medium_num - num;
			Small: account[buyer].shop_info.small_num = account[buyer].shop_info.small_num - num;
		endcase
		// - Money
		case (item)
			Large: price = 300;
			Medium: price = 200;
			Small: price = 100;
			default : price = 0;
		endcase
		total_price = price * num ;
		account[buyer].user_info.money = account[buyer].user_info.money + total_price;

		// Seller
		// - Inventory
		case (item)
			Large: account[seller].shop_info.large_num = account[seller].shop_info.large_num + num;
			Medium: account[seller].shop_info.medium_num = account[seller].shop_info.medium_num + num;
			Small: account[seller].shop_info.small_num = account[seller].shop_info.small_num + num;
		endcase
		// - Money
		account[seller].user_info.money = account[seller].user_info.money - total_price;

		account[buyer].return_info.last_act = Other;
		account[seller].return_info.last_act = Other;
		user_stock = {account[buyer].shop_info.large_num, account[buyer].shop_info.medium_num, account[buyer].shop_info.small_num};
		os_out_info = {14'b0, user_stock};
		return No_Err;
	endfunction : return_deal
endclass : c_ONLINE_SHOP


//---------- Object Declaration ----------
c_ONLINE_SHOP online_shop = new();
c_DATA proc_data = new();

//================================================================
// INITIAL
//================================================================
initial begin
	dram_task;
	reset_task;
	for (pat_cnt=0; pat_cnt<PAT_NUM; pat_cnt=pat_cnt+1) begin
		input_task;
		cal_ans_task;
		wait_out_valid_task;
		check_ans_task;
		$display("PASS Pattern No.%0d", pat_cnt+1);
	end
	pass_task;
end

//================================================================
// TASK
//================================================================
//--------------- DRAM ---------------
task dram_task;
	begin
		if (GEN_DAT==1) online_shop.dump_dat();
		$readmemh(DRAM_PATH,dram);
		online_shop.setData_from_DRAM();
	end
endtask : dram_task

//--------------- Reset ---------------
task reset_task;
	begin
		inf.rst_n = 1'b1;
		inf.id_valid = 1'b0;
		inf.act_valid = 1'b0;
		inf.item_valid = 1'b0;
		inf.num_valid = 1'b0;
		inf.amnt_valid = 1'b0;
		inf.D = 'dx;

		#20 inf.rst_n = 1'b0;
		#10 inf.rst_n = 1'b1;
	end
endtask

//--------------- Input ---------------
task input_task;
	begin
		if (pat_cnt>60)
			proc_data.get_new_data();
		else begin
			data_task;
		end
		//proc_data.new_data.print();

		// Latency between operate
		repeat(proc_data.new_data.getLat()) @(negedge clk);
		// ID
		if (proc_data.new_data.getChange()) begin
			inf.id_valid = 1;
			inf.D = proc_data.new_data.getId_buyer();
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
			repeat(proc_data.new_data.getGap(0)) @(negedge clk);
		end
		// Action
		inf.act_valid = 1;
		inf.D = proc_data.new_data.getAct();
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;

		// Buy or Return
		if (proc_data.new_data.getAct()==Buy || proc_data.new_data.getAct()==Return) begin
			// Item
			repeat(proc_data.new_data.getGap(1)) @(negedge clk);
			inf.item_valid = 1;
			inf.D = proc_data.new_data.getItem();
			@(negedge clk);
			inf.item_valid = 0;
			inf.D = 'dx;

			// Item Number
			repeat(proc_data.new_data.getGap(2)) @(negedge clk);
			inf.num_valid = 1;
			inf.D = proc_data.new_data.getNum();
			@(negedge clk);
			inf.num_valid = 0;
			inf.D = 'dx;

			// Seller id
			repeat(proc_data.new_data.getGap(3)) @(negedge clk);
			inf.id_valid = 1;
			inf.D = proc_data.new_data.getId_slr();
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
		end

		// Deposit
		else if (proc_data.new_data.getAct()==Deposit) begin
			// Money
			repeat(proc_data.new_data.getGap(1)) @(negedge clk);
			inf.amnt_valid = 1;
			inf.D = proc_data.new_data.getMoney();
			@(negedge clk);
			inf.amnt_valid = 0;
			inf.D = 'dx;
		end

		// Check
		else if (proc_data.new_data.getAct()==Check) begin
			// Seller
			if (proc_data.new_data.getCheck()) begin
				repeat(proc_data.new_data.getGap(1)) @(negedge clk);
				inf.id_valid = 1;
				inf.D = proc_data.new_data.getId_slr();
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
			end
			else
				repeat(6) @(negedge clk);
		end
	end
endtask : input_task

task data_task;
	Error_Msg em_c;
	bit cid;
	User_id bid;
	User_id sid;
	Action a;
	Item_id i;
	Item_num n;
	Money m;
	begin
		if (pat_cnt==0)
			proc_data.get_new_data_set(1, 0, 1, Buy, Small, 1, 0);
		else if (pat_cnt==1)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 2, 0);
		else if (pat_cnt==2)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 3, 0);
		else if (pat_cnt==3)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 4, 0);
		else if (pat_cnt==4)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 5, 0);
		else if (pat_cnt==5)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 6, 0);
		else if (pat_cnt==6)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 7, 0);
		else if (pat_cnt==7)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 8, 0);
		else if (pat_cnt==8)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 9, 0);
		else if (pat_cnt==9)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 10, 0);
		else if (pat_cnt==10)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 11, 0);
		else if (pat_cnt==11)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 12, 0);
		else if (pat_cnt==12)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 13, 0);
		else if (pat_cnt==13)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 14, 0);
		else if (pat_cnt==14)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 15, 0);
		else if (pat_cnt==15)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 16, 0);
		else if (pat_cnt==16)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 17, 0);
		else if (pat_cnt==17)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 18, 0);
		else if (pat_cnt==18)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 19, 0);
		else if (pat_cnt==19)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 20, 0);
		else if (pat_cnt==20)
			proc_data.get_new_data_set(0, 0, 1, Return, Small, 21, 0);
		else if (pat_cnt==21)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==22)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==23)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==24)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==25)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==26)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==27)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==28)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==29)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==30)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==31)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==32)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==33)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==34)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==35)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==36)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==37)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==38)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==39)
			proc_data.get_new_data_set(0, 0, 1, Return, Medium, 1, 0);
		else if (pat_cnt==40)
			proc_data.get_new_data_set(0, 0, 1, Return, Large, 1, 0);
		else if (pat_cnt==41)
			proc_data.get_new_data_set(1, 2, 3, Buy, Medium, 1, 0);
		else if (pat_cnt==42)
			proc_data.get_new_data_set(0, 0, 4, Buy, Large, 1, 0);
		else if (pat_cnt==43)
			proc_data.get_new_data_set(0, 0, 5, Buy, Small, 1, 0);
		else if (pat_cnt==44)
			proc_data.get_new_data_set(0, 0, 6, Buy, Medium, 1, 0);
		else if (pat_cnt==45)
			proc_data.get_new_data_set(0, 0, 7, Buy, Large, 1, 0);
		else if (pat_cnt==46)
			proc_data.get_new_data_set(0, 0, 8, Buy, Small, 1, 0);
		else if (pat_cnt==47)
			proc_data.get_new_data_set(0, 0, 9, Buy, Medium, 1, 0);
		else if (pat_cnt==48)
			proc_data.get_new_data_set(0, 0, 10, Buy, Large, 1, 0);
		else if (pat_cnt==49)
			proc_data.get_new_data_set(0, 0, 11, Buy, Small, 1, 0);
		else if (pat_cnt==50)
			proc_data.get_new_data_set(0, 0, 12, Buy, Medium, 1, 0);
		else if (pat_cnt==51)
			proc_data.get_new_data_set(0, 0, 13, Buy, Large, 1, 0);
		else if (pat_cnt==52)
			proc_data.get_new_data_set(0, 0, 14, Buy, Small, 1, 0);
		else if (pat_cnt==53)
			proc_data.get_new_data_set(0, 0, 15, Buy, Medium, 1, 0);
		else if (pat_cnt==54)
			proc_data.get_new_data_set(0, 0, 16, Buy, Large, 1, 0);
		else if (pat_cnt==55)
			proc_data.get_new_data_set(0, 0, 17, Buy, Small, 1, 0);
		else if (pat_cnt==56)
			proc_data.get_new_data_set(0, 0, 18, Buy, Medium, 1, 0);
		else if (pat_cnt==57)
			proc_data.get_new_data_set(0, 0, 19, Buy, Large, 1, 0);
		else if (pat_cnt==58)
			proc_data.get_new_data_set(0, 0, 20, Buy, Small, 1, 0);
		else if (pat_cnt==59)
			proc_data.get_new_data_set(0, 0, 21, Buy, Medium, 1, 0);
		else if (pat_cnt==60)
			proc_data.get_new_data_set(0, 0, 22, Buy, Large, 1, 0);
	end
endtask : data_task

task taskname();
	
endtask : taskname

//--------------- Wait Out Valid ---------------
task wait_out_valid_task;
	begin
		while (~inf.out_valid) begin
			@(negedge clk);
		end
	end
endtask : wait_out_valid_task

//--------------- Calculate Answer ---------------
task cal_ans_task;
	begin
		online_shop.setBuyer(proc_data.cur_data.buyer);
		online_shop.setSeller(proc_data.cur_data.seller);
		case (proc_data.cur_data.act)
			Buy: 		golden.err_msg = online_shop.buy(proc_data.cur_data.item, proc_data.cur_data.num);
			Check: 		golden.err_msg = online_shop.check(proc_data.new_data.getCheck());
			Deposit: 	golden.err_msg = online_shop.deposit(proc_data.cur_data.amnt);
			Return: 	golden.err_msg = online_shop.return_deal(proc_data.cur_data.item, proc_data.cur_data.num);
		endcase
		golden.complete = (golden.err_msg==No_Err) ? 1'b1 : 1'b0;
		golden.out_info = online_shop.getOut_info();
	end
endtask : cal_ans_task

//--------------- Check Answer ---------------
task check_ans_task;
	begin
		if (inf.complete!=golden.complete || inf.out_info!=golden.out_info || inf.err_msg!=golden.err_msg) begin
			$display("Wrong Answer");
			repeat(5) @(negedge clk);
			$finish;
		end
	end
endtask : check_ans_task

//--------------- Pass ---------------
task pass_task;
	begin
		$display("--------------------------------------------------------------------");
	    $display("             ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~                 ");
	    $display("                                                                    ");
	    $display("                         Congratulations!                           ");
	    $display("                  You have passed all patterns!                     ");
	    $display("                                                                    ");
	    $display("--------------------------------------------------------------------");
	    repeat(2) @(negedge clk);
  		$finish;
	end
endtask : pass_task



endprogram