module "strimzi" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-kafka-strimzi"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  cluster_name = "maskafka"
  user_name = "maskafka"
  storageclass = "ibmc-vpc-block-10iops-tier"
}