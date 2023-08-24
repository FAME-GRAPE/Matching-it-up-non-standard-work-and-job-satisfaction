clear

foreach type in ref flex_sched nights_reg  weekend long_flex l_hours_reg sun_nights {	
		import delimited modelref_dane`type'.csv, delimiter(";") clear
		rename prediction m_ref_d_`type'
		save data_modelref_dane`type', replace
}


use final_data_cut, clear
foreach type in  flex_sched nights_reg l_hours_reg weekend long_flex sun_nights {
		merge 1:m idn using data_modelref_dane`type', gen(merge_mref_d`type')
		duplicates drop

}

merge 1:m idn using data_modelref_daneref, gen(merge_mref_dref)
duplicates drop
drop if mi(countid) 

/*VALIDITY*/
* 1 internal -- Table C.1
tabout js1 m_ref_d_ref [iw=w5] ///
         using  internal_validity.txt, /// 
		 c(cell) f(1) clab(Cell_%) npos(row) ///
		 lay(cb) dpcomma ///
         style(tex) bt font(bold)  ///
		 replace
		 
* 2 external -- Table C.2
reg js2  js1 if !mi( m_ref_d_ref ), a(countid) vce(cluster countid)
est store js2_ref_js
reg js2  m_ref_d_ref if !mi( m_ref_d_ref ), a(countid) vce(cluster countid)
est store js2_ref

outreg2 [js2_*]  ///
using "external_validity.tex", tex(frag) replace


* taking away NWAs
gen js_ta_full  = .
replace js_ta_full = js1 - m_ref_d_flex_sched if !mi(m_ref_d_flex_sched)
replace js_ta_full = js1 - m_ref_d_nights_reg if !mi(m_ref_d_nights_reg)
replace js_ta_full = js1 - m_ref_d_l_hours_reg if !mi(m_ref_d_l_hours_reg)
replace js_ta_full = js1 - m_ref_d_weekend if !mi(m_ref_d_weekend)
replace js_ta_full = js1 - m_ref_d_long_flex if !mi(m_ref_d_long_flex)
replace js_ta_full = js1 - m_ref_d_sun_nights if !mi(m_ref_d_sun_nights)

gen js_ta_flex_sched = js1 - m_ref_d_flex_sched
gen js_ta_nights_reg = js1 - m_ref_d_nights_reg
gen js_ta_l_hours_reg = js1 - m_ref_d_l_hours_reg
gen js_ta_weekend = js1 - m_ref_d_weekend
gen js_ta_long_flex = js1 - m_ref_d_long_flex
gen js_ta_sun_nights = js1 - m_ref_d_sun_nights

** Comparison with more direct measures

gen worried     = Q45a<3 if !mi(Q45a)
gen tired       = Q45b<3 if !mi(Q45b)
gen notime_hh   = Q45c<3 if !mi(Q45c)
gen nofocus     = Q45d<3 if !mi(Q45d)
gen notime_wr   = Q45e<3 if !mi(Q45e)


label var worried      "Worry about work when not working"
label var tired        "Felt too tired after work to do household work"
label var notime_hh    "Job took time from family"
label var nofocus      "Cannot focus at work due to family"
label var notime_wr    "Family responsibilities took time from work"


gen improvement = 1-(js_ta_full >0) if !mi(js_ta_full)


 eststo est1: estpost ttest worried tired notime_hh nofocus notime_wr , by(improvement)

 local printto using direct_measures.tex
 esttab est1 `printto' , ///
        cell( (  mu_1(label("Yes") fmt(2)) mu_2(label("No") fmt(2)) b(s label("Diff.") fmt(2)) count(label("Obs.") fmt(0))  )) ///
		mlabel("Removing NWA improves life satisfaction") label sty(tex) nonumber stat( ) prefoot("") star( * 0.1 ** 0.05  *** 0.01 )

drop improvement
		
******* descriptives *****************
* Table 1
recode h_fit (1/2=0) (3/4=1) , g(hours_fit)
recode js1 (1/2=1) (3/4=0), g(js1_d)

gen id_model = 1 /*reference*/
replace id_model = 2 if flexible_schedules == 1
replace id_model = 3 if nights_reg_prev == 1
replace id_model = 4 if l_hours_reg_prev == 1
replace id_model = 5 if sun_prev == 1
replace id_model = 6 if long_flex == 1
replace id_model = 7 if sunday_nights == 1

local xv1	js1_d female single_hh child_u7 elder long_commute 
local xv2   sat_prev sun_prev nights_reg l_hours_reg_prev parttime flexible_schedules long_flex sunday_nights 
local xv3    hazardous hours_fit supportive_colleagues  enough_time 
global w 	[iw=w5]
eststo clear
eststo : 			quiet estpost sum `xv1' `xv2' `xv3'	$w
bys id_model : eststo :  quiet estpost sum `xv1' `xv2' `xv3'   $w


esttab est* , cells(mean(fmt(3))) refcat(female "\hline" , nolabel)

			
****************************** MODEL ****************************************

recode ends (4/6=0) (1/3=1), g(ends_d)
* ends_d=0 (do not meet ends), ends_d=1 (meet ends)
recode worry (4/5=0) (1/3=1), g(worry_d)
*worry_d =0 (do not worry), worry_d=1 (I worry)

global vars "js_ta_full js_ta_flex_sched js_ta_nights_reg js_ta_l_hours_reg js_ta_weekend js_ta_long_flex js_ta_sun_nights"

capture gen women_children = female * child_u7
fvset base 0 women_children 
fvset base 0 female
fvset base 0 child_u7
fvset base 3 wave

estimates drop _all
foreach var in  $vars {
capture drop yvar
*recode `var' (-3/-1=1)  (0/3=0), g(yvar)
recode `var' (-3/-1=1)  (1/3=0), g(yvar)
tab yvar, mi
	eststo: logit yvar   i.female i.child_u7 i.women_children i.age  i.countid i.wave /*flexible_schedule nights_reg_prev l_hours_reg_prev sun_prev long_flex sunday_nights*/, or vce(cluster countid)
	*estadd margins, dydx( i.female i.child_u7 i.women_children)
	predict y_hat_1
	quietly summ y_hat_1
	eststo, add(mean_pp r(mean))
	estat classification
	eststo, add(sens r(P_p1))
	eststo, add(spec r(P_n0))
	eststo, add(corr_c r(P_corr))
	est store s_im_`var'
	gen sample_`var' = e(sample)
/* eststo: logit yvar    i.female i.child_u7 i.women_children i.age  i.countid i.wave  i.ends_d i.worry_d fwc_d employer_sets enough_time , or vce(cluster countid)
	predict y_hat_2
	quietly summ y_hat_2
	eststo, add(mean_pp r(mean))
	estat classification
	eststo, add(sens r(P_p1))
	eststo, add(spec r(P_n0))
	eststo, add(corr_c r(P_corr))
	est store f_im_`var' */
drop yvar

gen yvar = -`var' // recode `var' (-3=3) (-2=2) (-1=1) (0=0) (1=-1) (2=-2) (3=-3), g(yvar)
*recode `var' (-3/-1=1)  (0=0) (1/3=-1), g(yvar)
eststo: ologit yvar   i.female i.child_u7 i.women_children i.age  i.countid i.wave /*flexible_schedule nights_reg_prev l_hours_reg_prev sun_prev long_flex sunday_nights*/, or vce(cluster countid)	
	predict y_hat_3
	quietly summ y_hat_3
	eststo, add(mean_pp r(mean))
	est store s_ologit_`var'
	gen sample_o_`var' = e(sample)
/* eststo: ologit yvar    i.female i.child_u7 i.women_children i.age  i.countid i.wave  i.ends_d i.worry_d fwc_d employer_sets enough_time , or vce(cluster countid)
	*estadd margins, dydx( i.female i.child_u7 i.women_children i.ends_d i.worry_d fwc employer_sets enough_time)
	predict y_hat_4
	quietly summ y_hat_4
	eststo, add(mean_pp r(mean))
	est store f_ologit_`var' */
drop yvar
drop y_hat_*
}

browse if sample_o_js_ta_flex_sched==1 & sample_js_ta_flex_sched==0
drop sample*


**************************************
gen yvar = - js_ta_flex_sched
ologit yvar i.female i.child_u7 i.women_children i.age  i.countid i.wave /*flexible_schedule nights_reg_prev l_hours_reg_prev sun_prev long_flex sunday_nights*/, vce(cluster countid)	
predict p1 p2 p3 p4 p5 p6 p7
egen maxpred = rowmax(p1-p7)
gen vpred = .
forval i = 1/7 {
replace vpred = `i' if p`i' == maxpred
}
tab2 yvar vpred
drop yvar
drop p1 p2 p3 p4 p5 p6 p7 maxpred vpred 

******************************************************

est table *_js_ta_flex_sched  , star(0.10 0.05 0.01) stat(N corr_c sens spec mean_pp) drop(i.countid i.wave) b(%9.2f) 

est table *_js_ta_nights_reg  , star(0.10 0.05 0.01) stat(N corr_c sens spec mean_pp) drop(i.countid i.wave) b(%9.2f) 

est table *_js_ta_l_hours_reg  , star(0.10 0.05 0.01) stat(N corr_c sens spec mean_pp) drop(i.countid i.wave) b(%9.2f) 

est table *_js_ta_weekend  , star(0.10 0.05 0.01) stat(N corr_c sens spec mean_pp) drop(i.countid i.wave) b(%9.2f) 

est table *_js_ta_full  , star(0.10 0.05 0.01) stat(N corr_c sens spec mean_pp) drop(i.countid i.wave) b(%9.2f) 

est table  s_ologit_js_ta_flex_sched s_ologit_js_ta_nights_reg s_ologit_js_ta_l_hours_reg s_ologit_js_ta_weekend , star(0.15 0.10 0.05)  stat(N corr_c sens spec mean_pp) drop(i.countid i.wave i.age_groups) b(%9.2f) 

est table  s_im_js_ta_flex_sched s_im_js_ta_nights_reg s_im_js_ta_l_hours_reg s_im_js_ta_weekend , star(0.15 0.10 0.05)  stat(N corr_c sens spec mean_pp) drop(i.countid i.wave i.age_groups) b(%9.2f) 

est table s_im_js_ta_flex_sched s_ologit_js_ta_flex_sched s_im_js_ta_nights_reg s_ologit_js_ta_nights_reg s_im_js_ta_l_hours_reg s_ologit_js_ta_l_hours_reg s_im_js_ta_weekend s_ologit_js_ta_weekend s_im_js_ta_long_flex s_ologit_js_ta_long_flex s_im_js_ta_sun_nights s_ologit_js_ta_sun_nights, star(0.15 0.10 0.05)  stat(N corr_c sens spec mean_pp) drop(i.countid i.wave i.age_groups) b(%9.2f) 

 
******* tex tables ************
local tbname using results_final.tex

local addspace "\rule{0pt}{4ex}"

estout s_im_js_ta_flex_sched s_ologit_js_ta_flex_sched s_im_js_ta_nights_reg s_ologit_js_ta_nights_reg s_im_js_ta_l_hours_reg s_ologit_js_ta_l_hours_reg s_im_js_ta_weekend s_ologit_js_ta_weekend s_im_js_ta_long_flex s_ologit_js_ta_long_flex  s_im_js_ta_sun_nights s_ologit_js_ta_sun_nights  `tbname' , replace    ///
			starlevels(* .15 ** .10 *** .05) stats(N mean_pp corr_c  spec, fmt(0 2) labels("\hline \hline Observations" "\hline \hline Mean predicted probability" "\hline \hline Correctly classified"  "Specificity")) ///
			cells("b(fmt(2) star)" "se(par fmt(2))")  sty(tex) nobase collabels(none)  ///
			drop(*cons *countid *wave *age* *cut*)  ///
			mlabels("Logit" "OLogit" "Logit" "OLogit" "Logit" "OLogit" "Logit" "OLogit" "Logit" "OLogit" "Logit" "OLogit"  , nodepvars ) ///
			varlabel(1.female "woman (\$\beta_w\$)"  1.child_u7 "parent (\$\beta_p\$)" 1.women_children "woman \$\times\$ parent (\$\gamma \$)" 1.ends_d "able to meet ends" fwc_d "family work conflict" 1.worry_d "worry about work when not working"  enough_time "enough time to finish tasks" employer_sets_time "employer sets time") ///
			prehead("\begin{tabular}{l|ll|ll|ll|ll|ll|ll} ""\hline \hline" "&\multicolumn{2}{c|}{\textbf{Varying hours}} & \multicolumn{2}{c|}{\textbf{Nights}} & \multicolumn{2}{c|}{\textbf{Long hours}} & \multicolumn{2}{c}{\textbf{Sundays}} & \multicolumn{2}{c|}{\textbf{Long_flex}} & \multicolumn{2}{c|}{\textbf{Sunday nights}}\\") ///
			posthead("\hline \hline") ///
			postfoot("\hline \hline" "\end{tabular}")
			
***************************	
local tbname using results_final_full.tex

local addspace "\rule{0pt}{4ex}"

estout s_im_js_ta_full  s_ologit_js_ta_full  `tbname' , replace    ///
			starlevels(* .15 ** .10 *** .05) stats(N mean_pp corr_c  spec, fmt(0 2) labels("\hline \hline Observations" "\hline \hline Mean predicted probability" "\hline \hline Correctly classified"  "Specificity")) ///
			cells("b(fmt(2) star)" "se(par fmt(2))")  sty(tex) nobase collabels(none)  ///
			drop(*cons *countid *wave *age* *cut*)  ///
			mlabels("Base model" "Extended model" "Base model" "Extended model" , nodepvars ) ///
			varlabel(1.female "woman (\$\beta_w\$)"  1.child_u7 "parent (\$\beta_p\$)" 1.women_children "woman \$\times\$ parent (\$\gamma \$)" 1.ends_d "able to meet ends" fwc_d "family work conflict" 1.worry_d "worry about work when not working"  enough_time "enough time to finish tasks" employer_sets_time "employer sets time") ///
			prehead("\begin{tabular}{l|llll} ""\hline \hline" "& \multicolumn{2}{c}{Logistic regression}  &\multicolumn{2}{c}{Ordered logistic regression}") ///
			posthead("\hline \hline") ///
			postfoot("\hline \hline" "\end{tabular}")


  
  
  
  
  
  
