locals {
  name          = "ibm-masapp-kafka"
  operator_name  = "ibm-masapp-kafka-operator"
  bin_dir        = module.setup_clis.bin_dir
  tmp_dir        = "${path.cwd}/.tmp/${local.name}"
  yaml_dir       = "${local.tmp_dir}/chart/${local.name}"
  operator_yaml_dir = "${local.tmp_dir}/chart/${local.operator_name}"

  layer              = "services"
  type               = "instances"
  operator_type      = "operators"
  application_branch = "main"
  core-namespace     = "mas-${var.instanceid}-core"
  namespace          = var.namespace
  appname            = var.appname
  layer_config       = var.gitops_config[local.layer]
  installPlan        = var.installPlan

# set values content for subscription
  values_content = {
        kafka = {
          name = var.cluster_name
          username = var.user_name
          namespace = local.namespace
          size = var.kafka_size
          storageclass = var.storageclass
        }
        masapp = {
          instanceid = var.instanceid
          core-namespace = local.core-namespace
        }
    }
  values_content_operator = {
        subscription = {
          name = local.appname
          channel = var.channel
          installPlanApproval = local.installPlan
          source = var.catalog
          sourceNamespace = var.catalog_namespace
        }
    }


}


module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}


# Add values for operator chart
resource "null_resource" "deployAppValsOperator" {
  count = deploy_op ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.operator_name}' '${local.operator_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content_operator)
    }
  }
}


# Add values for instance charts
resource "null_resource" "deployAppVals" {

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}


# Deploy Operator
resource gitops_module masapp_operator {
  depends_on = [null_resource.deployAppValsOperator]
  count = deploy_op ? 1 : 0

  name        = local.operator_name
  namespace   = local.namespace
  content_dir = local.operator_yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.operator_type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

# Deploy Instance
resource gitops_module masapp {
  depends_on = [gitops_module.masapp_operator, null_resource.deployAppVals]

  name        = local.name
  namespace   = local.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
