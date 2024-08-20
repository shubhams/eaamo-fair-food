#include <fstream>
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <algorithm>

using namespace std;

ifstream fin("lawschool.txt");
ofstream fout("lawschool_data.txt");

const int MAXN = 2099;
struct Data
{
	int cluster;
	double lsat, ugpa, zfygpa, zgpa;
	int bar1;
	double full, income;
	double age;
	int gender;
	int race[8];
};

Data a[MAXN];

int main()
{
	int n = 1;
	double t;
	while(fin >> t)
	{
		a[n].cluster = t + 0.01;
		fin >> a[n].lsat >> a[n].ugpa >> a[n].zfygpa >> a[n].zgpa;
		fin >> a[n].bar1;
		fin >> a[n].full >> a[n].income;
		fin >> a[n].age;
		fin >> a[n].gender;
		for(int i = 1; i <= 8; i++)
			fin >> a[n].race[i];
		
		for(int i = 1; i <= 6; i++)
		{
			if(a[n].cluster == i)
				fout << 1 << ' ';
			else
				fout << 0 << ' ';
		}
		fout << a[n].lsat << ' ' << a[n].ugpa << ' ' << a[n].zfygpa << ' ' << a[n].zgpa << ' ';
		fout << a[n].bar1 << ' ';
		fout << a[n].full << ' ' << a[n].income << ' ';
		fout << a[n].age << ' ';
		fout << a[n].gender;
		for(int i = 1; i <= 8; i++)
			fout << ' ' << a[n].race[i];
		fout << endl;
		n++;
	}
	n--;
	cout << n << endl;
	
	return 0;
}