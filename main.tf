provider "aci" {
  # cisco-aci user name
  username = "admin"
  # cisco-aci password
  password = "!v3G@!4@Y"
  # cisco-aci url
  url      =  "https://sandboxapicdc.cisco.com"
  insecure = true
}




locals {
  yaml_tenants= yamldecode(file("${path.module}/tenant_vars.yml"))
}



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
  name        = each.value.bd
  description = each.value.bd_description
}


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



#new locals for epg


locals {
  yaml_epg= yamldecode(file("${path.module}/epg_vars.yml"))
}

output "epg_details" {
  value = { for t in local.yaml_epg.epg : t.epg => t }
}

resource "aci_application_epg" "epgs" {
  for_each = { for t in local.yaml_epg.epg: t.epg => t }
  name = each.value.epg
  #application_profile_dn = each.value.epg_map_to_app_profile
  #application_profile_dn = "uni/tn-default/ap-${each.value.epg_map_to_app_profile}"
  #application_profile_dn = "uni/tn-${each.value.epg_tenant}-${each.value.epg_map_to_app_profile}"
  application_profile_dn = "uni/tn-${each.value.epg_tenant}/ap-${each.value.epg_map_to_app_profile}"
  relation_fv_rs_bd = "uni/tn-${each.value.epg_tenant}/BD-${each.value.epg_map_to_bd}"

  depends_on = [null_resource.epg_dependency]
}


# new locals for application_profile


locals {
  yaml_app_profile= yamldecode(file("${path.module}/app_profile_vars.yml"))
}

output "app_profile_details" {
  value = { for t in local.yaml_app_profile.app_profile : t.app_profile => t }
}

resource "aci_application_profile" "app_profiles" {
  for_each = { for t in local.yaml_app_profile.app_profile : t.app_profile => t }
  tenant_dn    = "uni/tn-${each.value.app_profile_tenant}"
  name        = each.value.app_profile
}




# dont build subnet untill bd is built
resource "null_resource" "aci_subnet_dependency" {
  depends_on = [aci_bridge_domain.bridge_domains]

  triggers = {
    aci_subnet_dependency = "${jsonencode(aci_bridge_domain.bridge_domains)}"
  }
}

# dont build epg untill app profile is built
resource "null_resource" "epg_dependency" {
  depends_on = [aci_application_profile.app_profiles]

  triggers = {
    epg_dependency = "${jsonencode(aci_application_profile.app_profiles)}"
  }
}
