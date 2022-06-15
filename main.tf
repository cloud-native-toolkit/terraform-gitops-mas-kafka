locals {
  name          = "ibm-masapp-kafka"
  bin_dir        = module.setup_clis.bin_dir
  tmp_dir        = "${path.cwd}/.tmp/${local.name}"
  cfgsecret_dir  = "${local.tmp_dir}/configsecrets"
  yaml_dir       = "${local.tmp_dir}/chart/${local.name}"

  layer              = "services"
  type               = "instances"
  application_branch = "main"
  core-namespace     = "mas-${var.instanceid}-core"
  namespace          = var.namespace
  layer_config       = var.gitops_config[local.layer]

# set values content for subscription
  values_content = {
        kafka = {
          name = var.cluster_name
          secretname = "${var.cluster_name}-credentials"
          username = var.user_name
          namespace = local.namespace
        }
        masapp = {
          instanceid = var.instanceid
          corenamespace = local.core-namespace
        }
    }

}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
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

# create mas credentials for kafka user
resource null_resource create_cfgsecret {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-configsecret.sh '${local.core-namespace}' '${local.cfgsecret_dir}' '${var.cluster_name}'"

    environment = {
      BIN_DIR = module.setup_clis.bin_dir
      KAFKA_USER = var.user_name
      KAFKA_PASS = var.user_password
    }

  }
}

module seal_secrets_cfg {
  depends_on = [null_resource.create_cfgsecret]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git?ref=v1.1.0"

  source_dir    = local.cfgsecret_dir
  dest_dir      = "${local.yaml_dir}/templates"
  kubeseal_cert = var.kubeseal_cert
  label         = local.name
}


### setup sa and job

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = local.namespace
  name = "cfgjob-sa"
  rbac_rules = [{
    apiGroups = ["kafka.strimzi.io"]
    resources = ["jobs","secrets","serviceaccounts","services","pods","kafkas","kafkacfgs"]
    verbs = ["*"]
  },{
    apiGroups = ["config.mas.ibm.com"]
    resources = ["jobs","secrets","serviceaccounts","services","pods","kafkas","kafkacfgs"]
    verbs = ["*"]
  }]
  sccs = ["anyuid","privileged"]
  server_name = var.server_name
  rbac_cluster_scope = true
}

# Deploy Instance and config
resource gitops_module masapp {
  depends_on = [null_resource.deployAppVals, module.seal_secrets_cfg, module.service_account]

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
