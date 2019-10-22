#!/usr/bin/env bash
set -e

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] ; then
    echo "Please specify test case branch, backend path and ec2 pem key path"
    exit 1
fi

#if [[ $EUID == 0 ]]; then
#   echo "Exiting from root"
#   exit
#fi

branch=$1
backend_path=$2
ec2_pem_key_path=$3

echo "###########################################################################"
python pytest_ec2.py start

ec2_ip=$(head -n 1 /tmp/ec2_instance_ip)

echo "###########################################################################"
echo "Uploading branch ${branch} to test case instance ${ec2_ip}"
. upload_backend_for_unit_test.sh ${branch} ${ec2_ip} ${backend_path} ${ec2_pem_key_path}

echo "###########################################################################"
echo "Setting up test backend and test database"
ec2_user=ubuntu
echo "backend folder is ${backend_folder}"
ssh -t ${ec2_user}@${ec2_ip} "sudo /home/${ec2_user}/run_unit_test.sh ${backend_folder}"
ssh -t ${ec2_user}@${ec2_ip} "sudo /home/${ec2_user}/prepare_test_database.sh verifi verifi verifi 127.0.0.1"

echo "###########################################################################"
echo "running pytest"
today=`date +%Y%m%d_%H%M%S`
logfile=test-${today}.txt

curl -X POST -H 'Content-type: application/json' --data '{"text":"['$(echo "$USER")'] Started Pytest execution for branch '${branch}'"}' https://hooks.slack.com/services/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


ssh -t ${ec2_user}@${ec2_ip} "sudo /home/${ec2_user}/run_pytest.sh ${logfile}"
echo "\n\n\nCopy log file into local machine at /tmp"
scp ${ec2_user}@${ec2_ip}:/home/${ec2_user}/${logfile} /tmp/.
echo "###########################################################################"

echo "###########################################################################"
echo "uploading file to slack"
python pytest_slack.py /tmp/$logfile
curl -X POST -H 'Content-type: application/json' --data '{"text":"['$(echo "$USER")'] Pytest summary report for branch - '${branch}'"}' https://hooks.slack.com/services/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


echo "###########################################################################"
# stopping ec2 machine
#python pytest_ec2.py stop