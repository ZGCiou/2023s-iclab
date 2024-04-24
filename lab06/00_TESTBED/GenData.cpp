#include <iostream>
#include <fstream>
using namespace std;

const int SEED = 123;
int currentPrime;

int invPF(int);
int modP(int);
int main() {
	int prime[16] = {5, 7 ,11 ,13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};
	cout << "PAT_NUM = ";
	int patNum;
	cin >> patNum;
	ofstream foutOUT("GoldOut.txt");
	ofstream foutIN("InData.txt");
	foutIN << "PAT_NUM="<< patNum << endl;

	srand(SEED);
	for (int i=0; i<patNum; i++) {
		// Generate INPUT
		int in_prime;
		int in_Px, in_Py, in_Qx, in_Qy; //Range: 0 ~ Prime-1
		int in_a; //Range: 0~63

		// i = 0~4 -> Small Random INPUT P!=Q
		if (i<5) {
			in_prime = prime[rand()%2];
			currentPrime = in_prime;
			in_Px = rand()%(currentPrime);
			in_Py = rand()%(currentPrime);
			in_a = rand()%64;
			do {
				in_Qx = rand()%(currentPrime);
				in_Qy = rand()%(currentPrime);
			} while (in_Qx==in_Px && in_Qy!=in_Py || in_Qx==in_Px && in_Qy==in_Py && in_Py==0);
		}
		// i = 5~9 -> Small Random INPUT P=Q
		else if (i>4 && i<10) {
			in_prime = prime[rand()%2];
			currentPrime = in_prime;
			in_Px = rand()%(currentPrime);
			do {
				in_Py = rand()%(currentPrime);
			} while (in_Py==0);
			in_a = rand()%64;
			in_Qx = in_Px;
			in_Qy = in_Py;
		}
		// i = 10 -> Big Number INPUT P!=Q
		else if (i == 10) {
			in_prime = prime[15];
			currentPrime = in_prime;
			in_Px = 60;
			in_Py = 60;
			in_a = 63;
			in_Qx = 59;
			in_Qy = 59;
		}
		// i = 11 -> Big Number INPUT P=Q
		else if (i == 11) {
			in_prime = prime[15];
			currentPrime = in_prime;
			in_Px = 60;
			in_Py = 60;
			in_a = 63;
			in_Qx = in_Px;
			in_Qy = in_Py;
		}
		else if (i>11 && i<31) {
			in_prime = prime[15];
			currentPrime = in_prime;
			in_Px = rand()%(currentPrime);
			in_Py = rand()%(currentPrime);
			in_a = rand()%64;
			do {
				in_Qx = rand()%(currentPrime);
				in_Qy = rand()%(currentPrime);
			} while (in_Qx==in_Px && in_Qy!=in_Py || in_Qx==in_Px && in_Qy==in_Py && in_Py==0);
		}
		else if (i >30 && i<50) {
			in_prime = prime[15];
			currentPrime = in_prime;
			in_Px = rand()%(currentPrime);
			do {
				in_Py = rand()%(currentPrime);
			} while (in_Py==0);
			in_a = rand()%64;
			in_Qx = in_Px;
			in_Qy = in_Py;
		}

		else {
			in_prime = prime[rand()%16];
			currentPrime = in_prime;
			in_Px = rand()%(currentPrime);
			in_Py = rand()%(currentPrime);
			in_a = rand()%64;
			do {
				in_Qx = rand()%(currentPrime);
				in_Qy = rand()%(currentPrime);
			} while (in_Qx==in_Px && in_Qy!=in_Py || in_Qx==in_Px && in_Qy==in_Py && in_Py==0);
		}

		// Write INPUT
		foutIN /*<< "in_prime="*/ << in_prime << " "
			   /*<< "in_Px="*/ << in_Px  << " "
			   /*<< "in_Py="*/ << in_Py << " "
			   /*<< "in_Qx="*/ << in_Qx << " "
			   /*<< "in_Qy="*/ << in_Qy << " "
			   /*<< "in_a="*/ << in_a << endl;

		// Calculate OUTPUT
		int out_Rx, out_Ry, s;
		if (in_Px==in_Qx && in_Py==in_Qy)
			s = modP((3 * in_Px * in_Px + in_a) * invPF(modP(2*in_Py)));
		else
			s = modP(modP(in_Qy - in_Py) * invPF(modP(in_Qx-in_Px)));
		out_Rx = modP(s * s - in_Px - in_Qx);
		out_Ry = modP(s * modP(in_Px - out_Rx) - in_Py);

		// Write OUTPUT
		foutOUT /*<< "out_Rx="*/ << out_Rx << " " /*<<"out_Ry="*/ << out_Ry << " s = " << s << endl;
	}


	return 0;
}

int invPF(int x) { //x=1 ~ Prime-1
	if (x==1)
		return 1;
	for (int i=1; i<currentPrime; i++) {
		if ((x*i)%currentPrime == 1)
			return i;
	}
}

int modP(int n) {
	while (n<0) {
		n += currentPrime;
	}
	return n%currentPrime;
}