*2000_2009 panel 
*created on 01/11/2019 
*task: reconstruct life history & create other measurements 
*directly copy the old code of DescriptiveAnalysis_panel_v4.do


clear all 
clear matrix 
set more off 
capture log close 

global date "03092018"   // yymmdd
global dir "C:\Users\donghuiw\Desktop\GansuChildren"  //office

global images "${dir}\images"
global tables "${dir}\tables"
global data   "${dir}\data"


use "${data}\00_09.dta", clear  // N=1728 


clonevar birth=c2_1    // 16 missing birth : need to go to wave 1 
clonevar sex=c1_09    // 16 missing values 
g age=2009-birth     // max age: 28;  98.19 are 22
keep if birth !=.    // 16 observation deleted 
tab age
keep if age >=19    // at least 19 years old : 195 deleted  ==> N=1517


********************
*2000 wave predictors 
********************
g female=(sex==2)
 
*generate variables for 2000 wave ;
g edasp=ce1  
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
gen goodhlth=(health==1|health==2)


**********************************
*transition pathway
***********************************

egen n_ed = anycount(d5_1_a_09 d5_1_b_09 d5_1_c_09 d5_1_d_09 d5_1_e_09), value(1)  // if have ever attended any school after middle school 
egen highsch=anycount(d5_1_a_09 d5_1_b_09 d5_1_c_09), value(1)
tab highsch  // 29 went to two institutions
list d5_1_a_09 d5_1_b_09 d5_1_c_09 if highsch==2
   
* deal with miscodings 
replace d5_2_d_09=2009 if d5_2_d_09==200809
replace d5_2_b_09=round(d5_2_b_09)  // what about those who had less than one year? => automatically set to one year
replace d6_1_09=2006 if d6_1_09==22006
*g missing_s1=(d6_1_09==. | d6_1_09<0) if d1_09==2

 
local ed "a b c d e"
foreach x of local ed{
replace d5_2_`x'_09=. if  d5_2_`x'_09==-1 
g dur_`x'=round(d5_3_`x'_09)   //how long attended 
*replace d5_2_`x'_09=round(d5_2_`x'_09)

g age_t_`x'=d5_2_`x'_09-birth if d5_1_`x'_09==1 &d5_2_`x'_09 >0 // age start education 
g age_s_`x'=age_t_`x'+dur_`x' if d5_1_`x'_09==1  // age when finish the education
replace age_s_`x'=age if d5_9_`x'_09==1  // age if still attending
clonevar comp_`x'=d5_9_`x'_09 // wheather completed or not 
}

* check if ppl have ever attend Both high school/ vocational high 
tab d5_1_a_09  d5_1_b_09   //10 ppl went to both highschool/vocational high
tab d5_1_c_09 


*collaps zhongzhuan with gaozhi 
replace age_t_b=age_t_c if d5_1_c_09==1 &d5_2_c_09 >0 
replace age_s_b=age_s_c if d5_1_c_09==1
drop age_t_c age_s_c

*collaps dazhuan with college 
replace age_t_d=age_t_e if d5_1_e_09==1 &d5_2_e_09 >0 
replace age_s_d=age_s_e if d5_1_e_09==1

drop age_t_e age_s_e



// record school history 
/* 1: middle school
   2: high school  (a)
   3: vocational highschool (zhiye gaozhong & zhongzhuan) 
   4: college (da zhuan and benke)
 */

*updated on 03092019: change < with <= 

 rename (age_t_a age_t_b age_t_d ) (ts2 ts3 ts4 )
 rename (age_s_a age_s_b age_s_d ) (tf2 tf3 tf4 )
 
g age_m=d6_1_09-birth if d1_09==2& d6_1_09>0  //age when quit middle school :240  (what to do with those with negatives ?? :11 )
*tab age_m if  d1_09==2 

g age_mf=d1_a_09-birth if d1_a_09>0 & d1_09==1 // for those who finished middle school, age at finishing middle school
tab age_mf,m  // 311 missing
*drop sch*

forvalues i=12(1)19{
g sch`i'= 0
*replace sch`i'=. if `i'>age  // set to missing if age at yr i is greater than current age   

replace sch`i'= 1 if `i'<= age_m &  d1_09==2 // age when quitting middle school | not finishing middle school ;
replace sch`i'= 1 if `i'<= age_mf & d1_09==1  //age when finishing middle school;

forvalues k=2(1)4{
replace sch`i'=`k' if `i'>=ts`k'  & `i'<= tf`k'   
}
la def val 0 "Not in school" 1"Middle school" 2"High school" 3"VET" 4"community or 4-yr college", modify
la val sch`i' val
}



*****work history************** 
*tab e15_09  // how many jobs
*tab e14_a_09
g age_w_t1=e2_a_09-birth //age start first job 
g age_w_s1=e14_a_09-birth if e13_09==1  //age end first job 
replace age_w_s1=2009-birth  if e13_09==2 // if still working 

g age_w_t2=e19_a_09-birth //age start most recent job 
g age_w_s2=e17_a_09-birth // age end most recent job 
replace age_w_s2=2009-birth if e16_09==1

replace age_w_t1=. if age_w_t1<0
replace age_w_s1=. if age_w_s1<0

*drop work*
forvalues i=12(1)19{
g work`i'=0
*replace work`i'=. if `i'>age 

replace work`i'=1 if `i'>=age_w_t1 &`i'<=age_w_s1 & (age_w_t1 !=. & age_w_s1 !=.)
replace work`i'=1 if `i'>=age_w_t2 &`i'<=age_w_s2 & (age_w_t2 !=. & age_w_s2 !=.)
//tab work`i', m
}
//list work* in 1/100

drop age_w*

************migration history ******************* 

foreach i in 1 2 {
g ms`i'=year(f8_b_`i'_09)-birth  // age start mig
g mf`i'=year(f8_c_`i'_09)-birth
}
foreach i in 31 32 {
g ms`i'=year(f8b_`i'_09)-birth
g mf`i'=year(f8c_`i'_09)-birth
}

replace ms1=18 if ms1==218 // ms==2207
replace mf1=25 if mf1==26   // one mf1==2010
replace ms2=. if ms2==-207


*drop mig*
forvalues i=12(1)19{
g mig`i'=0
*replace mig`i'=. if `i'>age // not sure what's going wrong
foreach k in 1 2 31 32 {
replace mig`i'=1 if `i' >=ms`k' & `i'<=mf`k'
}
tab mig`i',m  //looks correct 
}


drop ms1-mf32 *_09 
***************************************

* rates of missing data
local cv "edasp  goodhlth ded lwealth renzhi roadmin "
foreach v of local cv {
replace `v'=. if  `v'<0
}

*local dv " asp2 asp3 asp4 future esteem2 age female renzhi goodhlth hhwealth1 peduc closem closef  vnonaghh roadmin vtech vnearmiddle"  // interaction with local opportunity:insig
local dv "edasp inter2 ex esteem2 lwealth peduc closem closef age female goodhlth renzhi vnonaghh vhighsch vtech vnearmiddle vmig_all vcomp vncomp vroades vnonaghh "  // interaction with local opportunity:insig
estpost summarize `dv'
esttab using "${tables}\descriptive.rtf", cells ("mean(fmt(2)) sd (fmt(2)) ")  label replace 

pwcorr future2 esteem2 ,sig  // 0.5

//mat list stats

//estpost summarize sex edasp future feduc lwealth health school roadmin  renzhi
//esttab using Gansu_descriptive.rtf, cells ("mean(fmt(2)) sd (fmt(2)) ")  label replace 


keep hhid villid age birth female  sch* work* mig*  peduc sib goodhlth lwealth  qwealth   ///
edasp ed1 ed2 ed3 ed4 future2 esteem2   renzhi  ded med closem closef  roadmin lwealth    ///
vroades  vnonaghh vnearmiddle vhighsch vtech vmig_all vcomp vncomp  

save "${data}\lca.dta", replace

*save "G:\RA\Chinasurveydata\GSCF_to2009\GSCF_to2009\LCA stataplugin\Release64-1.3.2\lca_cov_v4.dta", replace
