#!/bin/bash
#Script will delete all images in all repositories of your docker hub account which are older than 'X' days

# pass username,password and no of 'X' days value from terminal as below line.
# ./docker-images-remove-script.sh <username> <password> <30>
UNAME=$1
UPASS=$2
X=$3
#UPASS=$4
MODE=$5

if [ $UPASS == "NOPASS" ];then
     echo "Pass var is not use, lets generate a new one"
     # get token to be able to talk to Docker Hub
     UPASS=$4
     TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
fi

#echo $TOKEN
# get list of repos for that user account
echo "List of Repositories in '${UNAME}' Docker Hub account."
sleep 5
REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" "https://hub.docker.com/v2/repositories/${UNAME}/?page_size=10000" | jq -r '.results|.[]|.name')
#echo "$REPO_LIST"
count=1
for rep in ${REPO_LIST}
do
     echo S.No: $count RepoName:  $rep
     count=`expr $count + 1`
done
echo
sleep 5

echo
echo "Identifying and deleting images which are older than $X days in '${UNAME}' docker hub account."
sleep 5

#NOTE!!! For deleting specific repositories images please include only those repositories in for-loop, like below for-loop which has repos mysql and mymongo 
#for i in  mysql mymongo

for rep in ${REPO_LIST}
do
    # get total no. of images & their count for a repo
    Images=$(curl -s -H "Authorization: JWT ${TOKEN}" "https://hub.docker.com/v2/repositories/$UNAME/$rep/tags/")
    ImageCount=$(echo $Images | jq -r '.count')    
    echo "Total no of Images in '$UNAME/$rep' repository are: $ImageCount"
    pages=`expr $ImageCount / 100 + 1`
    echo "No pages to iterate are: $pages"    
    sleep 5
    for (( p=1; p<=$pages; p++ ))
    do         
        echo "Looping Through '$rep' repository in '${UNAME}' account."
        IMAGES=$(curl -s -H "Authorization: JWT ${TOKEN}" "https://hub.docker.com/v2/repositories/${UNAME}/${rep}/tags/?page_size=100&page=$p") 
        IMAGE_TAGS=$(echo $IMAGES | jq -r '.results|.[]|.name')
        count1=1

             # build a list of images from tags
             for tag in ${IMAGE_TAGS}
             do
                  
                  echo Iteration no. is: $p
                  echo "S.No: $count1. RepoName: '$rep' ImageTag: $tag"
                  count1=`expr $count1 + 1`
                  sleep 5
                  # Get last_updated_time
                  updated_time=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${rep}/tags/${tag}/?page_size=100 | jq -r '.last_updated')
                  echo "Image build date and time is : $updated_time"
                  datetime=$updated_time
                  timeago=''$X' days ago'
                  #echo $timeago

                  dtSec=$(date --date "$datetime" +"%Y%m%d")
                  taSec=$(date --date "$timeago"  +"%Y%m%d")
                   
                  dt_Sec=$(date --date "$datetime" +"%Y-%m-%d")
                  ta_Sec=$(date --date "$timeago"  +"%Y-%m-%d")
                  

                  echo "INFO: Date on which this image was build: $dt_Sec" 
                  echo "INFO: $X days earlier date from today is: $ta_Sec" 
                  sleep 5
                  if [ $dtSec -lt $taSec ] 
                  then
                        echo "This image '${UNAME}/${rep}:${tag}'  is older than $X days, deleting this  image."
                  #### Note! TO delete an image please uncomment below line.
                  if [ $MODE != "TEST" ];then
                    echo "Lets delete the next tag!"
                    curl -s  -X DELETE  -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${rep}/tags/${tag}/
                  fi
                  else
                        echo "This image '${UNAME}/${rep}:${tag}' is within $X days time range, keeping this image."
                  fi
                  echo
             done      
    done
echo
done

echo "Script execution ends here."
