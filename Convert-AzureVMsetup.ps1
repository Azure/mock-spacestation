
# [int]$maxLength = 87380;
# [string]$bicepFile = ".\AzureVM.bicep"
# $setupFileContents = (Get-Content -path ".\AzureVMsetup.sh");
# $setupFileContentsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($setupFileContents))

# if($setupFileContentsBase64.Length -gt $maxLength){
#     throw "Conversion to Base64 exceeded max length supported by Azure CLI.  Max Length: $maxLength.  Length of AzureVMsetup.sh: $($setupFileContentsBase64.Length)"
# }

# [System.IO.StreamReader]$fileReader = New-Object System.IO.StreamReader($bicepFile);

# [bool]$isOSProfile = $false;
# [System.Text.StringBuilder]$newBicepFile = New-Object -TypeName "System.Text.StringBuilder"; 

# while ($null -ne ($line =$fileReader.ReadLine())) {
#     if($isOSProfile -eq $true -and $line.Contains("customData:")){        
#         $newBicepFile.AppendLine("      customData: '" + $setupFileContentsBase64 + "'")  | Out-Null;
#     }else{
#         $newBicepFile.AppendLine($line) | Out-Null
#     }
#     if($line.Contains("osProfile")){
#         $isOSProfile = $true;
#     }    
# }

# $fileReader.Close();
# $fileReader.Dispose();
# $fileReader = $null;

# #Set-Content -Path $bicepFile -Value $newBicepFile.ToString();
# [System.IO.StreamWriter]$fileWriter = New-Object System.IO.StreamWriter($bicepFile);

# $fileWriter.Write($newBicepFile.ToString());
# $fileWriter.Close();
# $fileWriter.Dispose();




# # $output = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($setupFileContentsBase64))


# # [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("blahblah"))



# # [System.Text.Encoding]::UNICODE.GetString([System.Convert]::FromBase64String($fileValue));

# # $setupFileContentsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($setupFileContents))
