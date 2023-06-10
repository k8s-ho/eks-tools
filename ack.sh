#!/bin/bash

usage()
{
  echo "Insufficient number of arguments. Please provide at least 2 arguments."
  echo "Thank you for the information. The policy applied to IRSA (IAM Roles for Service Accounts) is recommended to use the appropriate ARN format"
  echo -e "< Usage > ./ack.sh [namespace] [ACK Resource]\n"
  exit 100
}

if [ $# -eq 2 ]; then
  RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/$2-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4 | cut -c 2-)
  AWS_REGION=ap-northeast-2
  RCMD_POLICY=$(curl https://raw.githubusercontent.com/aws-controllers-k8s/$2-controller/main/config/iam/recommended-policy-arn | cut -d "/" -f2)
  CLUSTER_NAME=$(aws eks list-clusters --query "clusters[]" --output text)

  echo -e "[+] Create Namespace\n"
  kubectl create namespace $1

  echo "[+] Download ACK $2 Helm Chart & Checking Version\n"
  helm pull oci://public.ecr.aws/aws-controllers-k8s/$2-chart --version=$RELEASE_VERSION
  tar xzvf $2-chart-$RELEASE_VERSION.tgz


  echo -e "[+] Install ACK helm chart\n"
  helm install -n $1 ack-$2-controller --set aws.region="$AWS_REGION" ./$2-chart


  echo -e "[+] Create IRSA\n"
  eksctl create iamserviceaccount \
    --name ack-$2-controller \
    --namespace $1 \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn $(aws iam list-policies --query "Policies[?PolicyName=='$RCMD_POLICY'].Arn" --output text) \
    --override-existing-serviceaccounts --approve

  echo -e "[#] Done! Now, you can create AWS '$2' resources using ACK."
else
  usage
fi
