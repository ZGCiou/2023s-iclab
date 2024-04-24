#include "OS_info.h"
#include <cmath>
#include <iomanip>
using namespace std;

const int USER_LIMIT = 256;

const int PLATINUM = 0;
const int GOLD = 1;
const int SILVER = 2;
const int COPPER = 3;
const int LEVEL_LIMIT = 4;

const int LARGE = 1;
const int MEDIUM = 2;
const int SMALL = 3;

const int ITEM_NUM_LIMIT = 64;
const int MONEY_LIMIT = 65536;

OS_info::OS_info() {
	// shop_info
	shop_info.stock.largeNum = rand() % ITEM_NUM_LIMIT;
	shop_info.stock.mediumNum = rand() % ITEM_NUM_LIMIT;
	shop_info.stock.smallNum = rand() % ITEM_NUM_LIMIT;
	shop_info.level = rand() % LEVEL_LIMIT;

	if (shop_info.level==PLATINUM)
		shop_info.exp = 0;
	else if (shop_info.level==GOLD)
		shop_info.exp = rand() % 4000;
	else if (shop_info.level = SILVER)
		shop_info.exp = rand() % 2500;
	else
		shop_info.exp = rand() % 1000;

	// user_info
	user_info.money = rand() % MONEY_LIMIT;
	user_info.shop_his.item = rand() % 3 + 1;
	user_info.shop_his.itemNum = rand() % ITEM_NUM_LIMIT;
	user_info.shop_his.seller = rand() % USER_LIMIT;

	refresh_data();
}

void OS_info::refresh_data() {
	long shop, user;
	shop = shop_info.exp + pow(2,12)*shop_info.level 
		+ pow(2,14)*shop_info.stock.smallNum + pow(2,20)*shop_info.stock.mediumNum + pow(2,26)*shop_info.stock.largeNum;
	user = user_info.shop_his.seller + pow(2,8)*user_info.shop_his.itemNum + pow(2,14)*user_info.shop_his.item 
		+ pow(2,16)*user_info.money;

	shop_dram.b4 = shop % 256;
	shop /= 256;
	shop_dram.b3 = shop % 256;
	shop /= 256;
	shop_dram.b2 = shop % 256;
	shop /= 256;
	shop_dram.b1 = shop;

	user_dram.b4 = user % 256;
	user /= 256;
	user_dram.b3 = user % 256;
	user /= 256;
	user_dram.b2 = user % 256;
	user /= 256;
	user_dram.b1 = user;
}

int OS_info::getDRAM_shop(int x) const {
	if (x==1)
		return shop_dram.b1;
	else if (x==2)
		return shop_dram.b2;
	else if (x==3)
		return shop_dram.b3;
	else if (x==4)
		return shop_dram.b4;
}

int OS_info::getDRAM_user(int x) const {
	if (x==1)
		return user_dram.b1;
	else if (x==2)
		return user_dram.b2;
	else if (x==3)
		return user_dram.b3;
	else if (x==4)
		return user_dram.b4;
}

void OS_info::show_shop(ofstream &fout) {
	fout << "Large \tMedium\t Small\t Level\t Exp" << endl;
	fout << dec << setw(5) << shop_info.stock.largeNum << " \t" << setw(5) << shop_info.stock.mediumNum << " \t" << setw(5) << shop_info.stock.smallNum << " \t";
	fout << setw(5) << shop_info.level << " \t" << setw(4) << shop_info.exp << endl;
	fout << "-------------------------------------" << endl;
}

void OS_info::show_user(ofstream &fout) {
	fout << "Money \tItem \t Item_Num\t Seller" << endl;
	fout << dec << setw(5) << user_info.money << " \t" << setw(4) << user_info.shop_his.item << " \t" << setw(8) << user_info.shop_his.itemNum << " \t" << setw(6) << user_info.shop_his.seller << endl;
	fout << "-------------------------------------" << endl;
}

void OS_info::gen_dat(ofstream& fout, int addr, int debug) {
	// Shop Info
	fout << "@" << hex << addr << endl;
	fout << shop_dram.b1 << " " << shop_dram.b2 << " "  << shop_dram.b3 << " " << shop_dram.b4 << endl;
	if (debug) show_shop(fout);

	// User Info
	fout << "@" << hex << addr + 4 << endl;
	fout << user_dram.b1 << " " << user_dram.b2 << " "  << user_dram.b3 << " " << user_dram.b4 << endl;
	if (debug) show_user(fout);
}