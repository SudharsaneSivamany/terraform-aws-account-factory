/*
MIT License

Copyright (c) 2024 Sudharsane Sivamany

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

locals {
  account_level_0 = flatten(setsubtract([for entry in var.ou_map.accounts : { acc_name = entry.account_name
    email                      = entry.account_email
    tags                       = lookup(entry, "tags", {})
    parent                     = var.parent_id == null ? "Root" : var.parent_id
    close_on_deletion          = lookup(entry, "close_on_deletion", null)
    role_name                  = lookup(entry, "role_name", null)
    iam_user_access_to_billing = lookup(entry, "iam_user_access_to_billing", null)
  create_govcloud = lookup(entry, "create_govcloud", null) }], []))

  ou_level_1 = flatten(setsubtract([for entry1 in var.ou_map.ous : { ou_name = entry1.ou_name
    tags = lookup(entry1, "tags", {})
  parent = var.parent_id == null ? "Root" : var.parent_id }], []))

  account_level_1 = flatten(setsubtract([for entry1 in var.ou_map.ous : [for account in entry1.accounts : { acc_name = account.account_name
    email                      = account.account_email
    tags                       = lookup(account, "tags", {})
    parent                     = entry1.ou_name
    close_on_deletion          = lookup(account, "close_on_deletion", null)
    role_name                  = lookup(account, "role_name", null)
    iam_user_access_to_billing = lookup(account, "iam_user_access_to_billing", null)
  create_govcloud = lookup(account, "create_govcloud", null) }]], []))

  ou_level_2 = flatten(setsubtract([for entry1 in var.ou_map.ous : [for entry2 in entry1.ous : { ou_name = entry2.ou_name
    tags = lookup(entry2, "tags", {})
  parent = entry1.ou_name }]], []))

  account_level_2 = flatten(setsubtract([for entry1 in var.ou_map.ous : [for entry2 in entry1.ous : [for account in entry2.accounts : { acc_name = account.account_name
    email                      = account.account_email
    tags                       = lookup(account, "tags", {})
    parent                     = "${entry1.ou_name}=1>${entry2.ou_name}"
    close_on_deletion          = lookup(account, "close_on_deletion", null)
    role_name                  = lookup(account, "role_name", null)
    iam_user_access_to_billing = lookup(account, "iam_user_access_to_billing", null)
  create_govcloud = lookup(account, "create_govcloud", null) }]]], []))

  ou_level_3 = flatten(setsubtract([for entry1 in var.ou_map.ous : [for entry2 in entry1.ous : [for entry3 in entry2.ous : { ou_name = entry3.ou_name
    tags = lookup(entry3, "tags", {})
  parent = "${entry1.ou_name}=1>${entry2.ou_name}" }]]], []))

  account_level_3 = flatten(setsubtract([for entry1 in var.ou_map.ous : [for entry2 in entry1.ous : [for entry3 in entry2.ous : [for account in entry3.accounts : { acc_name = account.account_name
    email                      = account.account_email
    tags                       = lookup(account, "tags", {})
    parent                     = "${entry1.ou_name}=1>${entry2.ou_name}=2>${entry3.ou_name}"
    close_on_deletion          = lookup(account, "close_on_deletion", null)
    role_name                  = lookup(account, "role_name", null)
    iam_user_access_to_billing = lookup(account, "iam_user_access_to_billing", null)
  create_govcloud = lookup(account, "create_govcloud", null) }]]]], []))

  account = setunion(local.account_level_0, local.account_level_1, local.account_level_2, local.account_level_3)
}

resource "aws_organizations_organizational_unit" "ou_level_1" {
  for_each  = { for entry in local.ou_level_1 : entry.ou_name => entry }
  name      = each.value["ou_name"]
  parent_id = each.value["parent"] == "Root" ? data.aws_organizations_organization.this.roots[0].id : each.value["parent"]
  tags      = each.value["tags"]
}

resource "aws_organizations_organizational_unit" "ou_level_2" {
  for_each  = { for entry in local.ou_level_2 : "${entry.parent}=1>${entry.ou_name}" => entry }
  name      = each.value["ou_name"]
  parent_id = aws_organizations_organizational_unit.ou_level_1[each.value["parent"]].id
  tags      = each.value["tags"]
}

resource "aws_organizations_organizational_unit" "ou_level_3" {
  for_each  = { for entry in local.ou_level_3 : "${entry.parent}=2>${entry.ou_name}" => entry }
  name      = each.value["ou_name"]
  parent_id = aws_organizations_organizational_unit.ou_level_2[each.value["parent"]].id
  tags      = each.value["tags"]
}


data "aws_organizations_organization" "this" {}

resource "aws_organizations_account" "account" {
  for_each                   = { for entry in local.account : "${entry.acc_name}=>${entry.parent}" => entry }
  email                      = each.value["email"]
  name                       = each.value["acc_name"]
  parent_id                  = strcontains(each.value["parent"], "=2>") ? aws_organizations_organizational_unit.ou_level_3[each.value["parent"]].id : strcontains(each.value["parent"], "=1>") ? aws_organizations_organizational_unit.ou_level_2[each.value["parent"]].id : each.value["parent"] != "Root" ? try(aws_organizations_organizational_unit.ou_level_1[each.value["parent"]].id, each.value["parent"]) : data.aws_organizations_organization.this.roots[0].id
  close_on_deletion          = each.value["close_on_deletion"]
  role_name                  = each.value["role_name"]
  iam_user_access_to_billing = each.value["iam_user_access_to_billing"]
  create_govcloud            = each.value["create_govcloud"]

  lifecycle {
    ignore_changes = [role_name]
  }
}


locals {
  account_spec = [for entry in local.account : { account_id = aws_organizations_account.account["${entry.acc_name}=>${entry.parent}"].id
    account_name = entry.acc_name
    parent_name  = strcontains(entry.parent, "=2>") ? aws_organizations_organizational_unit.ou_level_3[entry.parent].name : strcontains(entry.parent, "=1>") ? aws_organizations_organizational_unit.ou_level_2[entry.parent].name : entry.parent != "Root" ? try(aws_organizations_organizational_unit.ou_level_1[entry.parent].name, entry.parent) : data.aws_organizations_organization.this.roots[0].name
  parent_id = strcontains(entry.parent, "=2>") ? aws_organizations_organizational_unit.ou_level_3[entry.parent].id : strcontains(entry.parent, "=1>") ? aws_organizations_organizational_unit.ou_level_2[entry.parent].id : entry.parent != "Root" ? try(aws_organizations_organizational_unit.ou_level_1[entry.parent].id, entry.parent) : data.aws_organizations_organization.this.roots[0].id }]

  ou_arn = concat([for entry in local.ou_level_1 : { ou_name = "${entry.parent}=0>${entry.ou_name}", ou_arn = aws_organizations_organizational_unit.ou_level_1[entry.ou_name].arn }],
    [for entry in local.ou_level_2 : { ou_name = "${entry.parent}=1>${entry.ou_name}", ou_arn = aws_organizations_organizational_unit.ou_level_2["${entry.parent}=1>${entry.ou_name}"].arn }],
  [for entry in local.ou_level_3 : { ou_name = "${entry.parent}=2>${entry.ou_name}", ou_arn = aws_organizations_organizational_unit.ou_level_3["${entry.parent}=2>${entry.ou_name}"].arn }])
}

resource "time_sleep" "wait_60_seconds_ou_register" {
  depends_on = [aws_organizations_account.account, aws_organizations_organizational_unit.ou_level_1, aws_organizations_organizational_unit.ou_level_2, aws_organizations_organizational_unit.ou_level_3]

  create_duration = "60s"
}

resource "terraform_data" "ou_register" {
  depends_on = [time_sleep.wait_60_seconds_ou_register]

  for_each = { for i in local.ou_arn : i.ou_name => i }

  triggers_replace = [each.key, each.value["ou_arn"]]

  provisioner "local-exec" {
    when        = create
    working_dir = path.module
    command     = "${var.python} register_ou.py ${each.value["ou_arn"]}"
  }
}



resource "time_sleep" "wait_60_seconds_account_enroll" {
  depends_on = [terraform_data.ou_register]

  create_duration = "60s"
}


resource "terraform_data" "account_enroll" {
  depends_on = [time_sleep.wait_60_seconds_account_enroll]

  for_each = { for i in local.account_spec : i.account_name => i }

  triggers_replace = [each.key, each.value["parent_name"]]

  provisioner "local-exec" {
    when        = create
    working_dir = path.module
    command     = "${var.python} enroll_account.py --ou ${each.value["parent_id"]} -i ${each.value["account_id"]} ${each.value["parent_name"] == "Root" ? "-c" : "-n"}"
  }

}
