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

if ('Add' -eq $operation_type) {
	ForEach ($WAFPolicy in $waf_policy_list) {
		Write-Output $WAFPolicy
		az network front-door waf-policy rule create --name $custom_rule_name --priority $PriorityID --rule-type $rule_type --action $action --resource-group $rsg_name --policy-name $WAFPolicy --disabled $IsDisabled --defer
		
		$IPCount = 0
		ForEach ($item in $IPList) {
			$IPArrayList += $item.("public_ip")
			$IPCount += 1
			$counter += 1
			
			if () {
				$PriorityID += 1
				$RuleName += "2"
				Write-Output "tempe"
				Write-Output $PriorityID
				Write-Output $RuleName
			}
			
			if ($IPCount -eq 5 -and $counter -eq $IPList.length) {
				az network front-door waf-policy rule match-condition add --match-variable RemoteAddr --operator IPMatch --values $IPArrayList --negate false --name $custom_rule_name --resource-group $rsg_name --policy-name $WAFPolicy
				$IPCount = 0
				$IPArrayList = @();
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
