* created on 03/01/2019
* lca anlaysis, migranted from lca_v5.do

clear all 
clear matrix 
set more off 
capture log close 

global date "11212018"   // yymmdd
global dir "C:\Users\donghuiw\Desktop\GansuChildren"  //office

global images "${dir}\images"
global tables "${dir}\tables"
global data   "${dir}\data"

*note: missing data on covariates is not allowed
set matsize  11000  

//set trace on
drop _all
cd "C:\Users\donghuiw\Desktop\GansuChildren\data"  // need to specify cd in order to call lca plugin

use "${data}\lca.dta", replace


* use stata plug in 
forvalues i=12/19{
replace sch`i'= sch`i'+1
replace mig`i'= mig`i'+1
replace work`i'= work`i'+1
}

discard


forvalues i=2/10{
discard
doLCA sch12-mig19, ///
      nclass(`i') ///
	  seed(100000) ///
	  seeddraws(100000) ///
	  categories(5 5 5 5 5 5 5 5 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2) ///
	  criterion(0.000001)  ///
	  rhoprior(1.0)
	  	  
scalar entropy_`i'=r(EntropyRsqd)
scalar gsq_`i'=r(Gsquared)
scalar aic_`i'=r(aic)
scalar bic_`i'=r(bic)
scalar adjBIC_`i'=r(AdjustedBIC) 
*scalar ll_`i'=r(loglikelihood)
}

numlist "2/10"
local stats "Gsquared AIC BIC adjBIC entropy"
local n :word count `r(numlist)'
mat stats=J(`n',5,-99)
mat colnames stats=`stats'
mat rownames stats=`r(numlist)'
mat list stats



forvalues i=2/10{
mat stats[`i'-1,1]= gsq_`i'
mat stats[`i'-1,2]= aic_`i'
mat stats[`i'-1,3]= bic_`i'
mat stats[`i'-1,4]= adjBIC_`i'
mat stats[`i'-1,5]= entropy_`i'
}
mat list stats, format (%9.3f)



svmat stats, names (col)
gen nclass=_n+1 if AIC !=.

   twoway (connected Gsquared nclass, lp(dash_dot) m(oh))    ///
          (connected AIC nclass, lp(dash_dot_dot) m(oh))     ///
             (connected BIC nclass, lp(solid))               ///
             (connected adjBIC nclass, lp(dash) m(0)) ,      ///
			 xlab(2(1)10) xtitle(Number of Latent Classes)    ///
			 title("Fit Statistics") 
			 
*graph save Graph "$graph\fit_v4.gph" , replace 

*===========lca with covariate=============
* trace on 
local dv "female lwealth peduc sib age renzhi "  // interaction with local opportunity:insig
discard
doLCA sch12-mig19, ///
      nclass(7) ///
	  id(hhid)   ///
	  seed(100089) ///
	  seeddraws(10000) ///
	  covariates(`dv') 	///
	  categories(5 5 5 5 5 5 5 5 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2) ///
	  binary(2)	///
	  criterion(0.000001)  ///
      rhoprior(1.0)   ///
	  betaprior(1)  ///
	  nstarts (3)  
return list
*set trace off
	  
mat C=r(rho) 
mat gamma=r(gamma)
mat odds=r(odds_ratio)
mat p=r(p_value)
mat rownames  p= `dv'
mat list p
mat list odds


mat list C
mat list gamma ,format(%9.3f) 
tab _Best_Index



*=============graph=============
mat age =(12\13\14\15\16\17\18\19)
mat list age
local role "work mig"
//foreach x of local gender{
forvalues i=1/7{
foreach v of local role {
mat C`i'`v'=C["`v'1221".."`v'1921",`i']
mat C`i'sch1= C["sch1211".."sch1911",`i']
mat C`i'sch2= C["sch1221".."sch1921",`i']
mat C`i'sch3= C["sch1231".."sch1931",`i']
mat C`i'sch4= C["sch1241".."sch1941",`i']
mat C`i'sch5= C["sch1251".."sch1951",`i']
}
mat C`i'= age, C`i'sch1, C`i'sch2, C`i'sch3, C`i'sch4, C`i'sch5, C`i'work,C`i'mig
mat colnames C`i'= T  Noschool Middle High VET College work mig
numlist "12/19"
mat rownames C`i'=`r(numlist)'
}

mat list C4

//drop Noschool-mig after first run 
set scheme plotplainblind 
forvalues i=1/7 {
drop T-mig
svmat C`i', names (col)
       twoway(connected Middle T, lp(dash) m(oh))                 ///
             (connected High T, lp(dash_dot))                      ///
			 (connected VET T, lp(longdash dot))                       ///
			 (connected College T, lp(dot) m(0))                 ///
             (connected work T, lp(solid) m(d))                          ///
             (connected mig T, lp(shortdash) m(dh)) ,                  ///
             xlab(12(1)19) ylab(0(.2)1.05) ytit("Expected Probability") xtitle(Age) ///
		     legend(rows(1) order(1 "Middle" 2 "High" 3 "VET" 4 "College"  5 "Work" 6 "Home-leaving") ///
			 forcesize pos(6))  ///
			 title("Class`i'") saving(c`i', replace)
			
}


grc1leg "c2" "c6" "c5" "c3"  "c7"  "c1" "c4",  ///
legendfrom(c1) ring(0) pos(4) span



