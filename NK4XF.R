#library reference for reading and writing files
library(readr)
#library reference for data handling
library(dplyr)
library(stringr)

options(stringsAsFactors=FALSE)

titanic.data.train <- read_csv('all/train.csv')

titanic.data.train$Survived <- factor(titanic.data.train$Survived)
titanic.data.train$Pclass <- factor(titanic.data.train$Pclass)
titanic.data.train$Sex <- factor(titanic.data.train$Sex)
titanic.data.train$Embarked <- factor(titanic.data.train$Embarked)

titanic.data.train.male.children <- titanic.data.train %>% filter(titanic.data.train$Name %>%  str_detect('Master.') == TRUE)
male.children.median.age <- titanic.data.train.male.children[titanic.data.train.male.children$Age %>% is.na() == FALSE,]$Age %>% median()
titanic.data.train[titanic.data.train$Age %>% is.na() == TRUE & titanic.data.train$Name %in% titanic.data.train.male.children$Name,]$Age <- male.children.median.age

titanic.data.train.male.adults <- titanic.data.train[titanic.data.train$Sex == 'male' & !(titanic.data.train$Name %in% titanic.data.train.male.children$Name),]
male.adults.median.age <- median(titanic.data.train.male.adults[titanic.data.train.male.adults$Age %>% is.na() == FALSE,]$Age)
titanic.data.train[titanic.data.train$Age %>% is.na() == TRUE & titanic.data.train$Name %in% titanic.data.train.male.adults$Name,]$Age <- male.adults.median.age

titanic.data.train.female <- titanic.data.train[titanic.data.train$Sex == 'female' & titanic.data.train$Age %>% is.na() == FALSE,]
female.adults.median.age <- titanic.data.train.female$Age %>% median()
titanic.data.train[titanic.data.train$Sex == 'female' & titanic.data.train$Age %>% is.na() == TRUE,]$Age <- female.adults.median.age

dropped.features <- c('Name','Ticket','Cabin','Fare','SibSp','Embarked','Parch','PClass', 'PassengerId')
titanic.data.train <- titanic.data.train[,!(names(titanic.data.train) %in% dropped.features)]

survived.lg <- glm(Survived ~ ., data=titanic.data.train, family="binomial")
summary(survived.lg)

test <- read_csv('all/test.csv')
test$Pclass <- factor(test$Pclass)
test$Sex <- factor(test$Sex)
test$Embarked <- factor(test$Embarked)


test$survived <- NA

test[test$Sex == 'female' & test$Age %>% is.na() == TRUE,]$Age <- female.adults.median.age
test[test$Sex == 'male' & test$Name %>% str_detect('Master.') == TRUE & test$Age %>% is.na() == TRUE,]$Age <- male.adults.median.age
test[test$Sex == 'male' & test$Name %>% str_detect('Master.') == FALSE & test$Age %>% is.na() == TRUE,]$Age <- male.children.median.age


test$survived <- predict(survived.lg, newdata=test, type="response")
test$survived[test$survived>=0.5] <- 1
test$survived[test$survived<0.5] <- 0

test <- test[,names(test) %in% c('PassengerId', 'survived')]
write.table(test, file = "test_survived_submission.csv", row.names=F, col.names=c('PassengerId', 'survived'), sep=",")



