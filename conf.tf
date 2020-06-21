//Set Subscription
//hello check git.
variable "subscriptionID" {
  default = "c405f45d-d750-45a5-8d4d-5c9006d4b2b5"
}

//Create the RG

//resource "azurerm_resource_group" "TERRAFORM-RG" {
//  location = "West Europe"
//  name = "TERRAFORM-RG"
//}
//------------------------------
//Create Hub VNet

module "hubVnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = var.rgname
  vnet_name           = var.hubVnetName
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  subnet_names        = ["AzureFirewallSubnet", "GatewaySubnet", "ManagementSubnet", "AzureBastionSubnet", "ADDSSubnet"]
}
//------------------------------

// Create Spoke 1 VNet {Workloads}

module "spoke01VNet" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = var.spoke01VNetName
  resource_group_name = var.rgname
  address_space       = ["10.1.0.0/16"]
  subnet_prefixes     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  subnet_names        = ["ManagementSubnet", "Workloads01Subnet", "Workloads02Subnet"]
}
//------------------------------
// Create Spoke 2 VNet {Workloads}

module "spoke02VNet" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = var.spoke02VNetName
  resource_group_name = var.rgname
  address_space       = ["10.2.0.0/16"]
  subnet_prefixes     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  subnet_names        = ["ManagementSubnet", "Workloads01Subnet", "Workloads02Subnet"]
}
//------------------------------
// Create the Peerings

resource "azurerm_virtual_network_peering" "HubToSpoke01" {
  name                      = "HubToSpoke01"
  resource_group_name       = var.rgname
  virtual_network_name      = module.hubVnet.vnet_name
  remote_virtual_network_id = module.spoke01VNet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit = false
}
resource "azurerm_virtual_network_peering" "Spoke1ToHub" {
  name                      = "HubToSpoke01"
  resource_group_name       = var.rgname
  virtual_network_name      = module.spoke01VNet.vnet_name
  remote_virtual_network_id = module.hubVnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit = false
}


resource "azurerm_virtual_network_peering" "HubToSpoke02" {
  name                      = "HubToSpoke02"
  resource_group_name       = var.rgname
  virtual_network_name      = module.hubVnet.vnet_name
  remote_virtual_network_id = module.spoke02VNet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit = false
}
resource "azurerm_virtual_network_peering" "Spoke02ToHub" {
  name                      = "HubToSpoke02"
  resource_group_name       = var.rgname
  virtual_network_name      = module.spoke02VNet.vnet_name
  remote_virtual_network_id = module.hubVnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit = false
}
//------------------------------
// Create & Associate the Network Security Groups

resource "azurerm_network_security_group" "Spoke01NSG" {
  depends_on          = ["module.spoke01VNet"]
  name                = "Spoke01NSG"
  location            = "west europe"
  resource_group_name = var.rgname

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "Spoke02NSG" {
  depends_on          = ["module.spoke02VNet"]
  name                = "Spoke02NSG"
  location            = "west europe"
  resource_group_name = var.rgname

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "BastionNSG" {
  depends_on          = ["module.hubVnet"]
  name                = "BastionNSG"
  location            = "west europe"
  resource_group_name = var.rgname

  security_rule {
    name                       = "Bastion443-IB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "443"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDPVNet-OB"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Bastion443-OB"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "443"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "spoke01NSGAssociation" {
  count                     = length(module.spoke01VNet.vnet_subnets)
  subnet_id                 = module.spoke01VNet.vnet_subnets[count.index]
  network_security_group_id = azurerm_network_security_group.Spoke01NSG.id
}

resource "azurerm_subnet_network_security_group_association" "spoke02NSGAssociation" {
  count                     = length(module.spoke02VNet.vnet_subnets)
  subnet_id                 = module.spoke02VNet.vnet_subnets[count.index]
  network_security_group_id = azurerm_network_security_group.Spoke02NSG.id
}

resource "azurerm_subnet_network_security_group_association" "managementSubnetNSGAssociation" {
  subnet_id                 = module.hubVnet.vnet_subnets[2]
  network_security_group_id = azurerm_network_security_group.BastionNSG.id
}
//------------------------------
// Create the Route Table
resource "azurerm_route_table" "spoke01UDR" {
  name                          = "Spoke01UDR"
  location                      = var.location
  resource_group_name           = var.rgname
  disable_bgp_route_propagation = false

  route {
    name           = "nextHopeFirewall"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "vnetlocal"
  }
}

resource "azurerm_route_table" "spoke02UDR" {
  name                          = "Spoke02UDR"
  location                      = var.location
  resource_group_name           = var.rgname
  disable_bgp_route_propagation = false

  route {
    name           = "nextHopeFirewall"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "vnetlocal"
  }
}

resource "azurerm_route_table" "hubUDR" {
  name                          = "HubUDR"
  location                      = var.location
  resource_group_name           = var.rgname
  disable_bgp_route_propagation = false

  route {
    name           = "nextHopeFirewall"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "vnetlocal"
  }
}
//------------------------------
//Associate UDRs
resource "azurerm_subnet_route_table_association" "RouteAssociateSpoke1" {
  count          = length(module.spoke01VNet.vnet_subnets)
  subnet_id      = module.spoke01VNet.vnet_subnets[count.index]
  route_table_id = azurerm_route_table.spoke01UDR.id
}

resource "azurerm_subnet_route_table_association" "RouteAssociateSpoke2" {
  count          = length(module.spoke02VNet.vnet_subnets)
  subnet_id      = module.spoke02VNet.vnet_subnets[count.index]
  route_table_id = azurerm_route_table.spoke02UDR.id
}

//Associate UDRs
resource "azurerm_subnet_route_table_association" "RouteAssociateGWSubnet" {
  subnet_id      = module.hubVnet.vnet_subnets[1]
  route_table_id = azurerm_route_table.hubUDR.id
}

//--------------
resource "azurerm_subnet_route_table_association" "RouteAssociateADDSSubnet" {
  subnet_id = module.hubVnet.vnet_subnets[4]
  route_table_id = azurerm_route_table.hubUDR.id
}
//}----------------
// P2S/S2S VPN GW AND LNG
// Requires manual change of IP's etc.

resource "azurerm_local_network_gateway" "LNG" {
  name                = "LNG"
  location            = var.location
  resource_group_name = var.rgname
  gateway_address     = "168.62.225.23"
  address_space       = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "GWPiP" {
  name                = "GWPiP"
  location            = var.location
  resource_group_name = var.rgname
  allocation_method   = "Dynamic"
}

output "gwsnid" {
  value = module.hubVnet.vnet_subnets[1]
}


resource "azurerm_virtual_network_gateway" "S2S-GW" {
  location = var.location
  name = "S2S-GW"
  resource_group_name = var.rgname
  sku = "Basic"
  type = "Vpn"

  ip_configuration {
    public_ip_address_id = azurerm_public_ip.GWPiP.id
    subnet_id = module.hubVnet.vnet_subnets[1]
  }
}

resource "azurerm_virtual_network_gateway_connection" "GWConnection" {
  name                = "S2SConnection"
  location            = var.location
  resource_group_name = var.rgname

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.S2S-GW.id
  local_network_gateway_id   = azurerm_local_network_gateway.LNG.id

  shared_key = "ent3r-pr3-sh4r3d-k3y-h3r3"
}

//https://github.com/hashicorp/terraform/issues/21170 - Seems to be same issue of accessing tuple value twice.

//------------------------------
 //Azure Firewall

resource "azurerm_public_ip" "AZFWPiP" {
  name                = "AZFWPiP"
  location            = var.location
  resource_group_name = var.rgname
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "example" {
  name                = "AzureFirewall"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                 = "AZFWPiPConfig"
    subnet_id            = module.hubVnet.vnet_subnets[0]
    public_ip_address_id = azurerm_public_ip.AZFWPiP.id
  }
}

//Bastion Host
//VMForBastion
resource "random_password" "BastionPassword" {
  length = 16
  special = true
  override_special = "_%@"
}

output "BastionPasswordOutput" {
  value = random_password.BastionPassword.result
}

resource "azurerm_network_interface" "BASTION-VM-NIC" {
  name                = "BASTION-VM-NIC"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.hubVnet.vnet_subnets[2]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "BASTION-VM" {
  name                = "BASTION-VM"
  resource_group_name = var.rgname
  location            = var.location
  size                = "Standard_DS3_v2"
  admin_username      = "sysadmin"
  admin_password      = random_password.BastionPassword.result
  network_interface_ids = [azurerm_network_interface.BASTION-VM-NIC.id]

  os_disk {
    name                 = "OSDisk01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

//BastionHost
resource "azurerm_public_ip" "BastionHostPiP" {
  name                = "BastionHostPiP"
  location            = var.location
  resource_group_name = var.rgname
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "BastionJB" {
  name                = "BastionJumpbox"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                 = "BastionHostPiP"
    subnet_id            = module.hubVnet.vnet_subnets[3]
    public_ip_address_id = azurerm_public_ip.BastionHostPiP.id
  }
}

////ADDS DomainController
resource "random_password" "DomainControllerPassword" {
  length = 16
  special = true
  override_special = "_%@"
}

output "DomainControllerPasswordOutput" {
  value = random_password.DomainControllerPassword.result
}

resource "azurerm_network_interface" "DC-VM-NIC" {
  name                = "DC-VM-NIC"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.hubVnet.vnet_subnets[4]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "DC-VM" {
  name                = "DC-VM"
  resource_group_name = var.rgname
  location            = var.location
  size                = "Standard_DS3_v2"
  admin_username      = "sysadmin"
  admin_password      = random_password.DomainControllerPassword.result
  network_interface_ids = [azurerm_network_interface.DC-VM-NIC.id]

  os_disk {
    name                 = "DC-Disk01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

