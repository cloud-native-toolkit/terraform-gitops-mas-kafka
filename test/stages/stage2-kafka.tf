module "gitops_module" {
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  instanceid = "masdemo"
  cluster_name = module.strimzi.clusterid
  user_name = module.strimzi.user_name
  user_password = module.strimzi.user_password
  namespace = module.strimzi.namespace

}

resource null_resource write_namespace {
  provisioner "local-exec" {
    command = "echo -n '${module.gitops_module.namespace}' > .namespace"
  }
}
