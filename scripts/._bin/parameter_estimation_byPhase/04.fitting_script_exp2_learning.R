#------------------------------------------------------------------------------#
# script that fit the winning models to each dataset and print the outputs
#
# this version is for the flat setup. 
#------------------------------------------------------------------------------#

# set current directory to the parent folder
setwd(dirname(getwd()))

rm(list=ls())

#Slibrary(here)
cd<-getwd()
# source the files with the function
source(("computational_model/helper_functions/BICcompute.R"))
source(("computational_model/helper_functions/searchGlobal.R"))
source(("computational_model/helper_functions/softmax.R"))
source(("computational_model/helper_functions/getFiles.R"))
source(("computational_model/helper_functions/modelFunPhase2.R"))
source(("computational_model/helper_functions/getResp.R"))
source(("computational_model/helper_functions/getProbStrongWeak.R"))
source(("computational_model/helper_functions/getx.R"))
source(("computational_model/helper_functions/getU.R"))
source(("computational_model/helper_functions/fixnames.R"))
source(("computational_model/helper_functions/getobs.R"))
source(("computational_model/helper_functions/getfeedb.R"))
source(("computational_model/helper_functions/var_murphy.R"))



setwd("computational_model/likelihood_functions")
likfun<-list.files()
for (f in 1:length(likfun)){
  source(likfun[f])
}
# fitting functions
setwd(paste(cd, "/computational_model/fitting_functions",sep=""))
fitfun<-list.files()
for (f in 1:length(fitfun)){
  source(fitfun[f])
}

setwd(cd)

# very important, the setup
exp <-"exp2"

# phase1
phase1Files<-read.csv2("exp2/outputs/group_level/share/group_task-learning.csv",sep=";",
                       header=T,stringsAsFactors=FALSE)
  
# # phase 2
# phase2Files<- read.csv2("exp2/outputs/group_level/share/group_task-rec.csv",sep=";",
#                         header=T,stringsAsFactors=FALSE)

# retrieve the winning models
mod<-"fLR_Instr"


  # load likelihood function
  likelihoodfunction = get(paste("lik_", mod, sep=""))
  
  # load fitting function
  fittingfunction = get(paste("fit_", mod, sep=""))
  
  # getparameters
  filename<-paste( "exp2/outputs/group_level/computational_model",
                  "/ParameterEstimation.exp2_learn.betalimit=10.initialQ=0.5.", mod, ".csv", sep="")
  
  # read the file with the parameters
  param<-read.csv(filename)
  
  # create an empty variable that will be the dataset with all participants' data
  dataAll1<-vector()

  # what subjects?
  participants<-unique(phase1Files$participant)
  
  participants<-1:40
  
  # for each subject
  for (j in 1:length(participants)){
    tryCatch({
    # currect participant
    SubNum<-participants[j]
    
    print(paste("working on participant", SubNum))
    
    # subset file
    # phase 1
    currfile1<-phase1Files[phase1Files$participant==SubNum,]
    #currfile<-phase2Files[phase2Files$participant.x==SubNum,]
    
    #--------------------------------------------------------------------------#
    # change names
    # change name of the response variable
    currfile1$response<- currfile1$key_resp_trial.keys
    #currfile$response<- currfile$key_resp_trial.keys
    
    # object category
    currfile1$object_cat<-currfile1$obj_cat_num
    #currfile$object_cat<-currfile$obj_cat_num
    
    # change name to scene categ
    currfile1$scene_cat<-currfile1$scn_cat
    #currfile$scene_cat<-currfile$scn_cat
    
    # delete NAs - the nas are not "no response"/ the no-response
    # in this file are marked by "", an empty character. 
    # we are assigning "NA" to these empty characters later
    currfile1<-currfile1[!is.na(currfile1$response),]
    #currfile<-currfile[!is.na(currfile$response),]
    
    # convert trial response
    conv_resp<-function(file){
    for (n in 1: nrow(file)){
      if (file$response[n] == "left"){
        file$response[n] <- (1)
      } else if (file$response[n] == "right"){
        file$response[n] <- (2)
      } else if (file$response[n] == ""){
        file$response[n] <-(0)
      }
    }
      file$response<-as.numeric(file$response)
    return(file)
    }
    
    #currfile<-conv_resp(currfile)
    currfile1<-conv_resp(currfile1)
      
   # currfile$acc<-currfile$trial_acc
    currfile1$acc<-currfile1$trial_acc
    
    #---------------------------------------------------------------------------#
    # get parameters
    parameters<-param[param$PartNum==SubNum,]
    
    #--------------------------------------------------------------------------#
    #---------------------------------extract parameters ----------------------#
    #--------------------------------------------------------------------------#
    alpha<-parameters$alpha
    beta<-parameters$beta
    alpha_c<-parameters$alpha_c
    omega<-parameters$beta_c
    initialQ <- matrix(0.5, ncol = 2, nrow = 6)
    initialQ2 <- matrix(0.5, ncol = 2, nrow = 6)
    setup<-exp
    #-------------------------------------------------------------------------#
    
    
    #--------------------------------------------------------------------------#
    #---------------------------------extract Qs ------------------------------#
    #--------------------------------------------------------------------------#
    # we need to extract the Qs from phase1 as starting Qs for phase2
    
    # first, fit the data from phase1
    data1<-likelihoodfunction(Data=currfile1, alpha=alpha, beta=beta, 
                                print = 2 , initialQ=initialQ)    


    # create subjnum variable
    data1$SubNum<-SubNum
    
    # bind them with the whole dataset
    dataAll1<-rbind(dataAll1, data1)
    
    # # now get the initial Qs for phase2
    # initialQ<-getQsPhase1(data1,2)
    
    # # fit to data
    #   fitdata<-likelihoodfunction(Data = currfile, alpha = alpha, beta = beta,
    #                               print =2, initialQ = initialQ)
    # 
    # # create subjnum variable
    # fitdata$SubNum<-SubNum
    # 
    # # bind them with the whole dataset
    # dataAll<-rbind(dataAll, fitdata)
    
    }, error = function(e) { print(paste("problem with number", j))})
    
  }
  
  
  # save the data
  dataAll1$surprise<-unlist(dataAll1$surprise)
  
  write.csv(dataAll1, paste("computational_model/output_files/", "fittedData_learning.", exp, ".Phase1.",mod, 
                           ".csv", sep=""), row.names = F)


