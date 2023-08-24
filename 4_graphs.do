use final_data_cut, clear
foreach type in  flex_sched nights_reg l_hours_reg weekend long_flex sun_nights {
		merge 1:m idn using data_modelref_dane`type', gen(merge_mref_d`type')
		duplicates drop

}

merge 1:m idn using data_modelref_daneref, gen(merge_mref_dref)
duplicates drop
drop if mi(countid) 

ren flexible_schedules flex_sched 
ren nights_reg_prev nights_reg
ren l_hours_reg_prev l_hours_reg
ren sun_prev weekend 
* long_flex 
ren sunday_nights sun_nights 

recode js1 (1/2=1) (3/4=0), gen(d_js1)

gen js_ta_full  = . 
foreach var in flex_sched  nights_reg l_hours_reg weekend long_flex sun_nights {
replace js_ta_full = js1 - m_ref_d_`var' if !mi(m_ref_d_`var')
gen js_ta_`var' = js1 - m_ref_d_`var'
}
capture label drop change
label define change 1 "rise in JS" -1 "decline in JS" 0 "no change in JS"

foreach var in flex_sched  nights_reg l_hours_reg weekend long_flex sun_nights  {
* female/male
gen `var'_female = `var' 						if female == 1
gen `var'_male = `var' 							if female == 0
gen js_ta_`var'_female = js_ta_`var'	if female == 1
gen js_ta_`var'_male = js_ta_`var' 		if female == 0
* parent/non-parent
gen `var'_parent = `var' 								if child_u7 == 1
gen `var'_nonparent = `var' 						if child_u7 == 0
gen js_ta_`var'_parent = js_ta_`var' 			if child_u7 == 1
gen js_ta_`var'_nonparent = js_ta_`var' 	if child_u7 == 0
}

// Figure C1
dotplot js2, over(js1) xsize(6) scheme(burd)

graph save jsatisfaction2.gph, replace
graph export jsatisfaction2.eps, replace
graph export jsatisfaction2.png, replace
graph export jsatisfaction2.pdf, replace

// Figure 1 - job satisfaction across countries
tab js1, g(jobsatisfaction)
graph bar (mean) jobsatisfaction* if wave>3 [aw=w5], ///
	over(countid, label(angle(vertical))) stack ///
	bar(1,color("blue") lcolor(black)) ///
	bar(2,color("blue"%60) lcolor(black%80)) ///
	bar(3,color("blue"%40) lcolor(black%80)) ///
	bar(4,color("blue"%20) lcolor(black%80)) ///
	legend(order(1 "very satisfied" 2 "satisfied" 3 "dissatisfied" 4 "very dissatisfied") ///
	cols(4)) xsize(7) ysize(3) scheme(burd)
graph save jsatisfaction.gph, replace
graph export jsatisfaction.eps, replace
graph export jsatisfaction.png, replace
graph export jsatisfaction.pdf, replace

	
// Figure 2 - NWA across countries
graph bar (mean) flex_sched  nights_reg l_hours_reg  weekend long_flex sun_nights if wave>3 [aw=w5],  ///
         over(countid, sort(1) descending label(angle(vertical)))  stack ///
         legend(order(- "% of population working: " - 1 "varying hours" 2 "nights" 3 "long hours" 4 "Sundays" 5 "long & varying hours" 6 "Sundays & nights") ///
         ring(1) bplacement(south) size(small) rows(1)) ///
		bar(1,color("cranberry") lcolor(black)) ///
		bar(2,color("cranberry"%85) lcolor(black%80)) ///
		bar(3,color("cranberry"%65) lcolor(black%80)) ///
		bar(4,color("cranberry"%45) lcolor(black%80)) ///
		bar(5,color("cranberry"%30) lcolor(black%80)) ///
		bar(6,color("cranberry"%15) lcolor(black%80)) ///
         xsize(7) ysize(3) scheme(burd) 
graph save NWA.gph, replace
graph export NWA.eps, replace
graph export NWA.png, replace
graph export NWA.pdf, replace
		 
// Figure 3 
histogram	js_ta_full, discrete percent   ytitle("percent ")  xsize(4) ysize(2) xtitle(" {&Delta}JS")   ///
					xlabel(-3 "JS down 3 levels"-2 "{&Delta}JS= -2 " -1 " {&Delta}JS= -1"  0 "{&Delta}JS=0" 1 " {&Delta}JS=1" 2 " {&Delta}JS=2" 3 "JS  up 3 levels")  ///
					 scheme(burd)
graph save change_JS_total.gph, replace
graph export change_JS_total.eps, replace
graph export change_JS_total.png, replace
graph export change_JS_total.pdf, replace
					 
// Figure E1 
graph bar	(percent) js_ta_flex_sched  js_ta_nights_reg    js_ta_l_hours_reg js_ta_weekend  js_ta_long_flex js_ta_sun_nights,   ///
					over(js_ta_full, relabel(1 "JS down 3 levels"2 "{&Delta}JS= -2 " 3 " {&Delta}JS= -1"  4 "{&Delta}JS=0" 5 " {&Delta}JS=1" 6 " {&Delta}JS=2" 7 "JS  up 3 levels") )  ///
					legend(order(1 "varying hours" 2 "nights" 3 "long hours" 4 "Sundays" 5 "long & varying hours" 6 "Sundays & nights") cols(4) )  ///
					ytitle("percent ")  xsize(4) ysize(2) ///
					 scheme(burd)					 
graph save change_JS_each.gph, replace
graph export change_JS_each.eps, replace
graph export change_JS_each.png, replace
graph export change_JS_each.pdf, replace
					 
// Figure - BARS with NWA changes 
global vars " js_ta_flex_sched js_ta_nights_reg js_ta_l_hours_reg js_ta_weekend js_ta_long_flex js_ta_sun_nights "

foreach var in $vars {
	tab `var', mi
	capture drop yvar
	recode `var' (-3/-2=-1) (2/3=1), g(yvar)
	label values yvar change
	tab countid yvar [iw=w5], matcell(mat_`var')
	mat mat_`var' =  mat_`var' 
}

mat stack = (mat_js_ta_flex_sched, mat_js_ta_nights_reg, mat_js_ta_l_hours_reg, mat_js_ta_weekend, mat_js_ta_long_flex, mat_js_ta_sun_nights)
preserve  
clear
svmat stack, names(c)

do 3a_matshort

foreach change in reduced unchanged increased {
	gen JS_FULL_TA_`change' =  JS_FLEX_SCHED_TA_`change'  + JS_L_HOURS_REG_TA_`change' +JS_NIGHTS_REG_TA_`change' + JS_WEEKEND_TA_`change' + JS_LONG_FLEX_TA_`change' + JS_SUN_NIGHTS_TA_`change'
}

foreach var in FULL FLEX_SCHED NIGHTS_REG L_HOURS_REG WEEKEND LONG_FLEX SUN_NIGHTS {
	gen total_`var'_TA = JS_`var'_TA_reduced+JS_`var'_TA_unchanged+JS_`var'_TA_increased
	foreach change in reduced unchanged increased {
			replace JS_`var'_TA_`change'= JS_`var'_TA_`change'/total_`var'_TA
	}
}

do 3b_country_labels

// Figure E2
graph bar (mean) JS_FULL_TA_unchanged  ,    ///
			over(country, sort(1) label(angle(90)))  ///
			bar(1,fcolor(dkgreen) lcolor(white))  	xsize(5) ysize(2)   ytitle(" ") 
graph save TA_full_no_change, replace
graph export TA_full_no_change.eps,  replace
graph export TA_full_no_change.png, replace
graph export TA_full_no_change.pdf, replace
			
// Figure E3
graph bar (mean) JS_FLEX_SCHED_TA_unchanged JS_NIGHTS_REG_TA_unchanged JS_L_HOURS_REG_TA_unchanged JS_WEEKEND_TA_unchanged JS_LONG_FLEX_TA_unchanged JS_SUN_NIGHTS_TA_unchanged ,    ///
			over(country, sort(1) label(angle(90)))  xsize(5) ysize(2) scheme(burd) ///
			bar(1,color("dkgreen") lcolor(white)) ///
			bar(2,color("dkgreen"%80) lcolor(white)) ///
			bar(3,color("dkgreen"%60) lcolor(white)) ///
			bar(4,color("dkgreen"%40) lcolor(white)) ///
			bar(5,color("dkgreen"%25) lcolor(white)) ///
			bar(6,color("dkgreen"%10) lcolor(white)) ///
			legend(order(1 "varying hours" 2 "nights" 3 "long hours" 4 "Sundays" 5 "long & varying hours" 6 "Sundays & nights") rows(2)) ytitle(" ") 
graph save TA_all_no_change, replace
graph export TA_all_no_change.eps,  replace
graph export TA_all_no_change.png, replace
graph export TA_all_no_change.pdf, replace
			
restore

// Figure - change in NWAs separately for genders and parents
global vars js_ta_flex_sched_female js_ta_flex_sched_male js_ta_flex_sched_parent js_ta_flex_sched_nonparent ///
					js_ta_nights_reg_female js_ta_nights_reg_male js_ta_nights_reg_parent js_ta_nights_reg_nonparent  ///
					js_ta_l_hours_reg_female js_ta_l_hours_reg_male js_ta_l_hours_reg_parent js_ta_l_hours_reg_nonparent ///
					js_ta_weekend_female js_ta_weekend_male js_ta_weekend_parent js_ta_weekend_nonparent ///
					js_ta_long_flex_female js_ta_long_flex_male js_ta_long_flex_parent js_ta_long_flex_nonparent ///
					js_ta_sun_nights_female js_ta_sun_nights_male js_ta_sun_nights_parent js_ta_sun_nights_nonparent

foreach var in js_ta_full $vars {
	tab `var', mi
	capture drop yvar
	recode `var' (-3/-2=-1) (2/3=1), g(yvar)
	label values yvar change
	tab countid yvar [iw=w5], matcell(mat_`var')
	mat mat_`var' =  mat_`var' 
}

mat stack = 	(mat_js_ta_flex_sched_female, mat_js_ta_flex_sched_male, mat_js_ta_flex_sched_parent, mat_js_ta_flex_sched_nonparent, ///
						mat_js_ta_nights_reg_female, mat_js_ta_nights_reg_male, mat_js_ta_nights_reg_parent, mat_js_ta_nights_reg_nonparent, ///
						mat_js_ta_l_hours_reg_female, mat_js_ta_l_hours_reg_male, mat_js_ta_l_hours_reg_parent, mat_js_ta_l_hours_reg_nonparent,  ///
						mat_js_ta_weekend_female, mat_js_ta_weekend_male, mat_js_ta_weekend_parent, mat_js_ta_weekend_nonparent, ///
						mat_js_ta_long_flex_female, mat_js_ta_long_flex_male, mat_js_ta_long_flex_parent, mat_js_ta_long_flex_nonparent, ///
						mat_js_ta_sun_nights_female, mat_js_ta_sun_nights_male, mat_js_ta_sun_nights_parent, mat_js_ta_sun_nights_nonparent) 
 
preserve  
clear
svmat stack, names(c)
do 3a_matlong
do 3b_country_labels

foreach type in F M P NP {
	foreach change in reduced unchanged increased {
	gen JS_FULL_`type'_TA_`change' =  JS_FLEX_SCHED_`type'_TA_`change'  + JS_L_HOURS_REG_`type'_TA_`change' +JS_NIGHTS_REG_`type'_TA_`change' + JS_WEEKEND_`type'_TA_`change' + JS_LONG_FLEX_`type'_TA_`change' + JS_SUN_NIGHTS_`type'_TA_`change'
	}
	
	foreach var in FULL FLEX_SCHED NIGHTS_REG L_HOURS_REG WEEKEND LONG_FLEX SUN_NIGHTS {
	gen total_`var'_`type'_TA = JS_`var'_`type'_TA_increased + JS_`var'_`type'_TA_reduced + JS_`var'_`type'_TA_unchanged
	}
}

foreach change in reduced unchanged increased {
	foreach type in F M P NP {
			foreach var in FULL FLEX_SCHED NIGHTS_REG L_HOURS_REG WEEKEND LONG_FLEX SUN_NIGHTS {
			replace JS_`var'_`type'_TA_`change'= JS_`var'_`type'_TA_`change'/total_`var'_`type'_TA
		}
	}
}

gen cn1 = countid - 0.25
gen cn2 = countid + 0.25

label define cn 		1 "Austria" 2 "Belgium" 3  "Bulgaria" 4 "Cyprus" 5 "Czech Republic" 6 "Denmark" 7 "Estonia" 8 "Finland" 9 "France" 10 "Germany" 11 "Greece" 12 "Hungary" 13 "Ireland" 14 "Italy" 15 "Latvia" 16 "Lithuania" ///
								17 "Luxembourg" 18 "Malta" 19 "Netherlands" 20 "Poland" 21 "Portugal" 22 "Romania" 23 "Slovakia" 24 "Slovenia" 25 "Spain" 26 "Sweden" 27 "United Kingdom" 0 " " 30 " "
label values cn1 cn
label values cn2 cn


foreach var in FULL FLEX_SCHED NIGHTS_REG L_HOURS_REG WEEKEND LONG_FLEX SUN_NIGHTS {
	foreach type in F M P NP {
	gen pos_JS_`var'_`type'_TA = JS_`var'_`type'_TA_increased 
	gen neg_JS_`var'_`type'_TA =- JS_`var'_`type'_TA_reduced 
	gen net_JS_`var'_`type' =( JS_`var'_`type'_TA_increased - JS_`var'_`type'_TA_reduced )  
	}

// Figure -  bars for men and women - Figure 4 & Appendix E
twoway	(bar pos_JS_`var'_F_TA neg_JS_`var'_F_TA  cn1, ///
			barwidth(0.5 0.5)  		fcolor("cranberry" "cranberry")  		fintensity(inten60 inten30)  		lcolor(white white)) /// 
		(bar pos_JS_`var'_M_TA  neg_JS_`var'_M_TA  cn2, /// 
			barwidth(0.5 0.5)  		fcolor("gs12" "gs12")  					fintensity(inten60 inten30)  		lcolor(white white)) /// 
		(scatter net_JS_`var'_F cn1, msymbol(dot) mcolor("cranberry"))  /// 
		(scatter net_JS_`var'_M cn2, msymbol(diamond) mcolor("gs2")), /// 
			xsize(5) ysize(2.5) ylabel(-0.6(0.2)0.6, labsize(small) )  scale(0.7) /// 
			legend(order(- "Women:" - "Men:" 1 "taking away NWA raises JS" 3 "taking away NWA raises JS" 2 "taking away NWA reduces JS"   4 "taking away NWA reduces JS" 5 "net change" 6 "net change") cols(2) ) /// 
			xlabel(1 "Austria", add angle(90) labsize(small)) /// 
			xlabel(2 "Belgium", add angle(90)) /// 
			xlabel(3 "Bulgaria", add angle(90)) /// 
			xlabel(4 "Cyprus", add angle(90)) /// 
			xlabel(5 "Czech Republic", add angle(90)) /// 
			xlabel(6 "Denmark", add angle(90)) /// 
			xlabel(7 "Estonia", add angle(90)) /// 
			xlabel(8 "Finland", add angle(90)) /// 
			xlabel(9 "France", add angle(90)) /// 
			xlabel(10 "Germany", add angle(90)) /// 
			xlabel(11 "Greece", add angle(90)) /// 
			xlabel(12 "Hungary", add angle(90)) /// 
			xlabel(13 "Ireland", add angle(90)) /// 
			xlabel(14 "Italy", add angle(90)) /// 
			xlabel(15 "Latvia", add angle(90)) /// 
			xlabel(16 "Lithuania", add angle(90)) /// 
			xlabel(17 "Luxembourg", add angle(90)) /// 
			xlabel(18 "Malta", add angle(90)) /// 
			xlabel(19 "Netherlands", add angle(90)) /// 
			xlabel(20 "Poland", add angle(90)) /// 
			xlabel(21 "Portugal", add angle(90)) /// 
			xlabel(22 "Romania", add angle(90)) /// 
			xlabel(23 "Slovakia", add angle(90)) /// 
			xlabel(24 "Slovenia", add angle(90)) /// 
			xlabel(25 "Spain", add angle(90)) /// 
			xlabel(26 "Sweden", add angle(90)) /// 
			xlabel(27 "United Kingdom", add angle(90)) /// 
			xlabel(0 " ", add custom labcolor(white)) /// 
			xlabel(30 " ", add custom labcolor(white))
graph save TA_`var'_gender_bars, replace
graph export TA_`var'_gender_bars.eps,  replace
graph export TA_`var'_gender_bars.png, replace
graph export TA_`var'_gender_bars.pdf, replace
			
// Figure - bars for parents and non-parents - Figure 4 & Appendix E

twoway	(bar pos_JS_`var'_P_TA neg_JS_`var'_P_TA  cn1, ///
			barwidth(0.5 0.5) 			fcolor("green" "green")  	fintensity(inten60 inten30)  		lcolor(white white)) /// 
		(bar pos_JS_`var'_NP_TA neg_JS_`var'_NP_TA  cn2, /// 
			barwidth(0.5 0.5)  		fcolor("orange" "orange")  		fintensity(inten60 inten30)  		lcolor(white white)) /// 
		(scatter net_JS_`var'_P cn1, msymbol(square) mcolor("green"))  /// 
		(scatter net_JS_`var'_NP cn2, msymbol(triangle) mcolor("orange")), /// 
			xsize(5) ysize(2.5) ylabel(-0.6(0.2)0.6, labsize(small) )  scale(0.7) /// 
			legend(order(- "Parents:" - "Non-parents:" 1 "taking away NWA raises JS" 3 "taking away NWA raises JS" 2 "taking away NWA reduces JS"   4 "taking away NWA reduces JS" 5 "net change" 6 "net change") cols(2)) /// 
			xlabel(1 "Austria", add angle(90) labsize(small)) /// 
			xlabel(2 "Belgium", add angle(90)) /// 
			xlabel(3 "Bulgaria", add angle(90)) /// 
			xlabel(4 "Cyprus", add angle(90)) /// 
			xlabel(5 "Czech Republic", add angle(90)) /// 
			xlabel(6 "Denmark", add angle(90)) /// 
			xlabel(7 "Estonia", add angle(90)) /// 
			xlabel(8 "Finland", add angle(90)) /// 
			xlabel(9 "France", add angle(90)) /// 
			xlabel(10 "Germany", add angle(90)) /// 
			xlabel(11 "Greece", add angle(90)) /// 
			xlabel(12 "Hungary", add angle(90)) /// 
			xlabel(13 "Ireland", add angle(90)) /// 
			xlabel(14 "Italy", add angle(90)) /// 
			xlabel(15 "Latvia", add angle(90)) /// 
			xlabel(16 "Lithuania", add angle(90)) /// 
			xlabel(17 "Luxembourg", add angle(90)) /// 
			xlabel(18 "Malta", add angle(90)) /// 
			xlabel(19 "Netherlands", add angle(90)) /// 
			xlabel(20 "Poland", add angle(90)) /// 
			xlabel(21 "Portugal", add angle(90)) /// 
			xlabel(22 "Romania", add angle(90)) /// 
			xlabel(23 "Slovakia", add angle(90)) /// 
			xlabel(24 "Slovenia", add angle(90)) /// 
			xlabel(25 "Spain", add angle(90)) /// 
			xlabel(26 "Sweden", add angle(90)) /// 
			xlabel(27 "United Kingdom", add angle(90)) /// 
			xlabel(0 " ", add custom labcolor(white)) /// 
			xlabel(30 " ", add custom labcolor(white))
graph save TA_`var'_parents_bars, replace
graph export TA_`var'_parents_bars.eps,  replace
graph export TA_`var'_parents_bars.png, replace
graph export TA_`var'_parents_bars.pdf, replace

}

restore


************************ OPTIMAL NSE ************************

global types "flex_sched nights_reg l_hours_reg  weekend long_flex sun_nights"
gen optimal_full  = .
gen no_full  = .
foreach var in $types {
replace optimal_full = min(js1,m_ref_d_`var') if !mi(m_ref_d_`var')
replace no_full = min(m_ref_d_`var', m_ref_d_ref) if !mi(m_ref_d_`var')
gen optimal_`var' = min(js1,m_ref_d_`var')  if !mi(m_ref_d_`var')
recode optimal_`var'  (1/2=1) (3/4=0), gen(d_optimal_`var' )
gen no_`var' =  min(m_ref_d_`var', m_ref_d_ref)  if !mi(m_ref_d_`var')
recode no_`var' (1/2=1) (3/4=0), gen(d_no_`var')
recode js_ta_`var' (-1/0=0)
replace js_ta_`var'  = . if `var'==0
	foreach type in female male nonparent parent {
	recode js_ta_`var'_`type' (-1/0=0)
	replace js_ta_`var'_female = . if `var'==0
	}
gen non_`var' = `var'==0 
replace d_no_`var'=. if non_`var'==1
}
recode optimal_full (1/2=1) (3/4=0), gen(d_optimal_full)
recode no_full(1/2=1) (3/4=0), gen(d_no_full)

preserve
collapse (mean) 	d_optimal_full d_no_full d_js1 js_ta_full    ///
								[iw=w5], by(countid female child_u7)

// Figure - scatter with countries // none vs original
capture drop clock
egen clock = mlabvpos(d_optimal_full d_js1)
twoway 		(scatter d_no_full d_js1 if female==1, mlabsize(small) mcolor(cranberry) mlabvpos(clock)  mlabcolor(cranberry) msymbol(circle) )  ///
			(scatter d_no_full d_js1 if female==0, mlabsize(small) mcolor(cranberry) mlabvpos(clock)  mlabcolor(cranberry) msymbol(circle_hollow) )  ///
			(line d_js1 d_js1, lcolor(gs12) )   ,	///
			xtitle("Original % of satisfied workers") ytitle("% of satisfied workers if NWAs are eliminated") scheme(burd)  title("") ///
			legend(order(1 "women" 2  "men" 3 "status quo") cols(3))   name(none_gender, replace)

capture drop clock
egen clock = mlabvpos(d_optimal_full d_js1)
twoway 		(scatter d_no_full d_js1 if child_u7==1, mlabsize(small) mcolor(dkgreen) mlabvpos(clock)  mlabcolor(cranberry) msymbol(square) )  ///
			(scatter d_no_full d_js1 if child_u7==0, mlabsize(small) mcolor(dkgreen) mlabvpos(clock)  mlabcolor(cranberry) msymbol(square_hollow) )  ///
			(line d_js1 d_js1, lcolor(gs12) )   ,	///
			xtitle("Original % of satisfied workers") ytitle("% of satisfied workers if NWAs are eliminated") scheme(burd)  title("") ///
			legend(order(1 "parents" 2  "not parents" 3 "status quo") cols(3))   name(none_parents, replace)
								
graph combine none_gender none_parents, ycommon xsize(5) ysize(2) scheme(burd)	iscale(1)		
graph save counterfactual_full, replace
graph export counterfactual_full.eps,  replace
graph export counterfactual_full.png, replace
graph export counterfactual_full.pdf, replace
restore

preserve
collapse (mean) 	$types  ///
					flex_sched_female  nights_reg_female l_hours_reg_female weekend_female long_flex_female sun_nights_female ///
					flex_sched_male  nights_reg_male l_hours_reg_male weekend_male long_flex_male sun_nights_male ///
					flex_sched_parent  nights_reg_parent l_hours_reg_parent weekend_parent long_flex_parent sun_nights_parent ///
					flex_sched_nonparent  nights_reg_nonparent l_hours_reg_nonparent weekend_nonparent long_flex_nonparent sun_nights_nonparent ///
					js_ta_flex_sched js_ta_nights_reg js_ta_l_hours_reg js_ta_weekend js_ta_long_flex js_ta_sun_nights ///
					js_ta_flex_sched_female js_ta_nights_reg_female js_ta_l_hours_reg_female js_ta_weekend_female js_ta_long_flex_female js_ta_sun_nights_female ///
					js_ta_flex_sched_male js_ta_nights_reg_male js_ta_l_hours_reg_male js_ta_weekend_male js_ta_long_flex_male js_ta_sun_nights_male ///
					js_ta_flex_sched_parent js_ta_nights_reg_parent js_ta_l_hours_reg_parent js_ta_weekend_parent js_ta_long_flex_parent js_ta_sun_nights_parent /// 
					js_ta_flex_sched_nonparent js_ta_nights_reg_nonparent js_ta_l_hours_reg_nonparent js_ta_weekend_nonparent js_ta_long_flex_nonparent js_ta_sun_nights_nonparent /// 
							[iw=w5], by(countid)

// Figure F10 - scatter for each NWA separately // none vs original 
label var js_ta_flex_sched "varying hours"
label var js_ta_nights_reg  "nights"
label var js_ta_l_hours_reg "long hours"
label var js_ta_weekend "Sundays"
label var js_ta_long_flex "long and varying hours"
label var js_ta_sun_nights "Sundays & nights"

foreach var in  $types {
local title : var label js_ta_`var'
twoway 	(lfitci  js_ta_`var' `var', clcolor(gs18) fcolor("gs12"%20) fintensity(inten20)  alcolor(white) 	)  ///
				(scatter js_ta_`var'_female		`var'_female				, mcolor(cranberry) msize(small) msymbol(circle)  )  ///
				(scatter js_ta_`var'_male			`var'_male					, mcolor(cranberry) msize(small) msymbol(circle_hollow)  ) ///
				(scatter js_ta_`var'_parent			`var'_parent			, mcolor(dkgreen) msize(small) msymbol(square)  )  ///
				(scatter js_ta_`var'_nonparent	`var'_nonparent	, mcolor(dkgreen) msize(small) msymbol(square_hollow)  ),  ///
				yline(0, lcolor(black))  xscale(range(0(0.05)0.25)) ylabel(-0.5(0.25)1, labsize(small) )  ///
				xtitle("% of workers with `title' ") ytitle("% of workers in NWAs who gain if" "`title' are eliminated", suffix nobox margin(zero) bmargin(zero)  bexpand) scheme(burd) ///
				title("`title'")  plotregion(margin(zero)) ///				
				legend(order(2 "Linear fit"  - - - 3 "women"  4 "men" 5 "parents"  6 " not parents" ) cols(4))   
	graph save counterfactual_`var', replace
	graph export counterfactual_`var'.eps,  replace
	graph export counterfactual_`var'.png, replace
	graph export counterfactual_`var'.pdf, replace
		
		
}
restore


preserve
collapse (mean) 	$types  ///
					flex_sched_female  nights_reg_female l_hours_reg_female weekend_female long_flex_female sun_nights_female ///
					flex_sched_male  nights_reg_male l_hours_reg_male weekend_male long_flex_male sun_nights_male ///
					flex_sched_parent  nights_reg_parent l_hours_reg_parent weekend_parent long_flex_parent sun_nights_parent ///
					flex_sched_nonparent  nights_reg_nonparent l_hours_reg_nonparent weekend_nonparent long_flex_nonparent sun_nights_nonparent ///
					js_ta_flex_sched js_ta_nights_reg js_ta_l_hours_reg js_ta_weekend js_ta_long_flex js_ta_sun_nights ///
					js_ta_flex_sched_female js_ta_nights_reg_female js_ta_l_hours_reg_female js_ta_weekend_female js_ta_long_flex_female js_ta_sun_nights_female ///
					js_ta_flex_sched_male js_ta_nights_reg_male js_ta_l_hours_reg_male js_ta_weekend_male js_ta_long_flex_male js_ta_sun_nights_male ///
					js_ta_flex_sched_parent js_ta_nights_reg_parent js_ta_l_hours_reg_parent js_ta_weekend_parent js_ta_long_flex_parent js_ta_sun_nights_parent /// 
					js_ta_flex_sched_nonparent js_ta_nights_reg_nonparent js_ta_l_hours_reg_nonparent js_ta_weekend_nonparent js_ta_long_flex_nonparent js_ta_sun_nights_nonparent /// 
							[iw=w5], by(countid wave)

foreach var in  $types {
	areg js_ta_`var' `var', a(countid)
	}
restore
