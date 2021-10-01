#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Used to convert the BareVMSetup script to Base64 and slipstream into the AzureVM Bicep template
# Syntax: ./BareVMSetup.sh

[int]$maxLength = 87380;
[string]$setupScript = ".\.devcontainer\library-scripts\BareVMSetup.sh"

$setupScriptContents = (Get-Content -Path $setupScript -Raw)
$setupScriptContentsBASE64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($setupScriptContents))

if($setupScriptContentsBASE64.Length -gt $maxLength){
    throw "BareVMSetup.sh length of $($fileScript.Length) exceeds the maximum allowed length of $($maxLength)"
}

[string]$bicepFile = ".\AzureVM.bicep"
[System.IO.StreamReader]$fileReader = New-Object System.IO.StreamReader($bicepFile);

[bool]$isOSProfile = $false;
[System.Text.StringBuilder]$newBicepFile = New-Object -TypeName "System.Text.StringBuilder"; 

while ($null -ne ($line =$fileReader.ReadLine())) {
    if($isOSProfile -eq $true -and $line.Contains("customData:")){        
        $newBicepFile.AppendLine("      customData: '" + $setupScriptContentsBASE64 + "'")  | Out-Null;
    }else{
        $newBicepFile.AppendLine($line) | Out-Null
    }
    if($line.Contains("osProfile")){
        $isOSProfile = $true;
    }    
}

$fileReader.Close();
$fileReader.Dispose();
$fileReader = $null;


[System.IO.StreamWriter]$fileWriter = New-Object System.IO.StreamWriter($bicepFile);

$fileWriter.Write($newBicepFile.ToString());
$fileWriter.Close();
$fileWriter.Dispose();

