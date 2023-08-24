1. Get the dataset (ewcs_1991-2015_ukda downloaded from https://ukdataservice.ac.uk/).
2. Set paths in 2_ML_model.py file (navigate to the folder with downloaded codes).
3. Run MASTER_file.do (or execute codes one by one) and enjoy.



It consists of:
1. 1_data.do 
	- requires: EWCS dataset (ewcs_1991-2015_ukda downloaded from https://ukdataservice.ac.uk/)
	- produces: 	(i) "final_data_cut.dta" (the main dataset for the analysis)
			(ii) "final_EWCS.csv" (same dataset, but csv format -- to upload in Python)

2. 2_ML_model.py 
	- requires: "final_EWCS.csv"
	- produces: 	"modelref_daneref.csv"
			"modelref_daneflex_sched.csv"
			"modelref_danenights_reg.csv"
			"modelref_danel_hours_reg.csv"
			"modelref_daneweekend.csv"
			"modelref_danelong_flex.csv"
			"modelref_danesun_nights.csv" (model predictions)
			"data_flexi_split_0.csv" (for probit comparison) 
You have to set paths to run this script.

2. 2_ML_validation.do
	- requires: "data_flexi_split_0.csv"
	- produces: accuracy comparisons with ordered probit

3. 3_analysis.do (with 3a_ and 3b_ additional files)
	- requires: "final_data_cut.dta" and csvs from step 2 
	- produces: estimation results & other outcomes 

4. 4_graphs.do 
	- requires: "final_data_cut.dta" and csvs from step 2 
	- produces: all figures
