#$executionScript = "curl https://raw.githubusercontent.com/bigtallcampbell/mock-spacestation/main/.devcontainer/library-scripts/BareVMSetup.sh -O | sudo sh BareVMSetup.sh"
#[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($executionScript))

#$fileScript = [convert]::ToBase64String((Get-Content -Path ".\.devcontainer\library-scripts\BareVMSetup.sh" -Raw -Encoding byte));

[int]$maxLength = 87380;
[string]$spaceStationDockerFile = ".\.devcontainer\library-scripts\Dockerfile.SpaceStation"
[string]$setupScript = ".\.devcontainer\library-scripts\BareVMSetup.sh"

$setupScriptContents = (Get-Content -Path $setupScript -Raw)
$dockerFileSpaceStationScriptContents = (Get-Content -Path $spaceStationDockerFile -Raw)
$setupScriptContents = $setupScriptContents.Replace("||STATION_DOCKER_FILE||", $dockerFileSpaceStationScriptContents);
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

#Set-Content -Path $bicepFile -Value $newBicepFile.ToString();
[System.IO.StreamWriter]$fileWriter = New-Object System.IO.StreamWriter($bicepFile);

$fileWriter.Write($newBicepFile.ToString());
$fileWriter.Close();
$fileWriter.Dispose();




# # $output = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($setupFileContentsBase64))


# # [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("blahblah"))



# # [System.Text.Encoding]::UNICODE.GetString([System.Convert]::FromBase64String($fileValue));

# # $setupFileContentsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($setupFileContents))
