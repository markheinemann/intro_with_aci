provider "aci" {
  # cisco-aci user name
  username = "admin"
  # cisco-aci password
  password = "!v3G@!4@Y"
  # cisco-aci url
  url      =  "https://sandboxapicdc.cisco.com"
  insecure = true
}

#resource "aci_tenant" "terraform_tenant" {
#  name        = "marks_tenant_for_terraform"   
#  description = "This tenant is created by the Terraform ACI provider"
#}

#resource "aci_bridge_domain" "bd_for_subnet" {
#  tenant_dn   = aci_tenant.terraform_tenant.id
#  name        = "mark_bd_for_subnet"
#  description = "This bridge domain is created by the Terraform ACI provider"
#}



#resource "aci_subnet" "demosubnet" {
#  parent_dn = aci_bridge_domain.bd_for_subnet.id
#  ip               = "10.1.1.1/24"
#  scope            = ["private"]
#  description      = "This subnet is created by Terraform"
#}

#
#
#

locals {
  yaml_tenants= yamldecode(file("${path.module}/tenant_vars.yml"))
}



#output "yaml_tenants" {
#  value = local.yaml_tenants
#}




#output "tenant01_details" {
#  value = local.yaml_rg.tenant[0]
#}



output "tenant_details" {
  value = { for t in local.yaml_tenants.tenant : t.tenant => t }
}


resource "aci_tenant" "tenants" {
  for_each = { for t in local.yaml_tenants.tenant : t.tenant => t }

  name        = each.value.tenant
  description = each.value.description
}








#new locals for bd


locals {
  yaml_bd= yamldecode(file("${path.module}/bd_vars.yml"))
}

output "bd_details" {
  value = { for t in local.yaml_bd.bd : t.bd => t }
}

resource "aci_bridge_domain" "bridge_domains" {
  for_each = { for t in local.yaml_bd.bd : t.bd => t }
  tenant_dn   = "uni/tn-${each.value.bd_tenant_name}"
  #tenant_dn   = each.value.bd_tenant_name
  name        = each.value.bd
  description = each.value.bd_description
}



#resource "aci_bridge_domain" "bd_for_subnet" {
#  tenant_dn   = aci_tenant.terraform_tenant.id
#  name        = "mark_bd_for_subnet"
#  description = "This bridge domain is created by the Terraform ACI provider"
#}


#new locals for aci subnets


locals {
  yaml_aci_subnets= yamldecode(file("${path.module}/aci_subnet_vars.yml"))
}

output "aci_subnet_details" {
  value = { for t in local.yaml_aci_subnets.aci_subnet : t.aci_subnet => t }
}

resource "aci_subnet" "aci_subnets" {
  for_each = { for t in local.yaml_aci_subnets.aci_subnet : t.aci_subnet => t }
  parent_dn    = "uni/tn-${each.value.aci_subnet_tn_name}/BD-${each.value.aci_subnet_bd}"
  ip        = each.value.aci_subnet
  description = each.value.aci_subnet_description
  scope = [each.value.aci_subnet_scope]

  depends_on = [null_resource.aci_subnet_dependency]
}

resource "null_resource" "aci_subnet_dependency" {
  depends_on = [aci_bridge_domain.bridge_domains]

  triggers = {
    aci_subnet_dependency = "${jsonencode(aci_bridge_domain.bridge_domains)}"
  }
}

