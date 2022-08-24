<#PSScriptInfo

.DESCRIPTION Azure Automation runbook script to tag an standalone SAP Java Application Server Instance on Linux VM.

.VERSION 0.0.1

.GUID ef6b15e1-1e53-4251-b512-650d2753ed55

.AUTHOR Goran Condric

.COMPANYNAME Microsoft

.COPYRIGHT (c) 2020 Microsoft . All rights reserved.

.TAGS Azure Automation SAP Java Application Server Instance Linux Tag Standalone Runbook

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES SAPAzurePowerShellModules

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
0.0.1: - Add initial version

#>

#Requires -Module SAPAzurePowerShellModules

Param(
    
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()] 
    [string] $ResourceGroupName,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()] 
    [string] $VMName,

    [Parameter(Mandatory=$True, HelpMessage="SAP System <SID>. 3 characters , starts with letter.")] 
    [ValidateLength(3,3)]
    [string] $SAPSID,

    [Parameter(Mandatory=$True, HelpMessage="SAP Java Application Server Instance Number")]
    [ValidateLength(1, 2)]
    [string] $SAPJavaApplicationServerInstanceNumber,

    [Parameter(Mandatory=$false, HelpMessage="Subscription ID. If null, the current subscription of automation account is used instead.")] 
    [ValidateLength(36,36)]
    [string] $SubscriptionId
)

# Deprecated due to using System Managed Identity
#$connection = Get-AutomationConnection -Name AzureRunAsConnection
#Add-AzAccount  -ServicePrincipal -Tenant $connection.TenantID -ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint 

# Connect to Azure with Automation Account system-assigned managed identity
# Ensure that you do not inherit an AZ Context in your runbook
Disable-AzContextAutosave -Scope Process | out-null

# Connect using Managed Service Identity
try {
	$AzureContext = (Connect-AzAccount -Identity -WarningAction Ignore).context
}
catch{
	Write-Output "There is no system-assigned user identity. Aborting."; 
	Write-Error  $_.Exception.Message
	exit
}

if ($SubscriptionId){
	$SubscriptionId = $SubscriptionId.trim()
	Select-AzSubscription -SubscriptionId $SubscriptionId -ErrorVariable -notPresent  -ErrorAction SilentlyContinue -Tenant $AzureContext.Tenant
}

$ResourceGroupName          = $ResourceGroupName.Trim()
$VMName                     = $VMName.Trim()
$SAPSID                     = $SAPSID.Trim()
$SAPJavaApplicationServerInstanceNumber    = $SAPJavaApplicationServerInstanceNumber.Trim()

# Check if resource group exists. If $False exit
Confirm-AzResoureceGroupExist -ResourceGroupName $ResourceGroupName 

# Check if VM. If $False exit
Confirm-AzVMExist -ResourceGroupName $ResourceGroupName -VMName $VMName

# Tag ASCS VM
New-AzSAPSystemSAPJavaApplicationServerInstanceLinuxTags -ResourceGroupName $ResourceGroupName -VMName $VMName -SAPSID $SAPSID -SAPApplicationInstanceNumber $SAPJavaApplicationServerInstanceNumber

Write-WithTime "Tagging of VM '$VMName' in resource group '$ResourceGroupName' with tags: SAPSID='$SAPSID' ; SAPApplicationInstanceNumber='$SAPJavaApplicationServerInstanceNumber' ; SAPApplicationInstanceType='SAP_J' done."

