package terraform.security

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "kubernetes_namespace"
  not resource.change.after.metadata.labels
  msg = "All namespaces must have labels"
}