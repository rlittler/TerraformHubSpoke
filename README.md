
>> NSG’s allow RDP/SSH from ANY, ANY

>> Firewall Rules need to be added to control access to VNets (First Hop For all VNets is FW).

>> Connection is added but PSK/IP needs changing to match on prem.

>> GW BGP Disabled by default

>> VNET Allow GW Transit / Use Remote GW disabled by default.

>> VM Passwords output in TF Console

>> Have to run template twice, Because resource deployments time out if GW takes over 30 mins to provision. 

https://imgur.com/ZesK9pA
