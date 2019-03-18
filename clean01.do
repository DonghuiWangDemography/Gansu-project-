*Project: Gansu survey of Children and family;
*Created 11/21/2018
*Task : data cleaning & merge 
*notes: Derived from Datamanagement_v2.do; revise codes
*updated : 03/01/2019: add more villiage level attributes 

*ssc install unique
*ssc install egenmore

clear all 
clear matrix 
set more off 
capture log close 

global date "03012019"   // yymmdd
global dir "C:\Users\donghuiw\Desktop\GansuChildren"  //office

global images "${dir}\images"
global tables "${dir}\tables"
global data   "${dir}\data"


global c00 "${data}\2000\child2000t.dta"    // child survey 
global hh00 "${data}\2000\hh2000ts.dta"
global v00 "${data}\2000\vill2000.dta" 
global v00 "${data}\2000\vill2000.dta"

global cog00 "${data}\2000\litracy2000t.dta"
global test00 "${data}\2000\achieve2000t.dta"
global c09 "${data}\2009\child2009t.dta"
global cross "${data}\GSCF_merge_pid_to2009.dta"

*===========2000 Villiage level characheristics=========== 

use $v00, clear 

*migration network 
clonevar pop=vb1b
clonevar nmale=vb1c
clonevar nfemale=vb1d
*assert pop==nmale+nfemale  // only 4contraditions, which is fine. leave as it is 
*list nmale nfemale pop if pop != nmale+nfemale 
*replace pop=nmale+nfemale  if nmale>0 & nfemale>0 

g mig_long=(vb1k+vb1l)/pop
* set negative as missing
replace vb1m=. if vb1m<0
replace vb1n=. if vb1n<0
g mig_short=(vb1m+vb1n)/pop
egen mig_p=rowtotal(vb1k vb1l vb1m vb1n)
g vmig_all=mig_p/pop   
drop mig_p


*local business
local co1 "ve6 ve7 ve8 ve9"           // if has local enterprise 
local co2 "ve61 ve7a ve8a ve9a "      // number of enterprise 
*local co3 ""
local co4 "ve6a1 ve7b1 ve8b1 ve9b1 "  // how many local hire 
local co "ve6 ve7 ve8 ve9 ve61 ve7a ve8a ve9a ve6a1 ve7b1 ve8b1 ve9b1"

foreach x of local co{
tab `x',m 
replace `x'=. if `x'<0 
 }

egen vcomp=anycount(`co1'), values(1)
egen vncomp=rowtotal(`co2')

clonevar vroades=vc6 // nearest roades 

replace ve3=0 if ve3==-2 
ge vnonaghh=ve3/vb1a  // percentage hh work on non ag 
la var vnonaghh "percentages hh work on non-ag sector"

g vnearmiddle=2-vf12 // middle school near by
g vhighsch=2-vf14  // high school nearby 

replace vf15=. if vf15<0
g vtech=2-vf15  //vocational high school near by : 2 missing 
keep villid  a1 a2 a3 vroades  vnonaghh vnearmiddle vhighsch vtech vmig_all vcomp vncomp mig_long mig_short vncomp

save "${data}\vill2000ts.dta", replace 


*=========hh data====================
use $hh00 ,clear
g villid=a1*10000+a2*100+a3
clonevar osex=h0103_01
clonevar obirth=h0104_01   //birth year
clonevar obirm = h0105_01
clonevar oethnic=h0106_01 //  may be no need 
g kidgardern=(h0301_01==1)
 
g dob=ym(h0104_01,obirm)
g dob_f=ym(h0104_02,h0105_02)
g dob_m=ym(h0104_03,h0105_03)
g wave4=ym(2009,2)
format dob*  wave4  %tm
g age= int((wave4-dob)/12)
g age_f=int((wave4-dob_f)/12)
g age_m=int(int((wave4-dob_m)/12))

*dad 1,997 respondents are father 
g ded=h0110_02 if  h0102_02==2 // highest education 
g dilliter=(h0111_02==1|h0112_02==1) if h0102_02==2 
g dadstay= h0115_02  if h0102_02==2 // length of stay at home 

*mom 1,996 respondents are monther  
g med=h0110_03 if  h0102_03==3 // 
g milliter=(h0111_03==1|h0112_03==1) if h0102_03==3 
g momstay=h0115_03  if h0102_03==3 



* count siblings
local sib "h0102_04 h0102_05 h0102_06 h0102_07 h0102_08 h0102_09 h0102_10 h0102_11 h0102_13 h0102_14 h0102_15"

foreach v of local sib{
gen sib`v'=0
replace sib`v'=1 if `v' >=21 &`v'<57 & `v' !=.  // refer to qinshu guanxi kapian 
tab sib`v'
}
egen sibling = rcount(sibh0102_04-sibh0102_15), cond(@ == 1) 
tab sibling


*health
gen goodhlth=(h0801_01==1|h0801_01==2)
g  goodhlth_f=(h0801_02==1|h0801_02==2)
g  goodhlth_m=(h0801_03==1|h0801_03==2)


* Family wealth: total value of house, equipment and durable goods
* follow Zhang, Yuping, Grace Kao, and Emily Hannum. "Do mothers in rural China practice gender equality in educational aspirations for their children?."
g house=h2406+h2408 //estimated present value of the house+ consturction materials stored at home

*durable goods 
foreach x of numlist 1/9 {
rename h2601_0`x' h2601_`x' 
rename h2602_0`x' h2602_`x' 
}

forvalues i=1(1)38 {
gen t260_`i'=h2601_`i'*h2602_`i' 
}
egen tgoods=rowtotal(t260_*)
g wealth=house+tgoods
g lwealth=log(wealth)
*histogram  lwealth


g roadkm=h1101_01  // distance to the nearest public road in km
g roadmin=h1102_01 // distance to the nearest public road in minitus 
g badyield=(h1306==4| h1306==5)

keep  hhid villid age* osex obirth oethnic  *birth *ed *illiter *stay road* lwealth sibling goodhlth*  ///
	  kidgardern badyield
save "${data}\hh00.dta" , replace 


use $c09 ,clear
foreach x of varlist _all {
rename `x' `x'_09
}
rename hhid_09 hhid
tempfile c09
save `c09.dta', replace 

use $c00, clear
merge 1:1 hhid using $cog00, nogen 
merge 1:1 hhid using $test00, nogen
merge 1:1 hhid using "${data}\hh00.dta", nogen
merge m:1 villid using  "${data}\vill2000ts.dta", nogen 

*merge with 09 data
merge 1:m hhid pid00  using $cross , keep(matched) nogen   
merge 1:1 hhid  using `c09.dta', keep(matched master)    // merge 09 adult survey


*===============wave 1 predictors====================
g 		female=(osex==2)

*ed aspiration 
g 		edasp=ce1  
replace edasp=. if edasp<0 //17 missing
replace edasp=1 if ce1==1|ce1==2
replace edasp=2 if ce1==3 
replace edasp=3 if ce1==4|ce1==5
replace edasp=4 if ce1==6
la var edasp "education expecation(recoded)"
la def edasp 1"Junior high or less " 2"Senior high" 3"VET" 4"College"
la val edasp edasp
tab edasp, gen(ed) la


local reverse "cg1e cg1i cg1j cg1o cg2h cg3a  cg3e"
foreach x of local reverse{
replace `x'=5-`x' if `x'>0 & `x'!=0
tab `x'
replace `x'=. if `x'<0
}

local iv "cb13a-cb13e cg2a-cg2u cf5a-cf5i ch1a-ch1y ch6a-ch6k cg1c cg1e cg1f cg1p cg2h  cg1r cg3b cg3u   cg1b  cg1l  cg3f cg3j  cg3l   cg3m  cg3q  cg3r  cg3s  cg3c  cg3h cg3i cg3k cg3n cg3o cg3p  cg3t cg1n"
foreach x of varlist `iv' {
replace `x'=. if `x'<0
}

local indicator "cg1d cg1g cg1h cg1i cg1j cg1k"  //future related only
alpha `indicator',std item   //0.47
foreach x of local indicator{
replace `x'=. if `x'<0
}

pca `indicator',component(1)
predict fu
egen future2=std(fu)
la var future2 "orientations toward future" 


* from Glewwe: I have many things to be proud of; I always do things well; I always win praise from others for what I've done; I cannot do things well without the presence of my parents; I think I should be good at everything; I feel inferior to others; I am satisfied with my life; I have reasons for what I do. Reverse questions have been recoded (strongly agree changed to strongly disagree, agree changed to disagree).

*1.esteem /mastery
local esteem "cg1c cg1e cg1f cg1n cg1p cg1r cg2h cg3b cg3e cg3u cg1b cg1l" 
describe `esteem' // adding mastery
alpha `esteem',std item  //

pca `esteem',component(1)
predict esteem
egen esteem2=std(esteem)
la var esteem2 "esteem"


*2. externalizing &internalizing 
local ex "cg2a cg2b cg2d cg2e cg2i cg2l  cg2m cg2n cg2p cg2s cg2t cg2u cg3f cg3j cg3l cg3m cg3q cg3r cg3s"
alpha `ex',std item  //.896

pca `ex', component(1)
predict ex2
egen ex=std(ex2)
la var ex "externalizing"

local in "cg2c cg2f cg2g cg2j cg2k cg2o cg2q cg2r cg3a cg3c cg3h cg3i cg3k cg3n cg3o cg3p cg3t"
*univar `in', vlabel
alpha `in',std item  //.752
pca `in',component(1)
predict inter2
la var inter2 "internalizing"



*parenting style 
g closem=(ch8==1)
g closef=(ch9==1)


*parental education 
gen feduc=ded 
replace feduc=4 if ded >3
replace feduc=. if ded<0

gen meduc=med 
replace meduc=4 if med>3
replace meduc=. if med<0

la def ed 1 "Illiterate or semi-illiterate" 2"Primary school" 3"Middle school" 4"HS and above" 
la var feduc ed
la var meduc ed

egen peduc=rowmax(feduc meduc)
la var peduc ed

tab peduc, gen(peduc) la

g sib=(sibling>1)

xtile qwealth=lwealth,n(5)
tab qwealth, gen(hhwealth) la

tab age  if samekid0009==1 & age>=19  //N=1452

g agesq=age*age


*============analysis of attrition====================
* A=0 remain in the sample, A=1 not in the sample
g 		A=1 if samekid0009 !=1
replace A=0 if samekid0009 ==1


misschk  female age goodhlth goodhlth_f goodhlth_m roadmin lwealth sibling  badyield vnonaghh vhighsch  vnearmiddle vmig_all


* Calculate unrestricted attrition probit
#delimit ;
local dv " female age goodhlth goodhlth_f goodhlth_m roadmin lwealth sibling  badyield vnonaghh vhighsch  vnearmiddle vmig_all
           i.a3" ;
xi: probit A `dv', robust cluster(villid) ;
#delimit cr; 

*test female age renzhi goodhlth
*test _Ipeduc_2 _Ipeduc_3 _Ipeduc_4 lwealth sibling dadstay momstay 
*test vnonaghh vhighsch vtech vnearmiddle vmig_all


* Calculate inverse probability weights
g 		R=-A
replace R=R+1

#delimit ;
local dv "ed2 ed3 ed4 female age agesq renzhi goodhlth  
		 i.peduc dadstay momstay goodhlth_f goodhlth_m lwealth sibling 
         roadmin vnonaghh vhighsch vtech vnearmiddle vmig_all i.a3" ;
xi: probit R `dv' , robust cluster(villid);
#delimit cr; 
g sample=e(sample)
predict pxav


#delimit ;
local dv "i.peduc dadstay momstay goodhlth_f goodhlth_m lwealth sibling" ; 
xi: probit R `dv' if sample==1, robust cluster(villid);
#delimit cr; 
predict pxres

g attw=pxres/pxav  
misschk attw if samekid0009==1

tab age if attw==.
replace attw=1 if attw==.
*keep if samekid0009==1   // N =1728

save "${data}\00_09.dta" , replace 

erase "${data}\hh00.dta"
erase "${data}\vill2000ts.dta"
*erase "${dir}\hh00.dta" 
