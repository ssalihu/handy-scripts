#!/bin/bash

FILTERS="egrep -v .jsp|.java"
NOT_FOUND_BRANCHES_REPORT="`pwd`/not-found.txt"
FOUND_IT="`pwd`/found.txt"

if [ -f $NOT_FOUND_BRANCHES_REPORT ];
then
   rm $NOT_FOUND_BRANCHES_REPORT
fi

if [ -f $FOUND_IT ];
then
   rm $FOUND_IT
fi


if [  "$#" -lt 2 ];
then
    echo "Usage $0 <input file with jira ids> <main branch> optional-git-repo-path"
    exit 1
fi

INPUT=$1

if [ ! -f $INPUT ];
then
   echo "File not found: $INPUT"
   exit 2
fi

BRANCH_NAME=$2
GIT_REPO=$3

OLDIFS=$IFS
IFS=,
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

clear
echo ""
printf "All input validations passed...\e[92m✔\e[0m" 
echo ""
printf "\e[1m\e[93mProcessing $INPUT file ..."
i=0
while read -r line
do
    readLine=$line
    #If the line starts with ST then echo the line
	array[$i]=`echo -n $readLine`
	i=$(($i+1))
done < "$INPUT"

printf "processed  $i entries  \e[92m[DONE] \e[0m"
echo ""
i=0

if [ ! -d $GIT_REPO ] && [ `git -C $GIT_REPO rev-parse` ];
then
   echo "Defaulting to current folder ..."
   GIT_REPO=.
else
   cd $GIT_REPO
fi
echo -e " \e[104m"
echo "Synching with GIT now..."
git fetch
git checkout $BRANCH_NAME
git merge origin/$BRANCH_NAME
echo -e " \e[0m"
has_branch=`git branch -a |grep $BRANCH_NAME`

if [ "$has_branch" == "" ];
then
   echo "Ouch, Input main branch NOT FOIND: $BRANCH_NAME"
   exit 3
fi
echo ""
echo -e " \e[104m"
echo "Detecting commit ids for the Jiras on main branch $BRANCH_NAME"
echo -e " \e[0m"
i=0
for jira in "${array[@]}"
do
  has_branch=`git show-ref |grep origin |grep $jira`
  if [ "$has_branch" == "" ];
  then
      printf "$jira                                          [BRANCH NOT FOUND] \e[91m✘\e[0m\n"
     echo "$BRANCH_NAME:$jira BRANCH NOT FOUND origin/$jira" >> $NOT_FOUND_BRANCHES_REPORT
  else
    actual_branch=`git show-ref |grep remote |grep $jira |cut -f4 -d'/'`
    commit_id=`git rev-parse origin/$actual_branch`
    printf "$jira $commit_id [BRANCH FOUND] \e[92m✔\e[0m\n"
    commit_array[$i]="$jira:$commit_id"
    i=$(($i+1))
  fi

done
echo ""

echo -e " \e[104m"
echo -e  "\e[1mNow detecting NON JAVA components [SQL,PLS,XML]."
echo -e " \e[0m"

i=0
for commit_details in "${commit_array[@]}"
do
  commit=`echo $commit_details |cut -f2 -d':' `
  jira_id=`echo $commit_details| cut -f1 -d':'`
  printf "Probing $jira_id[$commit]"
  component=`git diff-tree --no-commit-id --name-only -r $commit |egrep -i  ".sql|.pls|.xml"`
  if [ "$component" != "" ];
  then
     printf "\e[92m...Found ✔\e[0m\n"
     echo "$BRANCH_NAME:$jira_id[$commit]: $component" >> $FOUND_IT
  else
     printf "\e[91m...Not found ✘\e[0m\n"
     echo "$BRANCH_NAME:$jira_id: NONE" >> $NOT_FOUND_BRANCHES_REPORT
  fi
  i=$(($i+1))
done

echo ""
echo -e " \e[104m"

if [ -f $NOT_FOUND_BRANCHES_REPORT ];
then
   echo "Error report: $NOT_FOUND_BRANCHES_REPORT"
fi

if [ -f $FOUND_IT ];
then
   echo "Results report: $FOUND_IT"
fi
echo -e " \e[0m"
echo "Bye!"
echo ""
