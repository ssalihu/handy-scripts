#!/bin/bash
# Given a JIRA id figure out all the files
# that you are looking for that changed

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

JIRA=$1
BRANCH_NAME=$2
declare -A commit_array
i=0
for c in `git log --pretty=format:"%h" --grep="$JIRA"`
do
   component=`git diff-tree --no-commit-id --name-only -r $c |egrep -i ".sql|.pls|.xml" |egrep -v "web-config.xml"`
   
   found=false
   for c in "${commit_array[@]}"
   do
      if [ "$c" == "$component" ];
	  then
         found=true
	  fi
   done
   if [ "$found" == "false" ];
   then
     commit_array[$i]="$component"
	 i=$(($i+1))  
   fi
done

for commit_details in "${commit_array[@]}"
do
   echo $commit_details
   echo ""
done


if [ "${#commit_array[@]}" -gt 0 ];
then
	for c in "${commit_array[@]}" 
	do   
		echo "$BRANCH_NAME:$JIRA: $c" >> $FOUND_IT
	done
else
	printf "\e[91m...Not found ✘\e[0m\n"
    echo "$BRANCH_NAME:$JIRA: NONE" >> $NOT_FOUND_BRANCHES_REPORT
fi

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