#include <iostream>
#include <fstream>
using namespace std;

//int iter = 0;

int eea(int x, int p) {
	static int iter;
	iter++;
	if (p%x==1) {
		int count = iter;
		iter = 0;
		return count;
	}
	return (eea(p%x, x));
}

int main() {
	ifstream fin("Prime.in");
	
	/*
	int x1, p1;
	cin >> x1 >> p1;
	cout << "Iteraction Max = " << eea(x1, p1) << endl;
	*/
	
	cout << "Width(5 or 6 or 7): ";
	int width;
	cin >> width;

	int xNum, pNum;
	if (width==5) {
		xNum = 31;
		pNum = 9;
	}
	else if (width==6) {
		xNum = 63;
		pNum = 16;
	}
	else if (width==7) {
		xNum = 127;
		pNum = 29;
	}
	else {
		cout << "Invalid Width" << endl;
		return 0;
	}

	
	int iterMax = 0, iterCur = 0;
	for (int i=0; i<pNum; i++) {
		int pIn;
		fin >> pIn;
		//cout << "p: " << pIn << endl;
		
		int xIn = 2;
		for (int j=0; j<xNum; j++) {
			if (xIn >= pIn) 
				break;
			iterCur = eea(xIn, pIn);
			cout << "x=" << xIn << " p="<< pIn << " iteraction=" << iterCur << endl;
			if (iterCur>iterMax) {
				//cout << "x=" << xIn << " p=" << pIn << endl;
				iterMax = iterCur;
			}
			xIn++;
		}
	}
	
	cout << "Iteraction Max = " << iterMax << endl;
	
	return 0;
}