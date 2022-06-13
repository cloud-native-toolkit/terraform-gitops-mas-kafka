
output "name" {
  description = "The name of the module"
  value       = local.name
  depends_on  = [gitops_module.masapp]
}

output "branch" {
  description = "The branch where the module config has been placed"
  value       = local.application_branch
  depends_on  = [gitops_module.masapp]
}

output "namespace" {
  description = "The namespace where the module will be deployed"
  value       = local.namespace
  depends_on  = [gitops_module.masapp]
}

output "server_name" {
  description = "The server where the module will be deployed"
  value       = var.server_name
  depends_on  = [gitops_module.masapp]
}

output "layer" {
  description = "The layer where the module is deployed"
  value       = local.layer
  depends_on  = [gitops_module.masapp]
}

output "type" {
  description = "The type of module where the module is deployed"
  value       = local.type
  depends_on  = [gitops_module.masapp]
}

output "clusterid" {
  description = "The id of the kafka cluster name"
  value       = var.cluster_name
  depends_on  = [gitops_module.masapp]
}