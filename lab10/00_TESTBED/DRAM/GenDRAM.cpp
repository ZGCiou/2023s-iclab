#ifndef OS_INFO_H
#include "OS_info.h"
#endif

#include <fstream>
#include <iostream>
using namespace std;

const int SEED = 123;

int main() {
	int baseAddr = 0x10000, curAddr;
	ofstream fout("dram.dat");
	ofstream fout_debug("dram_info.txt");

	cout << "Choose Generate Mode: " << endl;
	cout << "1. Random Data" << endl;

	int mode;
	cin >> mode;

	if (mode==1) {
		srand(SEED);
		for (int i=0; i<256; i++) {
			OS_info info;
			curAddr = baseAddr + i*8;
			info.gen_dat(fout, curAddr, 0);
			info.gen_dat(fout_debug, curAddr, 1);

			/*
			// Shop Info
			fout << "@" << hex << curAddr << endl;
			fout << info.getDRAM_shop(1) << " " << info.getDRAM_shop(2) << " "  << info.getDRAM_shop(3) << " " << info.getDRAM_shop(4) << endl;
			//info.show_shop(fout);

			fout_debug << "@" << hex << curAddr << endl;
			fout_debug << info.getDRAM_shop(1) << " " << info.getDRAM_shop(2) << " "  << info.getDRAM_shop(3) << " " << info.getDRAM_shop(4) << endl;
			info.show_shop(fout_debug);

			// User Info
			fout << "@" << hex << curAddr + 4 << endl;
			fout << info.getDRAM_user(1) << " " << info.getDRAM_user(2) << " "  << info.getDRAM_user(3) << " " << info.getDRAM_user(4) << endl;
			//info.show_user(fout);

			fout_debug << "@" << hex << curAddr + 4 << endl;
			fout_debug << info.getDRAM_user(1) << " " << info.getDRAM_user(2) << " "  << info.getDRAM_user(3) << " " << info.getDRAM_user(4) << endl;
			info.show_user(fout_debug);
			*/
		}
	}


	return 0;
}
