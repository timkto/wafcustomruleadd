##Note. This script is not idempotent. Delete the existing rules on WAF Policy to avoid script failure for adding duplciate values.
param (
	[Parameter(Mandatory = $true)]
	[string]$rsg_name,
	[Parameter(Mandatory = $true)]
	[string]$subscription_id,
	[Parameter(Mandatory = $true)]
	[string[]]$waf_policy_list,
	[Parameter(Mandatory = $true)]
	[string]$custom_rule_name,
	[Parameter(Mandatory = $true)]
	[string]$rule_type,
	[Parameter(Mandatory = $true)]
	[string]$action,
	[Parameter(Mandatory = $true)]
	[string]$status,
	[Parameter(Mandatory = $true)]
	[string]$operation_type,
	[Parameter(Mandatory = $true)]
	[int]$priority,
	[Parameter(Mandatory = $true)]
	[string]$ip_list
)

####Install front-door module for az commands####
az extension add --name front-door

$IsDisabled = if ('Disabled' -eq $status) {$true} else {$false}
[string[]]$IPArrayList = @()
[string[]]$NewIPList = @()
$PriorityID = $priority
$RuleName = $custom_rule_name
$IPList = import-csv $ip_list
$counter = 0
$IPCount = 0

if ('Add' -eq $operation_type) {
	ForEach ($WAFPolicy in $waf_policy_list) {
		Write-Output $WAFPolicy
		az network front-door waf-policy rule create --name $RuleName --priority $PriorityID --rule-type $rule_type --action $action --resource-group $rsg_name --policy-name $WAFPolicy --disabled $IsDisabled --defer
		
		ForEach ($item in $IPList) {
			$IPArrayList += $item.("public_ip")
			$IPCount += 1
			$counter += 1
			
			if ($IPCount -eq 100 -or $counter -eq $IPList.length) {
				az network front-door waf-policy rule match-condition add --match-variable RemoteAddr --operator IPMatch --values $IPArrayList --negate false --name $RuleName --resource-group $rsg_name --policy-name $WAFPolicy
				$IPCount = 0
				$IPArrayList = @();
				Write-Output $counter
			}
			
			if ($counter -eq 600) {
				$PriorityID += 1
				Write-Output $PriorityID.GetType()
				$RuleName += $PriorityID
				Write-Output "tempe"
				Write-Output $PriorityID
				Write-Output $RuleName
				az network front-door waf-policy rule create --name $RuleName --priority $PriorityID --rule-type $rule_type --action $action --resource-group $rsg_name --policy-name $WAFPolicy --disabled $IsDisabled --defer

			}
		}
		
		Write-Output "-------Empyting IP Range Array------"
		##Empyting Array
		$IPArrayList = @();
	}
} else {
	Write-Output "-------Invalid Operation Type------"
}

#####End of Script####
