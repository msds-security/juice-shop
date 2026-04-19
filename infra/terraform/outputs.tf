output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_region" {
  description = "Region the cluster was created in"
  value       = var.region
}

output "vpc_id" {
  description = "VPC the cluster lives in"
  value       = module.vpc.vpc_id
}

output "update_kubeconfig_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
