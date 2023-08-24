/*probit check -- Table C.1*/
clear
import delimited "data_flexi_split_0.csv", delimiter(";") varnames(1) encoding(utf8) 

/*MODEL*/
global depvar "target"
global indepvars "female child_u7 elder occ_cat ind_cat sectors_grouped hazardous h_fit supportive_colleagues enough_time age_groups parttime single_hh long_commute sat_prev sun_prev l_hours_prev l_hours_reg_prev nights_prev nights_reg_prev flexible_schedules long_flex sunday_nights"

oprobit $depvar $indepvars

predict p1 p2 p3 p4
egen maxpred = rowmax(p1-p4)
gen vpred = .
forval i = 1/4 {
replace vpred = `i' if p`i' == maxpred
}

/*INTERNAL VALIDITY*/
tab2 target vpred, cell 











