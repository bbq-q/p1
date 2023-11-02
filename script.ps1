# Get the directory where the script is located
$ScriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

# Define the base file name
$BaseFileName = "WiFiPasswords.txt"
$Counter = 1

# Iterate through drive letters from D: to H:
for ($DriveLetter = [int][char]'D'; $DriveLetter -le [int][char]'H'; $DriveLetter++) {
    $Counter = 1
    $Drive = [char]::ConvertFromUtf32($DriveLetter)
    $OutputFile = "${Drive}:\\$BaseFileName"

    # Check if the file already exists on the current drive and increment the counter if needed
    while (Test-Path -Path $OutputFile) {
        $OutputFile = "${Drive}:\\$BaseFileName"
        $BaseFileName = "WiFiPasswords_$Counter.txt"
        $Counter++
    }

    # Check if the script is running on the current drive
    if (Test-Path -Path "${Drive}:\\") {
        # Combine the script directory and the output file name
        $OutputFile = Join-Path -Path $ScriptDirectory -ChildPath $BaseFileName

        (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object {
            $name = $_.Matches.Groups[1].Value.Trim()
            $profileInfo = (netsh wlan show profile name="$name" key=clear) | Select-String "Key Content\W+\:(.+)$"
            if ($profileInfo) {
                $pass = $profileInfo.Matches.Groups[1].Value.Trim()
                [PSCustomObject]@{ PROFILE_NAME = $name; PASSWORD = $pass }
            }
        } | Format-Table -AutoSize | Out-File -FilePath $OutputFile

        Write-Host "good"
        break  # Exit the loop once the file is saved on the current drive
    }
}
