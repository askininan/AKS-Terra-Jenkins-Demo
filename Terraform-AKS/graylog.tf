resource "helm_release" "graylog" {
  name = "graylog"

  repository = "https://charts.kong-z.com/"
  chart = "graylog"
  namespace = "graylog"
  create_namespace = true
  
  set {
    name = "installCRDS"
    value = "true"
  }
}