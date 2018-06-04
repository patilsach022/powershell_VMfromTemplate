Connect-VIServer 192.63.246.79

$numEM= read-host "no of EM to be created"
$Global:startingIp= read-host "Enter the starting ip of your environment ex: 192.168.7.1" #Starting IP of ur Environment
$Global:gatewayIp= read-host "Enter the gateway IP of your environment"  #Gateway of ur Environment
$portGroup= read-host "Enter the portgroup to be used"                 #PortGroup to be used
$prefix= read-host "Enter the prefix to be used for your machines"      #All the machines will be prefixed with this name   
$Global:ipAddress = $startingIp
$singletonIP= $startingIp.Split(".")

function Create-VM($vmName,$template){
   $var= Get-Template -Name "$template"
   $cred= Get-Credential      #credential to access machine.  
   New-VM -Name "$vmName" -Template "$var" -ResourcePool sachin -Datastore CSA-NYS-DS1
   Get-VM -Name "$vmName"|Start-VM
   Get-VM -Name "$vmName" | Get-NetworkAdapter -Name "Network adapter 1"| Set-NetworkAdapter -NetworkName $portGroup -WakeOnLan:$true -StartConnected:$true -Confirm:$false
   $vm= Get-resourcepool sachin | Get-VM -Name "$vmName"
   $vm | Restart-VM
   Invoke-VMScript -VM $vm.Name -ScriptType Bat -ScriptText "netsh interface ipv4 set address ""Ethernet0"" static $ipAddress 255.255.255.0 $gatewayIp" -HostCredential $cred -GuestCredential $cred -ToolsWaitSecs 60
   Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses ($startingIp)
}



For ($i=1;$i -le $numEM; $i++ ){
   Create-VM -vmName  "$prefix-EMSvr-2k12($i)" -template "CSA-EMServer-W2k12" -location "MTC-CustSim"
   $singletonIP[3]=[int]$singletonIP[3] + 1
   $ipAddress = $singletonIP -join "."
}



#For ($i=1;$i -le $numSaas;$i++){
#     Create-VM -vmName "SAAS-2k12($i)" -template CSA-EMServer-W2k12-Aware
#    $singletonIP[3]=[int]$lastbit + 1
#    $ipAddress = $singletonIP -join "."
#}
