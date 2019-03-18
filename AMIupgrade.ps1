# Script for upgrading AMI with new image in predefined Auto Scalling Group
# AWS AccessKey, AWS SecretKey and AWS Default Region must be set before running script


# Parameters for running script are described below:
# $ASGid for target Auto Scalling Group
# $NewAMIid for new ImageID
param([string]$ASGid = "ASGid", [string]$NewAMIid = "NewAMIid")


# Preparing variables for creating new LaunchConfoguration
$LCName = (Get-ASLaunchConfiguration -LaunchConfigurationName powertest).LaunchConfigurationName
$LCInstanceType = (Get-ASLaunchConfiguration -LaunchConfigurationName powertest).InstanceType
$LCSecurityGroup = (Get-ASLaunchConfiguration -LaunchConfigurationName powertest).SecurityGroups
$LCIAMInstanceProfile = (Get-ASLaunchConfiguration -LaunchConfigurationName powertest).IAMInstanceProfile
$ExtForLCName = (get-date).ToString("yyyyMMddThhmmss")
# Creating new LC based on predefined ImageID
New-ASLaunchConfiguration -LaunchConfigurationName $LCName$ExtForLCName -InstanceType $LCInstanceType -ImageId $NewAMIid -SecurityGroup $LCSecurityGroup -IamInstanceProfile $LCIAMInstanceProfile


# Updating Auto Scalling Group settings with new LC
Update-ASAutoScalingGroup -AutoScalingGroupName $ASGid -LaunchConfigurationName $LCName$ExtForLCName
# Preparing list of old instances
$Targets = (Get-ASAutoScalingGroup -AutoScalingGroupName $ASGid).Instances.InstanceId
# Replacing old images with new ones regarding to new LC. 
# Sleep time was set approximately, for waiting new instance is up and runnig
Foreach ($i in $Targets)
{
  Remove-EC2Instance -InstanceId $i -Force
  Start-Sleep -Seconds 300
}
