#include <fstream>
using namespace std;
int main()
{
	ofstream fout("tmp.txt");
	for(int i = 6; i <= 123; i++)
	{
		
		fout << " \'a" << i << "\',";
	}
	return 0;
}
