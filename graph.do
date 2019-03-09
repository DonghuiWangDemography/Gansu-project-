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


use lca.dta  // schoolign are recorded in five catergories 
keep  hhid birth sex age sch12-mig19  

