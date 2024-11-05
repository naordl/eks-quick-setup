#!/bin/bash

# Define AWS Region
AWS_REGION="eu-west-1"

# Fetch AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Find the EKS stack name by partial match on stack name
# If you gave a different name to the stack during deployment, you will have to edit this line
EKS_STACKNAME=$(aws cloudformation describe-stacks --region ${AWS_REGION} --query 'Stacks[?contains(StackName, `eks-quick-setup`)].StackName' --output text)

# Find the CodePipeline stack name by partial match on stack name
# If you gave a different name to the stack during deployment, you will have to edit this line
PIPELINE_STACKNAME=$(aws cloudformation describe-stacks --region ${AWS_REGION} --query 'Stacks[?contains(StackName, `eks-quick-setup-pipeline`)].StackName' --output text)

# Exit with an error if the stacks can't be retrieved
# This means that either the stack names or the region where the stacks are deployed differs
if [[ -z "$EKS_STACKNAME" || -z "$PIPELINE_STACKNAME" ]]; then
  echo "Error: Unable to retrieve stack names. Please check stack naming conventions or region."
  exit 1
fi

# Update kubeconfig
aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_STACKNAME} --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${PIPELINE_STACKNAME}-CloudformationRole

# Add storageclass (turns out this is necessary)
kubectl apply -f gp2-immediate.yaml

# Add Helm repos
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install and upgrade Helm charts
helm upgrade -i aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver -n kube-system
helm upgrade -i prometheus prometheus-community/prometheus -f prometheus/values.yaml
helm upgrade -i grafana grafana/grafana -f grafana/values.yaml

# Configure autoscaler
kubectl apply -f autoscaler/autoscaler.yaml
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
