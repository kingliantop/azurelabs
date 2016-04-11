<#
.NOTES
   AUTHOR: System Center Automation Team 
   LASTEDIT: September 4, 2015
   
   Author: Steven Lian
   Updated: April 6th, 2016
#>

workflow Start-AzureVMs
{   
    param (
#        [Parameter(Mandatory=$false)] 
#        [String]  $AzureCredentialAssetName = 'AzureCredential',
        
#        [Parameter(Mandatory=$false)]
#        [String] $AzureSubscriptionIdAssetName = 'AzureSubscriptionId',

#        [Parameter(Mandatory=$false)] 
#        [String] $ServiceName
    )

    # Returns strings with status messages
    [OutputType([String])]

	# Connect to Azure and select the subscription to work against
	$AzureCredentialAssetName = 'automationuser@XXX.cn'
    $AzureSubscriptionIdAssetName = 'automationsubid'
    # $ServiceName = 'linuxcent71'
	# Connect to Azure and select the subscription to work against
	$Cred = Get-AutomationPSCredential -Name $AzureCredentialAssetName
    $SubId = Get-AutomationVariable -Name $AzureSubscriptionIdAssetName
    
    $vmconfiglist = Get-AutomationVariable -Name 'vmnamelist'   
    $vmlist = $vmconfiglist -split ","

	$null = Add-AzureAccount -Credential $Cred -Environment AzureChinaCloud -ErrorAction Stop	
    $null = Select-AzureSubscription -SubscriptionId $SubId -ErrorAction Stop
	
	# If there is a specific cloud service, then get all VMs in the service,
    # otherwise get all VMs in the subscription.
#    if ($ServiceName) 
#	{ 
#		$VMs = Get-AzureVM -ServiceName $ServiceName
#	}
#    else 
#	{ 
#		$VMs = Get-AzureVM
#	}

	$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
    $Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)

    $day = $Start.DayOfWeek 
    if ($day -eq 'Saturday' -or $day -eq 'Sunday')
    { 
		 Write-Output ("StartVM exits due to weekends!!")
         exit 
    }
	
    # Start each of the stopped VMs
  foreach ($vmname in $vmlist)
    {
		#$VM = Get-AzureVM -ServiceName $ServiceName -Name $vmname
		$VM = Get-AzureVM| Where-Object -FilterScript { $_.InstanceName -eq $vmname}

		if ($VM.PowerState -eq "Started")
		{
			# The VM is already started, so send notice
			Write-Output ($VM.InstanceName + " is already running")
		}
		else
		{
			# The VM needs to be started
			$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
			$Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
	
            Write-Output($Start.tostring()+" Start VM:" + $VM.Name)
			
        	$StartRtn = Start-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -ErrorAction Continue

	        if ($StartRtn.OperationStatus -ne 'Succeeded')
	        {
				# The VM failed to start, so send notice
                Write-Output ($VM.InstanceName + " failed to start")
	        }
			else
			{
				# The VM started, so send notice
				#Write-Output ($VM.InstanceName + " has been started")
				$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
				$Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
	
				Write-Output($Start.tostring()+" " + $VM.InstanceName + " has been started!!")
			}
		}
    }
}