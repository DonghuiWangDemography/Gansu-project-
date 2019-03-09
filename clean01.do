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
keep villid  vroades  vnonaghh vnearmiddle vhighsch vtech vmig_all vcomp vncomp

save "${data}\vill2000ts.dta", replace 


*=========hh data====================
use $hh00 ,clear

g villid=a1*10000+a2*100+a3
clonevar osex=h0103_01
clonevar obirth=h0104_01   //birth year
clonevar oethnic=h0106_01 //  may be no need 
clonevar health=h0801_01


*dad 1,997 respondents are father 
g ded=h0110_02 if  h0102_02==2 // highest education 
g dilliter=(h0111_02==1|h0112_02==1) if h0102_02==2 
g dadstay= h0115_02  if h0102_02==2 // length of stay at home 

*mom 1,996 respondents are monther  
g med=h0110_03 if  h0102_03==3 // 
g milliter=(h0111_03==1|h0112_03==1) if h0102_03==3 
g momstay=h0115_03  if h0102_03==3 

g roadkm=h1101_01  // distance to the nearest public road in km
g roadmin=h1102_01 // distance to the nearest public road in minitus 


* count siblings
local sib "h0102_04 h0102_05 h0102_06 h0102_07 h0102_08 h0102_09 h0102_10 h0102_11 h0102_13 h0102_14 h0102_15"

foreach v of local sib{
gen sib`v'=0
replace sib`v'=1 if `v' >=21 &`v'<57 & `v' !=.  // refer to qinshu guanxi kapian 
tab sib`v'
}
egen sibling = rcount(sibh0102_04-sibh0102_15), cond(@ == 1) 
tab sibling

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

keep  hhid villid osex obirth oethnic  *birth *ed *illiter *stay road* lwealth sibling health
save "${data}\hh00.dta" , replace 

*use $c09, clear
*use $cross, clear

* it seems that prior study add _09 for 2009 children survey, to keekp consistent, also add _09 to childrens' survey
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

merge 1:m hhid pid00  using $cross , keep(matched) nogen // all merged

merge 1:1 hhid  using `c09.dta' // merge 09 adult survey

keep if samekid0009==1   // N =1728

save "${data}\00_09.dta" , replace 

erase "${data}\hh00.dta"
erase "${data}\vill2000ts.dta"
*erase "${dir}\hh00.dta" 
