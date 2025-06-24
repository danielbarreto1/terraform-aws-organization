output "accounts_summary" {
  value = {
    for key, account in var.accounts :
    key => {
      name         = account.name
      email        = account.email
      parent_key   = account.parent_key
      parent_ou_id = local.organizational_units_map[account.parent_key]
    }
    if !(key == "root" && var.existing_organization_id != null)
  }
}

output "organizational_units" {
  value = local.organizational_units_map
}

output "organization_id" {
  value = var.existing_organization_id != null ? var.existing_organization_id : aws_organizations_organization.org[0].id
}

output "root_id" {
  value = local.root_id
}