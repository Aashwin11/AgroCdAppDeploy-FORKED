#!/bin/bash


set -e # Exit immediately if a command exits with a non-zero status.

# These variables are expected to be set in the CodeBuild environment
if [ -z "$ECR_REPO_URI" ] || [ -z "$IMAGE_TAG" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: Required environment variables are not set."
  exit 1
fi

DEPLOYMENT_FILE="k8s-kustomize/base/deployment.yaml"
GIT_REPO_URL="https://oauth2:${GITHUB_TOKEN}@github.com/YOUR_USERNAME/AgroCdAppDeploy-FORKED.git"

echo "Updating image in ${DEPLOYMENT_FILE} to ${ECR_REPO_URI}:${IMAGE_TAG}"

# Use sed to replace the image line
sed -i "s|image:.*|image: ${ECR_REPO_URI}:${IMAGE_TAG}|g" $DEPLOYMENT_FILE

echo "Configuring Git..."
git config --global user.email "codebuild@aws.com"
git config --global user.name "AWS CodeBuild CI"

echo "Committing and pushing changes..."
git add $DEPLOYMENT_FILE
# Check if there are changes to commit to avoid errors
if git diff-index --quiet HEAD; then
  echo "No changes to commit."
else
  git commit -m "chore(release): Update image to ${IMAGE_TAG} [skip ci]"
  git push $GIT_REPO_URL HEAD:main
fi

echo "Manifest update complete."
