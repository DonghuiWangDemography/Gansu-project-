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
// g 		sex=1 if female==0
// replace sex=2 if female==1  

*keep if female==1

discard


forvalues i=2/10{
discard
doLCA sch12-mig19, 			///
      nclass(`i') 			///
	  seed(100000) 			///
	  seeddraws(100000) 	///
	  categories(5 5 5 5 5 5 5 5 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2) ///
	  criterion(0.000001)  ///
	  clusters(villid)    ///
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

*note : bootstrap method is not avaiable for measurements use more than 2 items. 

/*measurement invariance test 
discard 
#delimit ;
doLCA sch12-mig19, 					
      nclass(7) 					
	  groups(sex) 					
	  groupnames("male female") 
	  measurement("groups")
	  seed(100000) 			  
	  seeddraws(100000) 	
	  categories(5 5 5 5 5 5 5 5 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2) 
	  criterion(0.000001)  
	  weight(attw)        
	  rhoprior(1.0) ;
#delimit cr
return list
*/
	  


*===========final model =============


*set trace on 
discard
doLCA sch12-mig19,  ///
      nclass(7)   ///
	  id(hhid)   ///
	  seed(100000) ///
	  seeddraws(100000) ///
	  categories(5 5 5 5 5 5 5 5 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2) ///
	  criterion(0.000001)  	///
	  clusters(villid)    ///
      rhoprior(1.0)   		///
	  nstarts (3)  
return list
*set trace off
	  
mat C=r(rho) 
mat gamma=r(gamma)
*mat odds=r(odds_ratio)
*mat p=r(p_value)
*mat rownames  p= `dv'
*mat list p
*mat list odds


mat list C
mat list gamma ,format(%9.3f) 
tab _Best_Index


// local dv "zfa zvedu zvmig zvinf"  // interaction with local opportunity:insig
// discard
// #delimit;
// doLCA sch12-mig19, 
//       nclass(7) 
// 	  id(hhid)   
// 	  seed(100089) 
// 	  seeddraws(10000) 
// 	  groups(sex) 
// 	  groupnames ("male female")
//       measurement("groups")
// 	  covariates(`dv') 	
// 	  reference(1)
// 	  categories(5 5 5 5 5 5 5 5 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2) 
// 	  criterion(0.000001)  
//       rhoprior(1.0)   
// 	  betaprior(1)  
// 	  nstarts (3) ; 
// #delimit cr	 
// return list
//	  
// mat C=r(rho) 
// mat gamma=r(gamma)
// mat odds=r(odds_ratio)
// mat p=r(p_value)
// mat rownames  p= `dv'
// mat list p
// mat list odds
// mat cov=r
//
// mat list C
// mat list gamma ,format(%9.3f) 
// tab _Best_Index
//








*=============graph=============
mat age =(12\13\14\15\16\17\18\19)
mat list age
local role "work mig"
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


grc1leg "c1" "c2" "c3" "c4"  "c5"  "c6" "c7",  ///
legendfrom(c1) ring(0) pos(4) span


*c1: move for vet
*c2: early mover 
*c3: move for work 
*c4: late finisher
*c5: move for high school
*c6: local high school
*c7: inactive 

grc1leg "c6" "c5" "c7"  ///
		"c3" "c2" "c1" "c4",  ///
legendfrom(c1) ring(0) pos(4) span

// graph save Graph "$images\rho_total.gph" , replace 
// graph export "$images\rho_total.png", replace


*================multinomial anlaysis============================
tab _Best_Index, gen(pa)
// rename pa1 finlate
// rename pa2 vet
// rename pa3 earlymove
// rename pa4 localhigh
// rename pa5 movehigh
// rename pa6 workmove

rename pa1 vet
rename pa2 earlymove
rename pa3 workmove
rename pa4 finlate
rename pa5 movehigh
rename pa6 localhigh
rename pa7 inact

la var localhigh  "Local high school attenders"
la var movehigh   "Move for high school"
la var workmove   "Move for work"
la var earlymove  "Early movers"
la var vet        "Move for VET"
la var finlate    "Late finishers"
la var inact      "Inactive"

recode _Best_Index (6=1 "Local high school attenders") (5=2 "Move for high school") (7=3 "Move for work")   ///
				   (3=4 "Early movers") (2=5 "Move for VET") (1=6 "Late finishers") (4=7 "Inactive"), gen(class) 

				   
*other labels
la var ed2 "Aspire high school"				   
la var ed3 "Aspire VET"				   
la var ed4 "Aspire College"				   

bysort qwealth: sum lwealth 



*============multinomial logit===============


mlogit class female zfa zvedu zvmig zvinf $ctr [aw=attw],  baseoutcome(7) vce(cluster villid) 
esttab using "$tables\model1_pca_b6.rtf" , b(%9.2f) se(%9.2f)   wide replace  la

*descriptives
la var female "Female"
la var lwealth "Household wealth(log transformed)"
la var peduc "Parental eudcation"
la var vnonaghh "Non-ag employment"
la var vncomp "Local enterprises"
la var vroades "Roades"
la var vprimaryr "Primary school attendence rate"
la var vmiddler "Middle school progression rates"
la var vhighr "High school progression rates"
la var age "Age"
la var goodhlth "Self-rated health"

local dv "female lwealth peduc vnonaghh vncomp vroades  vprimaryr vmiddler vhighr age goodhlth"  // interaction with local opportunity:insig
estpost summarize `dv'
// esttab using "${tables}\descriptive.rtf", cells ("mean(fmt(2)) sd (fmt(2))")  label replace 
esttab using "${tables}\descriptive.rtf", main(mean) aux(sd) nostar unstack label replace 


global ctr "age goodhlth "
mlogit class female zfa zvedu zvmig zvinf $ctr [aw=attw],  baseoutcome(1) vce(cluster villid) 
*esttab using "$tables\model1_pca_b6.rtf" , b(%9.2f) se(%9.2f)   wide replace  la

mlogit class i.female i.female#c.zfa i.female#c.zvedu i.female#c.zvmig i.female#c.zvinf $ctr [aw=attw],  baseoutcome(1) vce(cluster villid) 
margins, dydx(zfa zvedu zvmig zvinf) subpop(if female==0) post
estimates store male 


mlogit class i.female i.female#c.zfa i.female#c.zvedu i.female#c.zvmig i.female#c.zvinf $ctr [aw=attw],  baseoutcome(1) vce(cluster villid) 
margins, dydx(zfa zvedu zvmig zvinf) subpop(if female==1) post
estimates store female 

set scheme plotplainblind 
local iv "zfa zvedu zvmig zvinf"
foreach x of local iv {
#delimit;
coefplot ( male,  keep (`x':1._predict )) (female ,  keep (`x':1._predict ))     
		 ( male,  keep (`x':2._predict )) (female ,  keep (`x':2._predict )) 
	     ( male,  keep (`x':3._predict))  (female ,  keep (`x':3._predict ))	 	
         ( male,  keep (`x':4._predict )) (female ,  keep (`x':4._predict ))	
 		 ( male,  keep (`x':5._predict))  (female ,  keep (`x':5._predict ))	 
		 ( male,  keep (`x':6._predict)) (female ,  keep (`x':6._predict ))	
		 ( male,  keep (`x':7._predict))  (female ,  keep (`x':7._predict ))	
		 , yline(0) legend(off)  vertical   		
		 xlabel ( 1 "Local high school" 2 "Move for high school" 3"Inactive"  
		         4"Move for work" 5 "Early movers"  6 "Move for VET" 7 "Late finishers" , angle(45))
		 title(Estimated marginal effect of `x' on transition pathways);
		graph save Graph "$images\mlogit_`x'_gender.gph" , replace;
#delimit cr	  	
}






local iv "zfa zvedu zvinf "
foreach x of local iv {
coefplot (,  keep (`x':1._predict ))     ///
		 (,  keep (`x':2._predict) )  	///
	     (,  keep (`x':3._predict)) 	 ///
         (,  keep (`x':4._predict ) )  	///
 		 (,  keep (`x':5._predict))  	///
		 (,  keep (`x':6._predict) )  	///
		 (,  keep (`x':7._predict))  	///
		 , yline(0) legend(off)  vertical   ///
		 xlabel ( 1 "Local high school" 2 "Move for high school" 3"Inactive"  ///
		         4"Move for work" 5 "Early movers"  6 "Move for VET" 7 "Late finishers" ) ///
		 title(Estimated marginal effect of `x' on transition pathways)
graph save Graph "$images\mlogit_`x'.gph" , replace
}

graph use "$images\mlogit_female.gph"

graph use "$images\mlogit_zfa.gph"
graph use "$images\mlogit_zvedu.gph"
graph use "$images\mlogit_zvinf.gph"




grc1leg "$images\mlogit_female.gph" "$images\mlogit_zfa.gph"




