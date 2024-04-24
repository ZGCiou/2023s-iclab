#include <iostream>
#include <fstream>
using namespace std;

const int SEED = 123;

int main() {
    srand(SEED);
    ofstream fout("pseudo_DRAM.dat");
    int baseAddr = 0x1000, curAddr;
    for (int i=0; i<0x1000; i++) {
        curAddr = baseAddr + i;
        fout << "@" << hex << curAddr << endl;
        fout << hex << rand() % 32 << " " << rand() % 32 << " " << rand() % 32 << " " << rand() % 32 << endl;
    }
    return 0;
}
