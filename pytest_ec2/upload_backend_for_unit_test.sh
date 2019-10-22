#!/bin/bash

# exit when any command fails
set -e

if [[ -z "$1" ]]; then
  echo "Please enter test case branch as parameter"
  exit 1
else
    branch=$1
fi

if [[ -z "$2" ]]; then
  echo "Please enter test ec2 instance IP"
  exit 1
else
    ec2_ip=$2
fi

if [[ -z "$3" ]]; then
  echo "Please enter test backend path"
  exit 1
else
    backend_path=$3
fi

if [[ -z "$4" ]]; then
  echo "Please enter test ec2 pem key path"
  exit 1
else
    ec2_pem_key_path=$4
fi

today=`date +%Y%m%d_%H%M%S`
tar_file=backend-$today.tar.gz

user_name=$(echo "$USER")

#echo "Changing directory."
cd ${backend_path}
sleep 2

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "$current_branch" != "$branch" ]]; then
    echo "Fetching branch details from AWS CodeCommit"
    git fetch
    sleep 2

    echo "Checking out the branch '$1'."
    git checkout ${branch}
    sleep 2

    echo "Taking git pull of branch '$1'."
    git pull origin ${branch}
    sleep 2
fi
echo "Copying all the files and folder from backend to backend-$today"
cp -r ${backend_path}/ /home/${user_name}/Desktop/backend-${today}
sleep 2

#echo "Changing directory"
cd /home/${user_name}/Desktop/backend-${today}/
sleep 2

echo "Removing unnecessary folders."
rm -rf .git
sleep 2

tar_file=backend-${today}.tar.gz

cd ..

echo "Creating tar file '$tar_file' of the files"
tar -zcf ${tar_file} backend-${today}
sleep 2

#echo "Deleting folder"
rm -rf backend-${today}

echo "Moving tar file to location /home/$user_name/Desktop"

ssh-add ${ec2_pem_key_path}

echo "Uploading code to ec2 instance"
ssh-keyscan -H ${ec2_ip} >> ~/.ssh/known_hosts
scp ${tar_file} ubuntu@${ec2_ip}:~
sleep 2

#echo "Deleting tar file"
rm -rf /home/${user_name}/Desktop/backend-${today}


export backend_folder=backend-${today}.tar.gz