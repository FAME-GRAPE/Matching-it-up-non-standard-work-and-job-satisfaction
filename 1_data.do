/*upload dataset - ewcs_1991-2015_ukda.dta - rename it data_1991-2015.dta*/
use data_1991-2015, clear
*change of names (the prefix "y15_" ia redundant and confusing)
rename y15_Q* Q*

*missing observations
quietly mvdecode Q2a Q3a*, mv(9)

quietly mvdecode Q4? Q40 Q45* Q46 Q61* Q62 Q70* Q89* Q95*, mv(7 8 9)

quietly mvdecode Q2d Q3e* Q7 Q8b* Q9a Q10 Q11 Q14 Q18? Q20 Q21? Q22 Q26 ///
         Q27 Q38 Q39? Q41 Q42 Q43 Q44 Q47 Q49? Q61? Q65? Q67? Q69 Q71? Q72?  ///
		 Q75 Q81? Q87? Q88 Q90? Q96* Q99 Q100 Q101? Q102 y05_q1a, mv(8 9)

quietly mvdecode Q1, mv(99)

quietly mvdecode y15_ISCED_lt, mv(88)

quietly mvdecode Q2c Q3c* Q3d* Q16a Q37a Q37b Q37c Q37d Q106, mv(88 99)

quietly mvdecode Q2b Q3b* Q24 Q28 Q82 Q97, mv(888 999)

quietly mvdecode Q25 Q36, mv(777 888 999)

quietly mvdecode Q104*, mv(88888888 99999999)

quietly mvdecode Q105, mv(22 23)

* self-employed
gen self_emp = Q7 == 2
label var self_emp "self employed"
keep if self_emp!=1

* Job satisfaction
/*
Q90 - constructed out of 4 variables answered on scale 1-5
      "At my work I feel full of energy"
	  "I am enthusiastic about my job"
	  "Time flies when I am working"
	  "In my opinion, I am good at my job"
	  AND a reverse of 
	  "I feel exhausted at the end of the working day"
	  "I doubt the importance of my work"
Available only in 2015
Q88 - satisfaction with working conditions
Available in all years
*/

*Q90
  gen Q90d_r=6-Q90d
  gen Q90e_r=6-Q90e
  factor Q90a Q90b Q90c Q90d_r Q90e_r Q90f, ml //Q90e_r
  *it seems that 2 factors are enough
  pca Q90a Q90b Q90c Q90d_r Q90e_r Q90f 
  predict score  js2
  
  alpha Q90a Q90b Q90c Q90d_r Q90e_r Q90f, std 
  di sqrt(`r(alpha)')
  

  label var js2 "job satisfaction index, wave 6 only"
    
*Q88
gen js1 = Q88
  label var js1 "job satisfaction, all years, categorical"
  label define js1 1 "very satisfied" 2 "satisfied" 3 "dissatisfied" 4 "very dissatisfied"
  label values js1 js1
  *dummy of js2
recode js1 (1/2=1) (3/4=0) , gen(js1_d)
  label var js1_d "0/1, job satisfaction, all years, dumy"
 
 ********************************************************************************
gen female = Q2a-1
replace female =. if female == 8

gen age =  Q2b
gen age_cat = floor(age/5)

* number of people in household
  gen hhsize=Q1
  label var hhsize "number of people in household"

* children in household
gen child=0
forvalues no =2(1)10 {
replace child=1 if Q3c_`no'==2 & Q3b_`no'<=18
}
label var child "child 0-18 yo in household"  

* youngest child age
 gen child_age=0
replace child_age=min(Q3b_1, Q3b_2, Q3b_3, Q3b_4, Q3b_5, ///
                      Q3b_6, Q3b_7, Q3b_8, Q3b_9, Q3b_10) if child==1
replace child_age=2 if child_age==1.5
replace child_age=6 if child_age==5.5
label var child_age "age of the youngest child in household"

* age of the youngest child in household
  gen child_u7=0
forvalues no =2(1)10 {
replace child_u7=1 if Q3c_`no'==2 & Q3b_`no'<7
}
label var child_u7 "child 0-7 yo in household"

* children between 7 and 12 in household
  gen child_u12=0
forvalues no =2(1)10 {
replace child_u12=1 if Q3c_`no'==2 & Q3b_`no'>=7 & Q3b_`no'<=12
}
label var child_u12 "child 7-12 yo in household"

* elder in household
  gen elder=0
forvalues no =2(1)10 {
replace elder=1 if Q3b_`no'>=80 & Q3b_`no'!=.
}
label var elder "person >80 yo in household"
 
* education
  gen edu = .
  replace edu = 1 if inlist(y15_ISCED,1,2,3) 	| inlist(y15_ISCED_lt,1,2,3)
  replace edu = 2 if inlist(y15_ISCED,4,5) 		| inlist(y15_ISCED_lt,4,5) 
  replace edu = 3 if inlist(y15_ISCED,6,7,8,9) 	| inlist(y15_ISCED_lt,6,7) 
  * add from age of leaving education if ISCED missing y10_q5 y10_q5_lt
  gen hedu = edu ==3
  replace hedu = . if edu==.
  
* imigrant
  gen immi=1 if Q4a==2
    replace immi=0 if Q4a!=2 & Q4a!=.
	replace immi=1 if Q4a==2 & wave==5
	replace immi=0 if Q4a!=2 & Q4a!=. & wave==5
	replace immi=1 if y05_q1a==2
	replace immi=0 if y05_q1a!=2 & y05_q1a!=.
	label var immi "immigrant"
  
* occupation (3 cat)
	gen occ = y15_ISCO_88_1
	replace occ = . if y15_ISCO_88_1==-1
	replace occ = occ + 1
	label var occ "ISCO 88 1 digit"
	recode occ (1/3 = 1) (4/6=2) (7/9=3) (10=1), g(occ_cat)
	label var occ "ISCO 88 categorized to three levels"

* industry 	
	gen ind =   y15_nace_r1_lt_11
	gen ind_cat = y15_nace_r1_lt_4

* subjective health
  gen health=Q75
  label var health "subjective health"
  
* bread winner
  gen bwin=1 if Q99==1
    replace bwin=0 if Q99==2 | Q99==3
	replace bwin=0 if hhsize==1
	label var bwin "bread winner"
	
*equal contribution
  gen ec=1 if Q99==3
    replace ec=0 if Q99==1 | Q99==2
	label var ec "equal contribution"
	
*enough money to make ends meet
  gen ends=Q100
    label var ends "enough money to make ends meet"

* hazardous conditions
	capture drop hazardous 
	gen hazardous = 0
	foreach var in Q29a Q29b Q29c Q29d Q29e Q29f Q29g Q29h Q29i Q30a Q30b Q30c Q30e Q31 {
	replace hazardous = hazardous + 1 if inrange(`var',1,5)
	replace hazardous = hazardous + 0 if inlist(`var',6,7)
	}
	replace hazardous = . if wave <2
	label var hazardous "work in difficult or hazardous conditions, available from wave 2"
  
* type of employment contract
  gen permanent = Q11_lt == 1
  replace permanent = . if Q11_lt == .
  label var permanent "permanent contract, available from wave 2"  

  gen temporary = inlist(Q11_lt, 2,3,4)
  replace temporary = . if Q11_lt == .
  label var temporary "temporary contract, available from wave 2"
  
* sector of economy
gen private = Q14_lt == 1
replace private = . if Q14_lt == .
	label var private "work in private sector"
gen public = Q14_lt ==2
replace public = . if Q14_lt == .
	label var public "work in public sector"
 
* company size
  gen size = .
  replace size = 0 if Q16a_lt == 1
  replace size = 3 if Q16a_lt == 2
  replace size = 7 if Q16a_lt == 3
  replace size = 35 if Q16a_lt == 4
  replace size = 250 if Q16a_lt == 5
  replace size = 500 if Q16a_lt == 6
  replace size = . if Q16a_lt>7
    label var size "company size, missing for wave 2"
 
* side job
  gen side_job = Q27_lt ==1
  replace side_job = . if Q27_lt==.
	
* work-life balance
* fit of working hours with family or social life
  gen h_fit = 5- Q44
  replace h_fit = . if wave < 3
    label var h_fit "working hours fit with personal life, available from wave 3"
    label define _h_fit 4 "very well" 3 "well" ///
	                    2 "not very well" 1 "not at all well"
	label value h_fit _h_fit
	
* Q45 may be used to create a scale for work-life balance
gen wfc = (6-Q45b) + (6-Q45c)
label var wfc "work-family conflict, available in wave 6, bigger=greater conflict"
gen fwc = Q45d + Q45e
label var fwc "family-work conflict, available in wave 6, bigger=greater conflict"
gen worry = 6-Q45a 
label var worry "worry about work when not at work, available in wave 6, bigger=more"
gen fwc_d = 0 
replace fwc_d = 1 if Q45d == 1 | Q45d == 2 | Q45d == 3 | Q45e == 1 | Q45e == 2 | Q45e == 3
replace fwc_d = . if Q45d == . & Q45e == .

clonevar sectors_grouped = y15_nace_r1_lt_4 

*work time
  *hours per week
  gen hours = Q24
  label var hours "weekly hours"
  gen parttime = Q2d==1 
  label var parttime "part-time employment"
  * nights
  gen nights = Q37a
  replace nights = . if wave < 2
  label var nights "how many times a month work nights, available from wave 2"
  * Saturdays
  gen saturdays = Q37c 
  replace saturdays = . if wave < 2
  label var saturdays "how many times a month work saturdays, available from wave 2"
  * Sundays
  gen sundays = Q37b 
  replace sundays = . if wave < 2
  label var sundays "how many times a month work sundays, available from wave 2"
  * long hours
  gen long_hours = Q37d 
  replace long_hours = 12 if long_hours == 12.5
  replace long_hours = . if wave < 3
  label var long_hours "how many times a month work more than 10 hours, available from wave 3"

* commuting time
gen commute =Q36/60
replace commute = . if wave < 2
label var commute "hours of commuting to work per day, available from wave 2"
 
* way of setting working time
  gen employer_sets_time = Q42_lt == 1
  replace employer_sets_time = . if wave < 3 |  Q42_lt==.
  label var employer_sets_time "who sets time, available from wave 3"

* way of changing schedule 
  gen stable_schedule = Q43 == 1
  replace stable_schedule = . if Q43 == . | wave<3
  label var stable_schedule "stable working time schedule, available from wave 3"

*welfare regime - based on "Parental leave regulations and the persistence of the male breadwinner model: Using fuzzy-set ideal type analysis to assess gender equality in an enlarged Europe" (Ciccia, Verloo, 2012)
gen welf=.
  replace welf=1 if countid==21 | countid==25 | countid==26
  replace welf=2 if countid==1 | countid==7 | countid==10 | countid==11 | countid==12 | countid==17 | countid==18
  replace welf=3 if countid==4 | countid==23
  replace welf=4 if countid==3 | countid==6 | countid==8 | countid==9 | countid==13 | countid==16 | countid==19 | countid==20 | countid==24 | countid==27
  replace welf=5 if countid==2 | countid==14 | countid==22
  
  lab def welf 1 "limited universal caregiver (LUC)" 2 "unspported universal breadwinner (UUB)" 3 "supported universal breadwinner (SUP)" 4 "male breadwinner (MB)" 5 "caregiver parity (CGP)"
  lab var welf welf
  

*unclassified: germany(5) luxembourg(15)
gen supportive_colleagues = y15_q61a_lt ==1
replace supportive_colleagues = . if wave < 2 | mi(y15_q61a_lt)
label var supportive_colleagues "supportive colleagues, available from wave 2"
gen free_to_break = Q61f_lt ==1
replace free_to_break = . if wave < 4 | mi(Q61f_lt)
label var free_to_break "free to take a break at will, available from wave 4"
gen enough_time = Q61g_lt ==1
replace enough_time = . if wave < 2 | mi(Q61g_lt)
label var enough_time "enough time to finish tasks, available from wave 2"
  
  
****
// JOB SATISFACTION
// js1 == all years, categorical
// js1_d == all years, converted to dummy
// js2 == only 2015, index (quasi-continous)
global js "js1 js1_d js2"

// personal level characteristics
global personal "age age_cat female edu hedu hhsize immi child child_age child_u7 child_u12 elder bwin ec ends side_job  h_fit" 
global basic_personal "age female edu hedu hhsize immi child child_age child_u7 child_u12 elder bwin ec ends side_job " 

// employer characteristics
global employer "ind ind_cat size commute private public"

// job characteristics
global job "hours  occ occ_cat  nights saturdays sundays long_hours permanent temporary " 
global job_basic "hours occ occ_cat  nights saturdays sundays long_hours permanent temporary "

// workplace characteristics
global workplace "stable_schedule employer_sets_time supportive_colleagues free_to_break enough_time hazardous fwc fwc_d wfc worry" 
global environment "supportive_colleagues hazardous " 
global subjective "fwc fwc_d wfc worry "
global wtf_objective "stable_schedule employer_sets_time free_to_break"
global wtf_subjective "h_fit enough_time" 
		
// time variables
// year or wave (equivalent)
global time "year wave"

gen country = countid
global country "countid countr welf"

gen aux = _n
egen idn=group(countid aux)

recode age (19/30=1) (31/45=2) (46/60=3) (60/.=.), gen(age_groups)
gen single_hh = hhsize==1

replace ind_cat= . if ind_cat==9
gen long_commute = inrange(commute,1,14) & !mi(commute)

replace long_commute = . if mi(commute)
gen l_hours_prev = long_hours > 1 & !mi(long_hours)
 
replace l_hours_prev = . if mi(long_hours)
gen l_hours_reg_prev = long_hours >= 2 & !mi(long_hours)

replace l_hours_reg_prev = . if mi(long_hours)
gen sat_prev = saturdays > 1 & !mi(saturdays)

replace sat_prev = . if mi(saturdays)
gen sun_prev = sundays > 1 & !mi(sundays)

replace sun_prev = . if mi(sundays)
gen l_hours = hours>40 & !mi(hours)

replace l_hours = . if mi(hours)
gen nights_prev = nights> 1 & !mi(nights)

replace nights_prev = . if mi(nights)
gen nights_reg_prev = nights >=2 & !mi(nights)

replace nights_reg_prev = . if mi(nights)

gen wknd_prev= sat_prev * sun_prev 
gen sat_or_sun_prev = 0
replace sat_or_sun_prev = 1 if sat_prev== 1 | sun_prev == 1
replace sat_or_sun_prev = . if mi(sundays) & mi(saturdays)
replace hazardous = 5 if hazardous>5 & !mi(hazardous)

gen fixed_schedules = Q39d==1 & !mi(Q39d)
replace fixed_schedules = . if mi(Q39d)
gen flexible_schedules = Q39d ==2 & !mi(Q39d)
replace flexible_schedules = . if mi(Q39d)

tab js1, g(jobsatisfaction)

/*education missing 30% - do not use*/

global varlist1 "age_groups female single_hh child_u7 elder parttime flexible_schedules sat_prev sun_prev sat_or_sun_prev nights_prev nights_reg_prev h_fit l_hours_prev l_hours_reg_prev"
global varlist2 "ind_cat long_commute supportive_colleagues enough_time hazardous occ_cat "
global varlist3 "js1 w5 ends worry wfc fwc fwc_d employer_sets Q45?" 

/*missings*/
mdesc $varlist1 $varlist2 $varlist3  idn if !mi(js1) & wave>2

drop if countid>27 // keeping countries which are long enough in EWCS
drop if sectors_grouped >= 4 // keeping private sector workers
keep if wave>2 & !mi(js1) // most questions of interest were not asked before wave 2
keep $varlist1 $varlist2 $varlist3 js2 countid idn wave w5 sectors_grouped

/*missings*/
mdesc
egen idn2 = group($varlist1 $varlist2)
drop if mi(idn2)

gen long_flex = flexible_schedules * l_hours_reg_prev
replace l_hours_reg_prev = 0 if long_flex ==1
replace flexible_schedules = 0 if long_flex ==1

* sunday trumps everything! 
replace flexible_schedules = 0 	if sun_prev==1 & flexible_schedules==1
replace l_hours_reg_prev = 0 	if sun_prev==1 & l_hours_reg_prev==1
replace long_flex = 0 			if sun_prev==1 & long_flex==1

gen sunday_nights = sun_prev * nights_reg_prev
replace sun_prev = 0 if sunday_nights ==1
replace nights_reg_prev = 0 if sunday_nights ==1

capture drop diff_form
gen diff_form = flexible_schedules + sun_prev + nights_reg_prev + ///
				l_hours_reg_prev + sunday_nights + long_flex
tab diff_form

local if "if diff_form>1"
foreach x in flexible_schedules sun_prev nights_reg_prev l_hours_reg_prev sunday_nights long_flex {
	di "`x'"
		tab diff_form if `x'==1 
 		tab flexible_schedules `x' `if'
 		tab sun_prev `x' `if'
 		tab nights_reg_prev `x' `if'
 		tab l_hours_reg_prev `x' `if'
 		tab sunday_nights `x' `if'
 		tab long_flex `x' `if'
 }

 
drop if diff_form >=2 /* 58 k - 2.4k */
save final_data_cut, replace /*contains only valid (for the analysis) individuals*/

/*export data for python*/
keep $varlist1 $varlist2 $varlist3 idn sectors_grouped sunday_nights long_flex		
export delimited "final_EWCS.csv", replace nolabel


