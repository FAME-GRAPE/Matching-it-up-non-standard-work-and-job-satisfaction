# -*- coding: utf-8 -*-
"""
Created on 22.05.2021
Revised on 21.08.2021 & 24.08.2023
@author: katarzyna.bech-wysocka

-- This code requires an input dataset file (final_EWCS.csv)
and produces seven output files: 
    
modelref_daneref.csv
modelref_daneflex_sched.csv
modelref_danenights_reg.csv
modelref_danel_hours_reg.csv
modelref_daneweekend.csv
modelref_danelong_flex.csv
modelref_danesun_nights.csv

with predicted (by random forest) job satisfaction levels
"""

#IMPORTS -- load all necessary packages and functions
import os
import inspect
import pandas as pd
import statsmodels.api as sm
import numpy as np
from sklearn import metrics
import sklearn
from collections import defaultdict
from sklearn import linear_model
import csv
from sklearn.ensemble import RandomForestClassifier

#SET SEED -- for replicability of results
sklearn.utils.check_random_state(np.random.seed(1))

################################################################################
################## GLOBAL CONFIGURATION ########################################
################################################################################

#SET PATHS & INPUT DATA FILE
os.getcwd() # check working directory
data_dir = "PATH"  # SET PATH HERE
data_file = "final_EWCS.csv"

#READ DATA
os.chdir(data_dir)
df=pd.read_csv(data_file, sep=",")

#PREPARE DATASET COPY
data_cl=df.copy()  

################################################################################
################## SET TARGET # job satisfaction ###############################
################################################################################

data_cl["target"] = data_cl["js1"]
data_cl.drop('js1', axis=1, inplace=True)

# drop obs with NA target
data_cl = data_cl[pd.notnull(data_cl['target'])] 

# drop unnecessary variables
data_cl.drop('ends', axis=1, inplace=True)
data_cl.drop('fwc_d', axis=1, inplace=True)
data_cl.drop('worry', axis=1, inplace=True)
data_cl.drop('employer_sets_time', axis=1, inplace=True)
data_cl.drop('sat_or_sun_prev', axis=1, inplace=True)

################################################################################
############ SET VARIABLES USED FOR PREDICTION  ################################
################################################################################

features_names=['female'
        , 'child_u7'
        , 'elder'
        , 'occ_cat'
        , 'ind_cat'
        , 'sectors_grouped'
        , 'hazardous'
       , 'h_fit'
       , 'supportive_colleagues'
       , 'enough_time'
       , 'age_groups'
       , 'parttime'
       , 'single_hh'
       , 'long_commute'
       , 'sat_prev'
       , 'sun_prev'
       , 'l_hours_prev'
       , 'l_hours_reg_prev'
       , 'nights_prev' 
       , 'nights_reg_prev'
       , 'flexible_schedules'
       , 'long_flex'
       , 'sunday_nights'
       ]


################################################################################
################## 1. GENERATE REFERENCE GROUP #################################
################################################################################
data_cl['reference0_reg'] = np.where((data_cl['flexible_schedules'] == 0)   
                                 & (data_cl['nights_reg_prev'] == 0) 
                                 & (data_cl['l_hours_reg_prev'] == 0) 
                                 & (data_cl['sun_prev'] == 0)
                                 & (data_cl['long_flex'] == 0)
                                 & (data_cl['sunday_nights'] == 0)
                                 , 1,0)

################################################################################
################## 2. SAMPLE SPLIT #############################################
################################################################################
# SPLIT INTO SUBSAMPLES
# data_flexi_split_0 contains obs with absolutely no NWA -- drop obs with reference0_reg  = 0
data_flexi_split_0 = data_cl.drop(data_cl[(data_cl.reference0_reg == 0) ].index) 

data_flexible_schedules = data_cl.drop(data_cl[(data_cl.flexible_schedules == 0) ].index) 
data_nights_reg = data_cl.drop(data_cl[(data_cl.nights_reg_prev == 0) ].index) 
data_l_hours_reg = data_cl.drop(data_cl[(data_cl.l_hours_reg_prev == 0) ].index) 
data_sun = data_cl.drop(data_cl[(data_cl.sun_prev == 0) ].index) 
data_long_flex = data_cl.drop(data_cl[(data_cl.long_flex == 0) ].index) 
data_sun_nights = data_cl.drop(data_cl[(data_cl.sunday_nights == 0) ].index) 

########## EXPORT (if needed)
data_flexi_split_0.to_csv('data_flexi_split_0.csv',sep=';', header=True, index=False)
#data_flexible_schedules.to_csv('data_flexible_schedules.csv',sep=';', header=True, index=False)
#data_nights_reg.to_csv('data_nights_reg.csv',sep=';', header=True, index=False)
#data_l_hours_reg.to_csv('data_l_hours_reg.csv',sep=';', header=True, index=False)
#data_sun.to_csv('data_sun.csv',sep=';', header=True, index=False)
#data_long_flex.to_csv('data_long_flex.csv',sep=';', header=True, index=False)
#data_sun_nights.to_csv('data_sun_nights.csv',sep=';', header=True, index=False)

################ MODEL FOR THE REFERENCE GROUP #################################
# CHOOSE DATA FOR MODEL
data_model=data_flexi_split_0.copy()    

# FINAL SET 
data_model.dropna(axis=0, how='any',inplace=True) 
target_fin = data_model.reset_index()['target']
data_fin=data_model.reset_index()
data_fin.drop('target', axis=1, inplace=True)

# RANDOM FOREST CLASSIFIER with optimal parameters' selection
clf = RandomForestClassifier(n_estimators=500, class_weight='balanced_subsample', bootstrap=True, verbose = 10, min_samples_split=2, min_samples_leaf=1, n_jobs=-1)
clf.fit(data_fin[features_names],target_fin)

################ PREDICTION FOR THE REFERENCE GROUP ############################
# CHOOSE DATA FOR PREDICTION
data_prediction=data_flexi_split_0.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_daneref.csv',sep=';', header=True, index=False)


################ PREDICTION FOR DIFFERENT FORMS OF NWA #########################
######################### FLEXIBLE SCHEDULES  ##################################
# CHOOSE DATA FOR PREDICTION 
data_prediction=data_flexible_schedules.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_daneflex_sched.csv',sep=';', header=True, index=False)

######################### NIGHTS  ##############################################
# CHOOSE DATA FOR PREDICTION 
data_prediction=data_nights_reg.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_danenights_reg.csv',sep=';', header=True, index=False)

######################### LONG HOURS  ##########################################
# CHOOSE DATA FOR PREDICTION 
data_prediction=data_l_hours_reg.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_danel_hours_reg.csv',sep=';', header=True, index=False)

######################### SUNDAYS  ############################################
# CHOOSE DATA FOR PREDICTION 
data_prediction=data_sun.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_daneweekend.csv',sep=';', header=True, index=False)

######################### LONG_FLEX  ############################################
# CHOOSE DATA FOR PREDICTION 
data_prediction=data_long_flex.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_danelong_flex.csv',sep=';', header=True, index=False)

######################### SUNDAY_NIGHTS  ############################################
# CHOOSE DATA FOR PREDICTION 
data_prediction=data_sun_nights.copy()
data_prediction.dropna(axis=0, how='any',inplace=True) 

target_cf = data_prediction.reset_index()['target']
data_cf=data_prediction.reset_index()
data_cf.drop('target', axis=1, inplace=True)

data_cf['prediction']=clf.predict(data_cf[features_names])

# SAVE FILES WITH PREDICTION
data_cf[['idn','prediction']].to_csv('modelref_danesun_nights.csv',sep=';', header=True, index=False)
