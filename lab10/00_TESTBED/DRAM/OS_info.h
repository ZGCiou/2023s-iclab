#ifndef OS_INFO_H
#define OS_INFO_H
#include <fstream>
using namespace std;

struct Stock {
	int largeNum, mediumNum, smallNum;
};

struct Shop_info {
	Stock stock;
	int level;
	int exp;
};

struct Shop_history {
	int item;
	int itemNum;
	int seller;
};

struct User_info {
	int money;
	Shop_history shop_his;
};

struct DRAM_DATA {
	int b1, b2, b3, b4;
};

class OS_info {
	private:
		Shop_info shop_info;
		User_info user_info;
		DRAM_DATA shop_dram, user_dram;
	public:
		OS_info();
		//~OS_info();
		void refresh_data();
		int getDRAM_shop(int) const;
		int getDRAM_user(int) const;
		void show_shop(ofstream&);
		void show_user(ofstream&);
		void gen_dat(ofstream&, int, int);
};

#endif
