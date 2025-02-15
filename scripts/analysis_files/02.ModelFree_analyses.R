#------------------------------------------------------------------------------#
# Model-free analysis
# Cerated: "Tue Jan 25 14:00:40 2022"
#------------------------------------------------------------------------------#

rm(list=ls())

# load the packages
library(data.table)
library(dplyr)
library(viridis)
library(lme4)
library(car)
library(ggplot2)
library(Rmisc)

# source the scripts
source("scripts/helper_functions/dprime_thres.R")
source("scripts/helper_functions/discCalc.R")
source("scripts/helper_functions/getPredicted.R")

# get wd
cd<-getwd()

# load the data of the two experiments
exp1<-fread("exp1/outputs/group_level/share/group_task-rec.csv")

#------------------Experiment1-------------------------------------------------#
# select only immediate
exp1<-exp1[exp1$session==1,]

# get predicted category
exp1<-getPredicted(exp1, 1)

# rename fillers for old (as they were NA)
exp1$fillers[exp1$OvsN==2] <- 0

# Remove fillers
exp1 <- exp1[exp1$fillers!=1,]

#------------------Experiment2-------------------------------------------------#
exp2<-fread("exp2/outputs/group_level/share/group_task-rec.csv")

# get predicted category
exp2<-getPredicted(exp2, 2)

#The data file contains a lot of information that we will not need now.
exp2 <- subset(x = exp2,
               subset = !is.na(exp2$participant.y),
               select = c("practice", "participant.y", "OvsN",  "id_acc", 
                          "trial_acc", "contingency", "fillers",  "session",
                          "predicted_category" , "predicted_contingency"))

exp2$participant <- exp2$participant.y

exp2$fillers[exp2$OvsN==2] <- 0

# select only the particiopants in the immediate recognition session
exp2<-exp2[exp2$participant<41,]

# check how many trials
trials2<-exp2 %>%
  group_by( participant, OvsN) %>%
  tally()


# now calculate the hit rate by accuracy
#-----------------hitbyAcc------------------------------------------------#
names(exp1)
names(exp2)

# select only old 
exp1<-exp1[exp1$OvsN==1,]
exp2<-exp2[exp2$OvsN==1,]

# create prediction strength
exp1$prediction_condition<-as.factor(exp1$contingency)
exp1$prediction_condition2<- ifelse(exp1$prediction_condition=="0,33", "0.33",
                                    "0.20/0.80")
levels(exp1$prediction_condition)<-c("0.20", "0.33", "0.80")

exp2$prediction_condition<-as.factor(exp2$contingency)
exp2$prediction_condition2<- ifelse(exp2$prediction_condition==0.50, "0.50", 
                                    ifelse(exp2$prediction_condition==0.1 | 
                                             exp2$prediction_condition==0.90, 
                                           "0.10/0.90",
                                           "0.30/0.70"))

levels(exp2$prediction_condition)<-c("0.10", "0.30", "0.50", "0.70", "0.90")

# now predicted contingency
exp2$predicted_contingency<-as.factor(exp2$predicted_contingency)
exp2$predicted_contingency<- ifelse(exp2$predicted_contingency=="0,1", "0.10", 
                                    ifelse(exp2$predicted_contingency=="0,3", "0.30",
                                           ifelse(exp2$predicted_contingency=="0,5", "0.50",
                                                  ifelse(exp2$predicted_contingency=="0,7","0.70",
                                           "0.90"))))

exp2$predicted_contingency<-as.factor(exp2$predicted_contingency)

# we only need encoding accuracy and 
VoI1<-c("participant", "predicted_contingency", "prediction_condition",
        "prediction_condition2", "enc_acc", "id_acc")

exp1<-exp1[, ..VoI1]

names(exp1)[c(5,6)]<-c("prediction_accuracy", "recognition_accuracy")

VoI2<-c("participant", "predicted_contingency","prediction_condition", 
        "prediction_condition2", "trial_acc", "id_acc")

exp2<-exp2[, ..VoI2]

names(exp2)[c(5,6)]<-c("prediction_accuracy", "recognition_accuracy")

# bind them
exp2$participant<-exp2$participant+200

exp1$experiment<-"Experiment1"
exp2$experiment<-"Experiment2"

allData<-rbind(exp1, exp2)

#-----------------Experiment1------------------------------------------------#
# prediction condition
# exclude participants with low performance in phase1
exclPhase1<-c(7 ,16, 19, 20, 23)

exp1<-exp1[!exp1$participant %in% exclPhase1, ]

# rename the levels of prediction accuracy
exp1$prediction_accuracy<-ifelse(exp1$prediction_accuracy==0, "Incorrect",
                                 "Correct")
# turn them into a factor
exp1$prediction_accuracy<-as.factor(exp1$prediction_accuracy)

# make "incorrect" the first level
exp1$prediction_accuracy<-relevel(exp1$prediction_accuracy, 
                                  "Incorrect")

#------------------------------------------------------------------------------#
# as a function of predicted contingency

# Convert the variable into a factor
exp1$predicted_contingency<-as.factor(exp1$predicted_contingency)

data_agg_exp1_pred_cont<-exp1 %>%
  group_by(  prediction_accuracy, participant, predicted_contingency) %>%
  dplyr::summarise(rec_acc = mean(recognition_accuracy, na.rm = T), 
                   experiment = first(experiment))

data_summary_exp1_pred_cont<- summarySEwithin(data_agg_exp1_pred_cont,
                                              measurevar = "rec_acc",
                                              withinvars = c( "prediction_accuracy",
                                                              "predicted_contingency"), 
                                              idvar = "participant")

# plot
gplot_exp1_pred_cont<-ggplot(data_agg_exp1_pred_cont,#
                             aes( x=predicted_contingency, y=rec_acc))+
  geom_bar(aes(predicted_contingency, rec_acc, fill = predicted_contingency),
           position="dodge",stat="summary", fun.y="mean", SE=F)+
  geom_jitter(width = 0.20, alpha = 0.20 )+
  
  geom_errorbar(aes(y = rec_acc, ymin = rec_acc - se, ymax = rec_acc + se),
                color = "black", width = 0.10, data=data_summary_exp1_pred_cont)+
  #facet_wrap(experiment~.)+
  theme_classic()+
  ylab("% Hit")+
  theme(legend.position = "none")+
  theme(
    plot.title = element_text(size = 22),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20),
    axis.text=element_text(size=20)
  )+
  theme(strip.text.x = element_text(size = 18))+
  xlab("Contingency Condition of the Predicted Category")+
  ggtitle("Experiment 1")+
  facet_wrap(.~prediction_accuracy)+
  theme(plot.title = element_text(hjust = 0.5))+
  scale_fill_manual(values =   c("#DDCC77", "#CC6677","#117733"))

gplot_exp1_pred_cont

# save it
ggsave("scripts/figures/pred_contingency_acc_exp1.png", 
       width = 7, height = 7)

# analyse
modexp1_pred_cont_acc<-glmer(recognition_accuracy~prediction_accuracy*predicted_contingency+
                          (prediction_accuracy*predicted_contingency | participant),
                        family = binomial, data = exp1,
                        glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))

summary(modexp1_pred_cont_acc)

Anova(modexp1_pred_cont_acc, type = "II")

library(lsmeans)

lsmeans(modexp1_pred_cont_acc, pairwise~prediction_accuracy*predicted_contingency, 
        adjust = "bonferroni")

# Analyze seperately for correct vs incorrect predictions
modexp1_pred_cont_correct<-glmer(recognition_accuracy~predicted_contingency+
                               (predicted_contingency | participant),
                             family = binomial, 
                             data = exp1[exp1$prediction_accuracy=="Correct",],
                             glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))

summary(modexp1_pred_cont_correct)
lsmeans(modexp1_pred_cont_correct,pairwise~predicted_contingency, 
        adjust = "bonferroni")

modexp1_pred_cont_incorrect<-glmer(recognition_accuracy~predicted_contingency+
                                   (predicted_contingency | participant),
                                 family = binomial, 
                                 data = exp1[exp1$prediction_accuracy=="Incorrect",],
                                 glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))

summary(modexp1_pred_cont_incorrect)
Anova(modexp1_pred_cont_incorrect)


#-------------------Experiment2------------------------------------------------#

# exclude participants with low performance in phase1
exclPhase1exp2<-c(3 ,13, 28, 36, 39)

exp2<-exp2[!exp2$participant %in% exclPhase1exp2, ]

# rename the levels of prediction accuracy
exp2$prediction_accuracy<-ifelse(exp2$prediction_accuracy==0, "Incorrect",
                                 "Correct")
# turn them into a factor
exp2$prediction_accuracy<-as.factor(exp2$prediction_accuracy)

# make "incorrect" the first level
exp2$prediction_accuracy<-relevel(exp2$prediction_accuracy, 
                                  "Incorrect")


# -----------------------------------------------------------------------------#
# as a function of predicted contingency

# first, turn predicted contingency 

data_agg_exp2_pred_cont<-exp2 %>%
  group_by(  prediction_accuracy, participant, predicted_contingency) %>%
  dplyr::summarise(rec_acc = mean(recognition_accuracy, na.rm = T), 
                   experiment = first(experiment))

data_summary_exp2_pred_cont<- 
  summarySEwithin(data_agg_exp2_pred_cont,
                  measurevar = "rec_acc",
                  withinvars = c( "prediction_accuracy",
                                  "predicted_contingency"), 
                  idvar = "participant")

gplot_exp2_pred_cont<-ggplot(data_agg_exp2_pred_cont,
                             aes( x=predicted_contingency, y=rec_acc))+
  geom_bar(aes(predicted_contingency, rec_acc, fill = predicted_contingency),
           position="dodge",stat="summary", fun.y="mean", SE=F)+
  geom_jitter(width = 0.20, alpha = 0.20 )+
  
  geom_errorbar(aes(y = rec_acc, ymin = rec_acc - se, ymax = rec_acc + se),
                color = "black", width = 0.10, data=data_summary_exp2_pred_cont)+
  #facet_wrap(experiment~.)+
  theme_classic()+
  ylab("% Hit")+
  theme(legend.position = "none")+
  theme(
    plot.title = element_text(size = 22),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20),
    axis.text=element_text(size=20)
  )+
  theme(strip.text.x = element_text(size = 18))+
  xlab("Contingency Condition of the Predicted Category")+
  ggtitle("Experiment 2")+
  facet_wrap(.~prediction_accuracy)+
  theme(plot.title = element_text(hjust = 0.5))+
  scale_fill_manual(values =   c("#DDCC77","#88CCEE", "#AA4499","#44AA99","#332288"))

gplot_exp2_pred_cont

gi# save it
ggsave("scripts/figures/pred_contingency_acc_exp2.png", 
       width = 7, height = 7)

# analyse
modexp2_pred_cont_acc<-glmer(recognition_accuracy~prediction_accuracy*predicted_contingency+
                          (prediction_accuracy*predicted_contingency  | participant),
                        family = binomial, data = exp2, 
                        glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))

summary(modexp2_pred_cont_acc)

Anova(modexp2_pred_cont_acc, type = "III")

# analyse only predicted contingency
modexp2_pred_cont<-glmer(recognition_accuracy~predicted_contingency+
                               (predicted_contingency  | participant),
                             family = binomial, data = exp2, 
                             glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))

summary(modexp2_pred_cont)
lsmeans(modexp2_pred_cont, pairwise~predicted_contingency, adjust = "Bonferroni")

modexp2_pred_acc<-glmer(recognition_accuracy~prediction_accuracy+
                               (prediction_accuracy  | participant),
                             family = binomial, data = exp2, 
                             glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))
summary(modexp2_pred_acc)
