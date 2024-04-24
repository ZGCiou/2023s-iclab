#include <iostream>
#include <iomanip>
#include <fstream>
#include <bitset>
#include <cmath>
#include <string>
using namespace std;

// Random Seed
const int SEED = 123;

// Directory
const string datFile_instr = "DRAM_inst.dat";
const string datFile_data = "DRAM_data.dat";

const string txtFile_instr_debug = "DRAM_inst_debug.txt";

// Address Parameter
const int baseAddr = 0x1000;
const int maxAddr = 0x1fff;
const int addrNum = maxAddr - baseAddr + 1;
const int wordSize = 2;
//const int MAXDATA = pow(2, 8*wordSize);

// Architecture Parameter
const int bitNum_op = 3;
const int bitNum_reg = 4;
const int bitNum_imm = 5;
const int bitNum_func = 1;
const int bitNum_jAddr = 13;

const int regNum = 16;

// Instruction Ratio
const int R = 70;
const int I_ls = 20;
const int I_b = 10;
const int I = I_ls + I_b;
const int J = 1;

int main() {
	srand(SEED);
	int curAddr;
	ofstream outFile_inst(datFile_instr);
	ofstream outFile_inst_debug(txtFile_instr_debug);

	for (int i=0; i<addrNum; i+=wordSize) {
		curAddr = baseAddr + i;
		outFile_inst << "@" << hex << curAddr << endl;
		outFile_inst_debug << "@" << hex << curAddr << "\t\tPC: " << dec << (i/2) << endl;

		int type = rand() % (R + I + J);
		string byte0Str;
		string byte1Str;

		int opInt, rsInt, rtInt, rdInt, funcInt, immInt, addrInt, last_ls_addr=baseAddr;
		int jumpDist, jumpDir;

		// R type
		if (type<R) {
			opInt = rand() % 2;
			funcInt = rand() % 2;
			rsInt = rand() % regNum;
			rtInt = rand() % regNum;
			do {
				rdInt = rand() % regNum;
			} while (rdInt==0);
			
			bitset<bitNum_op> op(opInt);
			bitset<bitNum_reg> rs(rsInt);
			bitset<bitNum_reg> rt(rtInt);
			bitset<bitNum_reg> rd(rdInt);
			bitset<bitNum_func> func(funcInt);

			byte1Str = op.to_string() + rs.to_string() + rt.to_string().substr(0,1);
			byte0Str = rt.to_string().substr(1,3) + rd.to_string() + func.to_string();

			// Debug
			if (opInt==0 && funcInt==0) outFile_inst_debug << "sub\t";
			else if (opInt==0 && funcInt==1) outFile_inst_debug << "add\t";
			else if (opInt==1 && funcInt==1) outFile_inst_debug << "slt\t";
			else if (opInt==1 && funcInt==0) outFile_inst_debug << "mul\t";
			outFile_inst_debug << dec << setw(2) << rsInt << " " << setw(2) << rtInt << " " << setw(2) << rdInt << endl;
		}
		// I type
		else if (type<R+I) {
			// opcode
			if (type<R+I_ls) // load, store
				opInt = rand() % 2 + 2;
			else // branch
				opInt = 5;

			// rs
			if (opInt==5) // branch
				rsInt = rand() % regNum;
			else // load, store
				rsInt = 0;

			// rt
			do {
				rtInt = rand() % regNum;
			} while (rtInt==0 && opInt==3); // If load to r0/r1, re-rand
			
			// imm
			if (opInt==5) {
				do {
					jumpDist = rand() % 65 - 32; // -32~32
					immInt = jumpDist;
					jumpDir = curAddr + wordSize + (jumpDist * wordSize); // curr_addr+2-64 ~ curr_addr+64
				} while ((jumpDir<baseAddr) || (jumpDir>maxAddr));
			}
			else {
				int i = 1;
				do {
					immInt = rand() % 64 - 32;  // -32~31
					jumpDir = immInt * 2 + baseAddr;
					//cout << i++ << endl;
				} while ((jumpDir<baseAddr) || (jumpDir>maxAddr) || (jumpDir>(last_ls_addr+64)) || (jumpDir<(last_ls_addr-62)));
				last_ls_addr = jumpDir;
			}

			bitset<bitNum_op> op(opInt);
			bitset<bitNum_reg> rs(rsInt);
			bitset<bitNum_reg> rt(rtInt);
			bitset<bitNum_imm> imm(immInt);

			byte1Str = op.to_string() + rs.to_string() + rt.to_string().substr(0,1);
			byte0Str = rt.to_string().substr(1,3) + imm.to_string();

			// Debug
			if (opInt==2) outFile_inst_debug << "sw\t";
			else if (opInt==3) outFile_inst_debug << "lw\t";
			else if (opInt==5) outFile_inst_debug << "beq\t";
			outFile_inst_debug << dec << setw(2) << rsInt << " " << setw(2) << rtInt << " " << immInt << endl;
		}
		// J type
		else {
			opInt = 4;

			do {
				jumpDist = rand() % 65 - 32; // -32~32
				addrInt = curAddr + wordSize + (jumpDist * wordSize); // curr_addr+2-64 ~ curr_addr+64
			} while ((addrInt<baseAddr) || (addrInt>maxAddr) || (addrInt==curAddr));
			
			bitset<bitNum_op> op(opInt);
			bitset<bitNum_jAddr> addr(addrInt);

			byte1Str = op.to_string() + addr.to_string().substr(0, 5);
			byte0Str = addr.to_string().substr(6, 8);

			// Debug
			outFile_inst_debug << "j\t";
			outFile_inst_debug  << "0x" << hex << addrInt << endl;
		}

		bitset<8> byte0(byte0Str);
		bitset<8> byte1(byte1Str);
		outFile_inst << hex << setw(2) << setfill('0') << byte0.to_ulong() << " " << setw(2) << setfill('0') << byte1.to_ulong() << endl;
		
		// Debug
		outFile_inst_debug << hex << setw(2) << setfill('0') << byte0.to_ulong() << " " << setw(2) << setfill('0') << byte1.to_ulong() << endl;
		outFile_inst_debug << "------------------------------------------" << endl;

	}
	outFile_inst.close();
	outFile_inst_debug.close();

	// Data Memory
	ofstream ouitFile_data(datFile_data);
	for (int i=0; i<addrNum; i+=wordSize) {
		curAddr = baseAddr + i;
		ouitFile_data << "@" << hex << curAddr << endl;
		for (int i=0; i<wordSize; i++) {
			bitset<8> byte(rand() % (int)pow(2,8));
			ouitFile_data << hex << setw(2) << setfill('0') << byte.to_ulong() << " ";
		}
		ouitFile_data << endl;
	}
	ouitFile_data.close();

	return 0;
}