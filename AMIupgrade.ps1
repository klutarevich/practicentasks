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
echo "Creating new Launch configuration..."
New-ASLaunchConfiguration -LaunchConfigurationName $LCName$ExtForLCName -InstanceType $LCInstanceType -ImageId $NewAMIid -SecurityGroup $LCSecurityGroup -IamInstanceProfile $LCIAMInstanceProfile
echo "Done!"

# Preparing list of old instances
$Targets = (Get-ASAutoScalingGroup -AutoScalingGroupName $ASGid).Instances.InstanceId
# Updating Auto Scalling Group settings with new LC
Update-ASAutoScalingGroup -AutoScalingGroupName $ASGid -LaunchConfigurationName $LCName$ExtForLCName

echo "Starting AMI replacement..."
Foreach ($Instance in $Targets)
{
  echo "Detaching instance with ID $Instance"
  echo ""
  Dismount-ASInstance -InstanceId $Instance -AutoScalingGroupName $ASGid -ShouldDecrementDesiredCapacity $false -Force
  echo "Done!"
  echo ""
  # Check for Health and LifecycleState of instances in Auto Scalling group
  DO
  {
    Start-Sleep -Seconds 120
    $Health = (Get-ASAutoScalingGroup -AutoScalingGroupName $ASGid).Instances.HealthStatus | Get-Unique
    $LifecycleState = (Get-ASAutoScalingGroup -AutoScalingGroupName $ASGid).Instances.LifecycleState.Value | Get-Unique
    if ($Health -eq "Healthy" -and $LifecycleState -eq "InService") {
    echo "All instances are Healthy and InService at this momemt..."
    echo ""
    }
  } While (-not ($Health -eq "Healthy" -or $LifecycleState -eq "InService"))
  # Old instances cleanup when Autoscalling group was upgraded with new AMI
  Remove-EC2Instance -InstanceId $Instance -Force
}
echo ""
echo "Auto Scalling group $ASGid was successfully upgraded with AMI $NewAMIid !"
