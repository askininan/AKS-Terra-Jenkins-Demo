resource "helm_release" "jenkins" {
  name = "nexus"

  repository = "https://sonatype.github.io/helm3-charts/"
  chart = "nexus"
  namespace = "nexus"
  create_namespace = true
  
  set {
    name = "installCRDS"
    value = "true"
  }
}