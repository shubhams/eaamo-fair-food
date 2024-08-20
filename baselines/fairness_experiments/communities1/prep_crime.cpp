#include <fstream>
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <algorithm>

using namespace std;

ifstream fin("communities.txt");
ofstream fout("communities_data.txt");

const int MAXN = 2099;
struct Data
{
	int num;
	double population;
	double householdsize;
	double pctB, pctW, pctA, pctH; //Race
	double age1, age2, age3, age4;
	double numU, perU; //Urban
	double medIncome,pctWWage,pctWFarmSelf,pctWInvInc,pctWSocSec,pctWPubAsst,pctWRetire,medFamInc,perCapInc,
		whitePerCap,blackPerCap,indianPerCap,AsianPerCap,OtherPerCap,HispPerCap,NumUnderPov,PctPopUnderPov; //Income
	double PctLess9thGrade,PctNotHSGrad,PctBSorMore; //Education
	double PctUnemployed,PctEmploy,PctEmplManu,PctEmplProfServ,PctOccupManu,PctOccupMgmtProf; //Employment and Occupation
	double MalePctDivorce,MalePctNevMarr,FemalePctDiv,TotalPctDiv,PersPerFam,
		PctFam2Par,PctKids2Par,PctYoungKids2Par,PctTeen2Par,PctWorkMomYoungKids,PctWorkMom,NumIlleg,PctIlleg; //Marital Status and (Some) Household Structure
	double NumImmig,PctImmigRecent,PctImmigRec5,PctImmigRec8,PctImmigRec10,PctRecentImmig,PctRecImmig5,PctRecImmig8,PctRecImmig10,PctSpeakEnglOnly,PctNotSpeakEnglWell; //Immigration
	double PctLargHouseFam,PctLargHouseOccup,PersPerOccupHous,PersPerOwnOccHous,PersPerRentOccHous,PctPersOwnOccup,PctPersDenseHous,PctHousLess3BR,MedNumBR,
		HousVacant,PctHousOccup,PctHousOwnOcc,PctVacantBoarded,PctVacMore6Mos,MedYrHousBuilt,PctHousNoPhone,PctWOFullPlumb,OwnOccLowQuart,OwnOccMedVal,OwnOccHiQuart,
		RentLowQ,RentMedian,RentHighQ,MedRent,MedRentPctHousInc,MedOwnCostPctInc,MedOwnCostPctIncNoMtg,NumInShelters,NumStreet,PctForeignBorn,PctBornSameState,
		PctSameHouse85,PctSameCity85,PctSameState85; //Misc
	double LemasSwornFT,LemasSwFTPerPop,LemasSwFTFieldOps,LemasSwFTFieldPerPop,LemasTotalReq,LemasTotReqPerPop,
		PolicReqPerOffic,PolicPerPop,RacialMatchCommPol,PctPolicWhite,PctPolicBlack,PctPolicHisp,PctPolicAsian,PctPolicMinor,OfficAssgnDrugUnits,NumKindsDrugsSeiz,
		PolicAveOTWorked,LandArea,PopDens,PctUsePubTrans,PolicCars,PolicOperBudg,LemasPctPolicOnPatr,LemasGangUnitDeploy,LemasPctOfficDrugUn,PolicBudgPerPop; //Police
	double ViolentCrimesPP;
};

Data a[MAXN];

int main()
{
	cout << (sizeof(a[1]) - 4 + 4) / 8 << endl;
	int n = 1;
	while(fin >> a[n].num)
	{
		fin >> a[n].population;
		fin >> a[n].householdsize;
		fin >> a[n].pctB >> a[n].pctW >> a[n].pctA >> a[n].pctH;
		fin >> a[n].age1 >> a[n].age2 >> a[n].age3 >> a[n].age4;
		fin >> a[n].numU >> a[n].perU;
		fin >> a[n].medIncome >> a[n].pctWWage >> a[n].pctWFarmSelf >> a[n].pctWInvInc >> a[n].pctWSocSec >> a[n].pctWPubAsst >> a[n].pctWRetire >> a[n].medFamInc >> a[n].perCapInc >>
			a[n]. whitePerCap >> a[n].blackPerCap >> a[n].indianPerCap >> a[n].AsianPerCap >> a[n].OtherPerCap >> a[n].HispPerCap >> a[n].NumUnderPov >> a[n].PctPopUnderPov;
		fin >> a[n].PctLess9thGrade >> a[n].PctNotHSGrad >> a[n].PctBSorMore;
		fin >> a[n].PctUnemployed >> a[n].PctEmploy >> a[n].PctEmplManu >> a[n].PctEmplProfServ >> a[n].PctOccupManu >> a[n].PctOccupMgmtProf;
		fin >> a[n].MalePctDivorce >> a[n].MalePctNevMarr >> a[n].FemalePctDiv >> a[n].TotalPctDiv >> a[n].PersPerFam >> a[n]. PctFam2Par >>
			a[n].PctKids2Par >> a[n].PctYoungKids2Par >> a[n].PctTeen2Par >> a[n].PctWorkMomYoungKids >> a[n].PctWorkMom >> a[n].NumIlleg >> a[n].PctIlleg;
		fin >> a[n].NumImmig >> a[n].PctImmigRecent >> a[n].PctImmigRec5 >> a[n].PctImmigRec8 >> a[n].PctImmigRec10 >> a[n].PctRecentImmig >>
			a[n].PctRecImmig5 >> a[n].PctRecImmig8 >> a[n].PctRecImmig10 >> a[n].PctSpeakEnglOnly >> a[n].PctNotSpeakEnglWell;
		fin >> a[n].PctLargHouseFam >> a[n].PctLargHouseOccup >> a[n].PersPerOccupHous >> a[n].PersPerOwnOccHous >> a[n].PersPerRentOccHous >> a[n].PctPersOwnOccup >>
			a[n].PctPersDenseHous >> a[n].PctHousLess3BR >> a[n].MedNumBR >> a[n].HousVacant >> a[n].PctHousOccup >> a[n].PctHousOwnOcc >> a[n].PctVacantBoarded >>
			a[n].PctVacMore6Mos >> a[n].MedYrHousBuilt >> a[n].PctHousNoPhone >> a[n].PctWOFullPlumb >> a[n].OwnOccLowQuart >> a[n].OwnOccMedVal >> a[n].OwnOccHiQuart >>
			a[n].RentLowQ >> a[n].RentMedian >> a[n].RentHighQ >> a[n].MedRent >> a[n].MedRentPctHousInc >> a[n].MedOwnCostPctInc >> a[n].MedOwnCostPctIncNoMtg >>
			a[n].NumInShelters >> a[n].NumStreet >> a[n].PctForeignBorn >> a[n].PctBornSameState >> a[n].PctSameHouse85 >> a[n].PctSameCity85 >> a[n].PctSameState85;
		fin >> a[n].LemasSwornFT >> a[n].LemasSwFTPerPop >> a[n].LemasSwFTFieldOps >> a[n].LemasSwFTFieldPerPop >> a[n].LemasTotalReq >>
			a[n].LemasTotReqPerPop >> a[n].PolicReqPerOffic >> a[n].PolicPerPop >> a[n].RacialMatchCommPol >> a[n].PctPolicWhite >> a[n].PctPolicBlack >>
			a[n].PctPolicHisp >> a[n].PctPolicAsian >> a[n].PctPolicMinor >> a[n].OfficAssgnDrugUnits >> a[n].NumKindsDrugsSeiz >> a[n].PolicAveOTWorked >>
			a[n].LandArea >> a[n].PopDens >> a[n].PctUsePubTrans >> a[n].PolicCars >> a[n].PolicOperBudg >> a[n].LemasPctPolicOnPatr >>
			a[n].LemasGangUnitDeploy >> a[n].LemasPctOfficDrugUn >> a[n].PolicBudgPerPop;
		fin >> a[n].ViolentCrimesPP;
		
		
		fout << a[n].population;
		fout << ' ' << a[n].householdsize;
		fout << ' ' << (a[n].pctB > 0.39999 ? 1: 0) << ' ' << (a[n].pctW > 0.39999 ? 1: 0) << ' ' << (a[n].pctA > 0.39999 ? 1: 0) << ' ' << (a[n].pctH > 0.39999 ? 1: 0);
		fout << ' ' << a[n].age1 << ' ' << a[n].age2 << ' ' << a[n].age3 << ' ' << a[n].age4;
		fout << ' ' << a[n].numU << ' ' << a[n].perU;
		fout << ' ' << a[n].medIncome << ' ' << a[n].pctWWage << ' ' << a[n].pctWFarmSelf << ' ' << a[n].pctWInvInc << ' ' << a[n].pctWSocSec << ' ' << a[n].pctWPubAsst << ' ' << a[n].pctWRetire << ' ' << a[n].medFamInc << ' ' << a[n].perCapInc << ' ' <<
			a[n]. whitePerCap << ' ' << a[n].blackPerCap << ' ' << a[n].indianPerCap << ' ' << a[n].AsianPerCap << ' ' << a[n].OtherPerCap << ' ' << a[n].HispPerCap << ' ' << a[n].NumUnderPov << ' ' << a[n].PctPopUnderPov;
		fout << ' ' << a[n].PctLess9thGrade << ' ' << a[n].PctNotHSGrad << ' ' << a[n].PctBSorMore;
		fout << ' ' << a[n].PctUnemployed << ' ' << a[n].PctEmploy << ' ' << a[n].PctEmplManu << ' ' << a[n].PctEmplProfServ << ' ' << a[n].PctOccupManu << ' ' << a[n].PctOccupMgmtProf;
		fout << ' ' << a[n].MalePctDivorce << ' ' << a[n].MalePctNevMarr << ' ' << a[n].FemalePctDiv << ' ' << a[n].TotalPctDiv << ' ' << a[n].PersPerFam << ' ' << a[n]. PctFam2Par << ' ' <<
			a[n].PctKids2Par << ' ' << a[n].PctYoungKids2Par << ' ' << a[n].PctTeen2Par << ' ' << a[n].PctWorkMomYoungKids << ' ' << a[n].PctWorkMom << ' ' << a[n].NumIlleg << ' ' << a[n].PctIlleg;
		fout << ' ' << a[n].NumImmig << ' ' << a[n].PctImmigRecent << ' ' << a[n].PctImmigRec5 << ' ' << a[n].PctImmigRec8 << ' ' << a[n].PctImmigRec10 << ' ' << a[n].PctRecentImmig << ' ' <<
			a[n].PctRecImmig5 << ' ' << a[n].PctRecImmig8 << ' ' << a[n].PctRecImmig10 << ' ' << a[n].PctSpeakEnglOnly << ' ' << a[n].PctNotSpeakEnglWell;
		fout << ' ' << a[n].PctLargHouseFam << ' ' << a[n].PctLargHouseOccup << ' ' << a[n].PersPerOccupHous << ' ' << a[n].PersPerOwnOccHous << ' ' << a[n].PersPerRentOccHous << ' ' << a[n].PctPersOwnOccup << ' ' <<
			a[n].PctPersDenseHous << ' ' << a[n].PctHousLess3BR << ' ' << a[n].MedNumBR << ' ' << a[n].HousVacant << ' ' << a[n].PctHousOccup << ' ' << a[n].PctHousOwnOcc << ' ' << a[n].PctVacantBoarded << ' ' <<
			a[n].PctVacMore6Mos << ' ' << a[n].MedYrHousBuilt << ' ' << a[n].PctHousNoPhone << ' ' << a[n].PctWOFullPlumb << ' ' << a[n].OwnOccLowQuart << ' ' << a[n].OwnOccMedVal << ' ' << a[n].OwnOccHiQuart << ' ' <<
			a[n].RentLowQ << ' ' << a[n].RentMedian << ' ' << a[n].RentHighQ << ' ' << a[n].MedRent << ' ' << a[n].MedRentPctHousInc << ' ' << a[n].MedOwnCostPctInc << ' ' << a[n].MedOwnCostPctIncNoMtg << ' ' <<
			a[n].NumInShelters << ' ' << a[n].NumStreet << ' ' << a[n].PctForeignBorn << ' ' << a[n].PctBornSameState << ' ' << a[n].PctSameHouse85 << ' ' << a[n].PctSameCity85 << ' ' << a[n].PctSameState85;
		fout << ' ' << a[n].LemasSwornFT << ' ' << a[n].LemasSwFTPerPop << ' ' << a[n].LemasSwFTFieldOps << ' ' << a[n].LemasSwFTFieldPerPop << ' ' << a[n].LemasTotalReq << ' ' <<
			a[n].LemasTotReqPerPop << ' ' << a[n].PolicReqPerOffic << ' ' << a[n].PolicPerPop << ' ' << a[n].RacialMatchCommPol << ' ' << a[n].PctPolicWhite << ' ' << a[n].PctPolicBlack << ' ' <<
			a[n].PctPolicHisp << ' ' << a[n].PctPolicAsian << ' ' << a[n].PctPolicMinor << ' ' << a[n].OfficAssgnDrugUnits << ' ' << a[n].NumKindsDrugsSeiz << ' ' << a[n].PolicAveOTWorked << ' ' <<
			a[n].LandArea << ' ' << a[n].PopDens << ' ' << a[n].PctUsePubTrans << ' ' << a[n].PolicCars << ' ' << a[n].PolicOperBudg << ' ' << a[n].LemasPctPolicOnPatr << ' ' <<
			a[n].LemasGangUnitDeploy << ' ' << a[n].LemasPctOfficDrugUn << ' ' << a[n].PolicBudgPerPop;
		fout << ' ' << a[n].ViolentCrimesPP;
		
		fout << endl;
		
		n++;
	}
	n--;
	cout << n << endl;
	
	return 0;
}