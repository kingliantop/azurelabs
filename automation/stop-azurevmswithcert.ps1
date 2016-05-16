	<#
.NOTES
 
   Author: Steven Lian
   Updated: April 6th, 2016
#>

workflow Stop-AzureVMs
{   
    param (
    #    [Parameter(Mandatory=$false)] 
    #   [String]  $AzureCredentialAssetName = 'AzureCredential',
        
    #   [Parameter(Mandatory=$false)]
    #   [String] $AzureSubscriptionIdAssetName = 'AzureSubscriptionId',

    #    [Parameter(Mandatory=$false)] 
    #    [String] $ServiceName
    )
	# automationsubid b18f6b8a-XXXX
	# automationuser@XXXXX.cn
	# vmnamelist 
    # Returns strings with status messages
    [OutputType([String])]


    $AzureSubscriptionIdAssetName = 'automationsubid'
    $subscriptionNameAssetname = 'azuresubscriptionname'
    # $ServiceName = 'linuxcent71'
	# Connect to Azure and select the subscription to work against
	#$Cred = Get-AutomationPSCredential -Name $AzureCredentialAssetName
    $SubId = Get-AutomationVariable -Name $AzureSubscriptionIdAssetName
    $subscriptionName = Get-AutomationVariable -Name $subscriptionNameAssetname 
    
    $vmconfiglist = Get-AutomationVariable -Name 'vmnamelist'
    
    $vmlist = $vmconfiglist -split ","

    $certificateName = Get-AutomationVariable -Name "mycertificateName" 
    $certificate = Get-AutomationCertificate -Name $certificateName  
    
    Set-AzureSubscription -SubscriptionName $subscriptionName -SubscriptionId $SubId -Certificate $certificate -Environment AzureChinaCloud -ErrorAction Stop
     
    $null = Select-AzureSubscription -SubscriptionId $SubId -ErrorAction Stop

	
	# If there is a specific cloud service, then get all VMs in the service,
    # otherwise get all VMs in the subscription.
    #if ($ServiceName) 
	#{ 
	#	$VMs = Get-AzureVM -ServiceName $ServiceName
	#}
    #else 
	#{ 
	#	$VMs = Get-AzureVM
	#}
	
	$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
    $Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)

    $day = $Start.DayOfWeek 
    if ($day -eq 'Saturday' -or $day -eq 'Sunday')
    { 
		 Write-Output ("StopVM exits due to weekends!!")
         exit 
    }
	
    # Stop each of the started VMs
    foreach ($vmname in $vmlist)
    {
		#$VM = Get-AzureVM -ServiceName $ServiceName -Name $vmname
		$VM = Get-AzureVM| Where-Object -FilterScript { $_.InstanceName -eq $vmname}
        if ($VM.PowerState -eq "Stopped")
		{
			# The VM is already stopped, so send notice
			Write-Output ($VM.InstanceName + " is already stopped")
		}
		else
		{
			# The VM needs to be stopped
			$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
			$Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
	
            Write-Output($Start.tostring()+" Start stopping VM:" + $VM.Name)
			
        	$StopRtn = Stop-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -Force -ErrorAction Continue

	        if ($StopRtn.OperationStatus -ne 'Succeeded')
	        {
				# The VM failed to stop, so send notice
                Write-Output ($VM.InstanceName + " failed to stop!!")
	        }
			else
			{
				# The VM stopped, so send notice
				$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
				$Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
	
				Write-Output($Start.tostring()+" " + $VM.InstanceName + " has been stopped!!")
			}
		}
    }
}