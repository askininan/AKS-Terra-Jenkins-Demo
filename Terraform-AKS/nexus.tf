resource "helm_release" "nexus" {
  name = "nexus"

  repository = "https://sonatype.github.io/helm3-charts/"
  chart = "nexus-repository-manager"
  namespace = "nexus"
  create_namespace = true
  
  set {
    name = "installCRDS"
    value = "true"
  }
}