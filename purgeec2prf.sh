#!/bin/bash
# Purges instance profiles in ACG lab
# Use with caution!!!

# Environment
export AWS_DEFAULT_OUTPUT="text"
export AWS_PROFILE=acglab

profiles=($(aws iam list-instance-profiles --query 'InstanceProfiles[*].[InstanceProfileName]'))  

for profile in "${profiles[@]}"
do
   aws iam delete-instance-profile --instance-profile-name $profile
   echo $profile deleted.
done