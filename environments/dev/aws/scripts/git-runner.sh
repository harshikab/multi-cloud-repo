#!/bin/bash
# Install Docker
dnf update -y
dnf install -y docker
systemctl enable --now docker

# Start the Runner Container
# We mount the docker socket so the runner can build images
docker run -d --restart always --name github-runner \
  -e REPO_URL="${repo_url}" \
  -e RUNNER_TOKEN="${runner_token}" \
  -e RUNNER_NAME="aws-ec2-runner-$(hostname)" \
  -e RUNNER_REPLACEMENT_POLICY="true" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  myoung34/github-runner:latest