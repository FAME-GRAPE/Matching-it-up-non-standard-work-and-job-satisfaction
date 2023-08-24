//********************************************************************************** //
//*** This code replicates the results of a paper by Bech-Wysocka, Smyk
//*** Tyrowicz & van der Velde "Matching it up"
//*** https://grape.org.pl/article/matching-it-non-standard-work-and-job-satisfaction

//*** This code requires the data from European Working Conditions
//*** Survey to be obtained from UK Data Service: https://ukdataservice.ac.uk/ 

//*** Part of this code is executed in Python, you can either run it yourself
//*** or use STATA Python script to execute 2_ML_model.py.

//*** We use STATA 17 to execute this set of codes, but back to STATA 15 will 
//*** succeed, only Python script will have to be executed outside STATA.

//*** August 2023 
//********************************************************************************** //




version 17
clear 

do 1_data // data preparation

python script 2_ML_model.py // obtaining the ML predictions
do 2_ML_validation  // validation of the ML model, not necessary to run 3_analysis or 4_graphs

do 3_analysis // main results & tables 
do 4_graphs //  figures for the main results and appendices

