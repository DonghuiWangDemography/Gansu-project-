*Graphing descriptives
*most codes are copied from Graphing_v4.do
*created on 03092019

clear all
discard

global date "03092018"   // yymmdd
global dir "C:\Users\donghuiw\Desktop\GansuChildren"  //office

global images "${dir}\images"
global tables "${dir}\tables"
global data   "${dir}\data"


use "${data}\lca.dta", replace


keep hhid birth female age sch12-mig19  
reshape long sch work mig , i(hhid) j(j)
drop  if j>age 

tab sch, gen(sch) la
la var sch1 "Not in school"
la var sch2 "Middle school"
la var sch3 "High school"
la var sch4 "VET"
la var sch5 "community college or 4-yr college "


*proportion of the status over age
foreach x of varlist sch1 sch2 sch3 sch4 sch5 work mig {
qui: prop `x', over (j)
mat `x'=r(table)
mat list r(table)
mat p`x'= `x'[1,9..16]
mat list p`x'
}

drop _all 
mat C=psch1',psch2',psch3',psch4', psch5', pwork', pmig'
mat colnames C=Noschool Middle High VET College Work Home_leaving
numlist "12/19"
mat rownames C`i'=`r(numlist)'
mat list C 
svmat C, names(col)
gen Age=11+_n
foreach x in Noschool Middle High VET College Work Home_leaving{
replace `x'= 100*`x'
}


twoway (connected Middle Age, lp(dash) m(oh))                 ///
       (connected High Age, lp(dash_dot))                     ///
       (connected VET Age, lp(dash_dot_dot) m(d))   ///
	   (connected College Age, lp(solid) m(d))                          ///
       (connected Work Age, lp(shortdash) m(dh)) 	  /// 
	   (connected Home_leaving Age, lp(longdash) m(dh)) ,                  ///
  legend(rows(1) forcesize pos(6)) xlab(12(1)19) ylab(0(20)100) ytit("% Respondents") xtitle(Age)


	