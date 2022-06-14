#  Maximo Application Suite - Kafka Configuration gitops terraform module
This module will deploy the Kafka config to an existing MAS Core cluster.  This will create a secret in the MAS namespace with the credentials as well as creating a `system` scoped KafkaCfg custom resource within the MAS Core namespace.  A Kafka instance must already exist before using this module.  It is recommended to use the `Strimzi` module referenced below in the Suggested companion modules section.

The MAS `instanceid` is required as well as the block storageclass when calling this module.  Unless otherwise specified, the default kafka user and kafka installed namespace is `maskafka`

This module has been tested with Strimzi v0.22.x


## Supported platforms

- OCP 4.8+

## Suggested companion modules

The module itself requires some information from the cluster and needs a
namespace to be created. The following companion
modules can help provide the required information:

- Gitops:  github.com/cloud-native-toolkit/terraform-tools-gitops
- Gitops Bootstrap: github.com/cloud-native-toolkit/terraform-util-gitops-bootstrap
- Pull Secret:  github.com/cloud-native-toolkit/terraform-gitops-pull-secret
- Catalog: github.com/cloud-native-toolkit/terraform-gitops-cp-catalogs 
- Cert:  github.com/cloud-native-toolkit/terraform-util-sealed-secret-cert
- Cluster: github.com/cloud-native-toolkit/terraform-ocp-login
- CertManager: github.com/cloud-native-toolkit/terraform-gitops-ocp-cert-manager
- Strimzi:  github.com/cloud-native-toolkit/terraform-gitops-kafka


## Example usage

```hcl-terraform
module "mas_kafka" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-mas-kafka"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  instanceid = "masdemo"
  storageclass = "ibmc-vpc-block-10iops-tier"
}
```
