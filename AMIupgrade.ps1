# Script for upgrading AMI with new image in predefined Auto Scalling Group
# AWS AccessKey, AWS SecretKey and AWS Default Region must be set before running script


# Parameters for running script are described below:
# $ASGid for target Auto Scalling Group
# $NewAMIid for new ImageID
param([string]$ASGid = "ASGid", [string]$NewAMIid = "NewAMIid")


# Preparing variables for creating new LaunchConfoguration
$LCName = (Get-ASAutoScalingGroup -AutoScalingGroupName $ASGid).LaunchConfigurationName
$LCInstanceType = (Get-ASLaunchConfiguration -LaunchConfigurationName $LCName).InstanceType
$LCSecurityGroup = (Get-ASLaunchConfiguration -LaunchConfigurationName $LCName).SecurityGroups
$LCIAMInstanceProfile = (Get-ASLaunchConfiguration -LaunchConfigurationName $LCName).IAMInstanceProfile
$ExtForLCName = (get-date).ToString("yyyyMMddThhmmss")
# Creating new LC based on predefined ImageID
echo "Creating new Launch configuration..."
New-ASLaunchConfiguration -LaunchConfigurationName $LCName$ExtForLCName -InstanceType $LCInstanceType -ImageId $NewAMIid -SecurityGroup $LCSecurityGroup -IamInstanceProfile $LCIAMInstanceProfile
echo "Done!"

# Calculating amount of instances for replacement
$Amount = @((Get-ASAutoScalingGroup -AutoScalingGroupName $ASGid).Instances.InstanceId).Length
echo "In current group we have to replace $Amount instances."
# Updating Auto Scalling Group settings with new LC
Update-ASAutoScalingGroup -AutoScalingGroupName $ASGid -LaunchConfigurationName $LCName$ExtForLCName -TerminationPolicy "OldestInstance"

# Replacement initiating via manipulating with Desire capacity
echo "Starting AMI replacement..."
for ($i=1; $i -le $Amount; $i++)
{
echo "Increasing ASG capacity..."
Update-ASAutoScalingGroup -AutoScalingGroupName $ASGid -DesiredCapacity ($Amount + 1)
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
echo "Decreasing ASG capacity..."
Update-ASAutoScalingGroup -AutoScalingGroupName $ASGid -DesiredCapacity $Amount
Start-Sleep -Seconds 120
echo ""
}
echo "Auto Scaling group $ASGid was successfully upgraded with AMI $NewAMIid !"
