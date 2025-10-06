locals {
  acme_server = var.letsencrypt_environment == "staging" ?
    "https://acme-staging-v02.api.letsencrypt.org/directory" :
    "https://acme-v02.api.letsencrypt.org/directory"
}

# Ingress NGINX
resource "helm_release" "ingress_nginx" {
  count      = var.enable_ingress ? 1 : 0
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = null
  create_namespace = true

  # Default values are fine for initial setup
}

# cert-manager
resource "helm_release" "cert_manager" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = null
  create_namespace = true

  values = [yamlencode({
    installCRDs = true
  })]
}

# ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  count = var.enable_cert_manager ? 1 : 0
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.letsencrypt_environment == "staging" ? "letsencrypt-staging" : "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = local.acme_server
        privateKeySecretRef = {
          name = var.letsencrypt_environment == "staging" ? "acme-staging-account-key" : "acme-prod-account-key"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}

# External DNS: secret with DO token
resource "kubernetes_secret" "external_dns" {
  count = var.enable_external_dns ? 1 : 0
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }
  data = {
    DO_TOKEN = var.do_token
  }
}

# External DNS Helm chart (kubernetes-sigs)
resource "helm_release" "external_dns" {
  count      = var.enable_external_dns ? 1 : 0
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = null

  values = [yamlencode({
    provider = "digitalocean"
    policy   = "upsert-only"
    sources  = ["service", "ingress"]
    domainFilters = [var.domain_base]
    env = [{
      name = "DO_TOKEN"
      valueFrom = {
        secretKeyRef = {
          name = kubernetes_secret.external_dns[0].metadata[0].name
          key  = "DO_TOKEN"
        }
      }
    }]
  })]

  depends_on = [kubernetes_secret.external_dns]
}

# Metrics Server
resource "helm_release" "metrics_server" {
  count      = var.enable_metrics_server ? 1 : 0
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = null
}
