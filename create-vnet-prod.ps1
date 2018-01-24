
$AzRegion = "Central US"
$subscriptionID = "e53aa0c7-824d-40a2-b420-4ab77b1051d2" #enterprise
#$subscriptionID = "fc3a960a-7c4c-4bf7-9b7b-64045347cd77" #rkramer
$rtname="RTR_SERVERS"
$untrustrt="rt_untrust"
$peer="Vnet_Shared_Services"

Login-AzureRmAccount
#Get-AzureRmSubscription
Get-AzureRmSubscription -SubscriptionId $subscriptionID| Set-AzureRmContext


$RGName= Read-Host -Prompt 'What is your pre-existing user group you want to create a vnet in?'
$VNETName = Read-Host -Prompt 'Vnet Name?'
$subnets = Read-Host -Prompt 'How many subnets to pre-create? (minimum 1)'

$subnetName=@()
$subnetRange=@()

$rt = Get-AzureRmRouteTable -Name $rtname -ResourceGroupName $RGName
$untrust=Get-AzureRmRouteTable -Name $untrustrt -ResourceGroupName $RGName




for ($i=0;$i -lt $subnets;$i++)
{
    $subnetName+=Read-Host -Prompt "Subnet $i Name?"
    $subnetRange+=Read-Host -Prompt "Base $i Range?"
    #$newsubnetName = $subnetRange[$i]
    #$newsubnetName -replace "//","_"
    #Write-Host " new subnet name is $newsubnetName"
}



$vnet= New-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RGName -Location $AzRegion -AddressPrefix  $subnetRange[0] -DnsServer "10.2.7.40"
$myvnet = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RGName


Write-Host "Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName[0] -VirtualNetwork $myvnet -AddressPrefix $subnetRange[0]"


#Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName[0] -VirtualNetwork $myvnet -AddressPrefix $subnetRange[0]

for ($i=0;$i -lt $subnets;$i++)
{
    if ($i -gt 0)
    {
        $myvnet.AddressSpace.AddressPrefixes.Add($subnetRange[$i])
    }
    Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName[$i] -VirtualNetwork $myvnet -AddressPrefix $subnetRange[$i] -RouteTable $rt
    $newsubnetName =$subnetRange[$i] -replace "\/","_"
    Add-AzureRmRouteConfig -Name $newsubnetName -NextHopType "VirtualAppliance" -NextHopIpAddress "10.21.1.11" -RouteTable $untrust -AddressPrefix $subnetRange[$i]
    Write-Host "add-azurermrouteconfig -Name $newsubnetName -NextHopType \"VirtualAppliance\" -NextHopIpAddress \"10.21.1.11\" -RouteTable $untrust"

}

# $untrust | Set-AzureRmVirtualNetwork
#$myvnet | Set-AzureRmVirtualNetwork



$servicesvnet= Get-AzureRmVirtualNetwork -Name $peer -ResourceGroupName $RGName

Add-AzureRmVirtualNetworkPeering -name $VNETName -VirtualNetwork $servicesvnet -AllowGatewayTransit -RemoteVirtualNetworkId $myvnet.Id
Add-AzureRmVirtualNetworkPeering -name $VNETName -VirtualNetwork $myvnet -UseRemoteGateways -RemoteVirtualNetworkId $servicesvnet.Id

$untrust | Set-AzureRmRouteTable
$myvnet | Set-AzureRmVirtualNetwork
$servicesvnet | Set-AzureRmVirtualNetwork
