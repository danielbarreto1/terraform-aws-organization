# Determina o root da organização (usando org existente ou criando nova)
locals {
  root_id = var.existing_organization_id != null ? var.existing_organization_id : try(aws_organizations_organization.org[0].roots[0].id, null)
}

# Organiza OUs em 3 níveis para evitar ciclos
locals {
  organizational_units_level_0 = {
    for key, name in var.organizational_units :
    key => name
    if !contains(keys(var.organizational_unit_parents), key)
  }

  organizational_units_level_1 = {
    for key, name in var.organizational_units :
    key => name
    if try(var.organizational_unit_parents[key], null) != null && contains(keys(local.organizational_units_level_0), var.organizational_unit_parents[key])
  }

  organizational_units_level_2 = {
    for key, name in var.organizational_units :
    key => name
    if try(var.organizational_unit_parents[key], null) != null && contains(keys(local.organizational_units_level_1), var.organizational_unit_parents[key])
  }
}

# Criação das OUs em níveis separados
resource "aws_organizations_organizational_unit" "level0" {
  for_each = local.organizational_units_level_0

  name      = each.value
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "level1" {
  for_each = local.organizational_units_level_1

  name      = each.value
  parent_id = aws_organizations_organizational_unit.level0[var.organizational_unit_parents[each.key]].id
}

resource "aws_organizations_organizational_unit" "level2" {
  for_each = local.organizational_units_level_2

  name      = each.value
  parent_id = aws_organizations_organizational_unit.level1[var.organizational_unit_parents[each.key]].id
}

# Mapa completo com todas as OUs
locals {
  organizational_units_map = merge(
    { root = local.root_id },
    { for key, ou in aws_organizations_organizational_unit.level0 : key => ou.id },
    { for key, ou in aws_organizations_organizational_unit.level1 : key => ou.id },
    { for key, ou in aws_organizations_organizational_unit.level2 : key => ou.id }
  )
}

# Processamento das contas com os parent_id corretos
locals {
  processed_accounts = {
    for key, account in var.accounts :
    key => {
      email     = account.email
      name      = account.name
      parent_id = local.organizational_units_map[account.parent_key]
    }
    if !(key == "root" && var.existing_organization_id != null)
  }

  tags = merge(
    var.tags,
    {
      "Module" = "aws-foundation-organizations"
    }
  )
}

# Criação das contas
resource "aws_organizations_account" "this" {
  for_each = local.processed_accounts

  email     = each.value.email
  name      = each.value.name
  parent_id = each.value.parent_id
  tags      = local.tags
  tags_all  = {}

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name, name, email]
  }

  depends_on = [
    aws_organizations_organizational_unit.level0,
    aws_organizations_organizational_unit.level1,
    aws_organizations_organizational_unit.level2,
  ]
}

# Leitura ou criação da organização
data "aws_organizations_organization" "org" {
  count = var.existing_organization_id == null ? 0 : 1
}

resource "aws_organizations_organization" "org" {
  count = var.existing_organization_id == null ? 1 : 0

  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = var.feature_set
}