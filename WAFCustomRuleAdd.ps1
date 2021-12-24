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
	[string]$priority,
	[Parameter(Mandatory = $true)]
	[string]$ip_list
)

####Install front-door module for az commands####
az extension add --name front-door

$IsDisabled = if ('Disabled' -eq $status) {$true} else {$false}
[string[]]$IPArrayList = @()
[string[]]$NewIPList = @()
$IPList = import-csv $ip_list

ForEach ($item in $IPList) {
	$IPArrayList += $item.("public_ip")
}

$counter = 0
if ($IPArrayList -ne $null) {
	for($i=0; $i -lt $IPArrayList.length; $i+=100) {
		$NewIPList += ,$IPArrayList[$i..($i+99)]
		$counter += 1
	}
}

if ('Add' -eq $operation_type) {
	ForEach ($WAFPolicy in $waf_policy_list) {
		Write-Output $WAFPolicy
		
		if ($NewIPList -ne $null) {
			az network front-door waf-policy rule create --name $custom_rule_name --priority $priority --rule-type $rule_type --action $action --resource-group $rsg_name --policy-name $WAFPolicy --disabled $IsDisabled --defer
			az network front-door waf-policy rule match-condition add --match-variable RemoteAddr --operator IPMatch --negate false --name $custom_rule_name --resource-group $rsg_name --policy-name $WAFPolicy
			for(; $counter -gt 0; $counter-=1) {
				az network front-door waf-policy rule match-condition--values $NewIPList[$counter-1] --name $custom_rule_name --resource-group $rsg_name --policy-name $WAFPolicy
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
