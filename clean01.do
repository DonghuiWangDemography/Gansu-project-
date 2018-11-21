*Project: Gansu survey of Children and family;
*Created 11/21/2018
*Task : data cleaning & management
*Nptes: Derived from Datamanagement_v2.do; revise codes

clear all 
clear matrix 
set more off 
capture log close 

global date "11212018"   // yymmdd
global dir "C:\Users\donghuiw\Desktop\GansuChildren"
global images "${dir}\images"
global tables "${dir}\tables"

global c00 "${dir}\data\2000\child2000t.dta"
global hh00 "${dir}\data\2000\hh2000ts.dta"
global vill00 "${dir}\data\2000\vill2000.dta" 
global cog00 "${dir}\data\2000\litracy2000t.dta"
global test00 "${dir}\data\2000\achieve2000t.dta"
global c09 "${dir}\data\2009\child2009t.dta"

use $hh00 ,clear

g villid=a1*10000+a2*100+a3
clonevar osex=h0103_01
clonevar obirth=h0104_01 //birth year
clonevar oethnic=h0106_01 // may be no need 

//dad 1,997 respondents are father 
g ded=h0110_02 if  h0102_02==2 // highest education 
g dilliter=(h0111_02==1|h0112_02==1) if h0102_02==2 
g dadstay= h0115_02  if h0102_02==2 // length of stay at home 

//mom 1,996 respondents are monther  
g med=h0110_03 if  h0102_03==3 // 
g milliter=(h0111_03==1|h0112_03==1) if h0102_03==3 
g momstay=h0115_03  if h0102_03==3 

//g roadkm=h1101_01  // distance to the nearest public road in km
//g roadmin=h1102_01 // distance to the nearest public road in minitus 

// count siblings
local sib "h0102_04 h0102_05 h0102_06 h0102_07 h0102_08 h0102_09 h0102_10 h0102_11 h0102_13 h0102_14 h0102_15"

foreach v of local sib{
gen sib`v'=0
replace sib`v'=1 if `v' >=21 &`v'<57 & `v' !=.  // refer to qinshu guanxi kapian 
tab sib`v'
}
egen sibling = rcount(sibh0102_04-sibh0102_15), cond(@ == 1) 
tab sibling

// Family wealth: total value of house, equipment and durable goods
// follow Zhang, Yuping, Grace Kao, and Emily Hannum. "Do mothers in rural China practice gender equality in educational aspirations for their children?."
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

keep  hhid villid osex obirth oethnic  health *birth *ed *illiter *stay road* lwealth sibling
unique hhid 
sort hhid villid
