resource "helm_release" "jenkins" {
  name = "jenkins"

  repository = "https://charts.jenkins.io"
  chart = "jenkins"
  namespace = "jenkins"
  create_namespace = true
  
  set {
    name = "installCRDS"
    value = "true"
  }
}