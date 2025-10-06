# Infraestructura de Portafolio en DigitalOcean (Terraform + DOKS)

Infraestructura IaC para crear un clúster de Kubernetes en DigitalOcean (DOKS) con VPC dedicada, integración con DO Container Registry (opcional), y un flujo en dos pasos para instalar add-ons (Ingress NGINX, cert-manager, external-dns y Metrics Server) mediante Terraform y Helm.

## Arquitectura

- Proveedor: `digitalocean/digitalocean` (~> 2.0) en `provider.tf`.
- Red: `digitalocean_vpc.vpc` dedicada y parametrizable.
- Registro: `digitalocean_container_registry.registry` (opcional) e integración `registry_integration` en el clúster.
- Clúster: `digitalocean_kubernetes_cluster.cluster` con:
  - Versión de Kubernetes variable; si está vacía se usa la última estable mediante `data.digitalocean_kubernetes_versions.this.latest_version`.
  - `maintenance_policy` (domingo 03:00 UTC), `auto_upgrade` y `surge_upgrade` activados por defecto.
  - Node pool con autoscaling (`min_nodes=1`, `max_nodes=2`) y tamaño `s-1vcpu-1gb` por defecto.
  - Firewall del plano de control configurado con allowlist dinámico para GitHub Actions (`authorized_sources`).
- Outputs principales: `cluster_id`, `cluster_endpoint`, `kubeconfig` (sensible), `vpc_id`, `registry_name`.
- Add-ons (directorio `addons/`): instalados en un segundo paso usando el `kubeconfig` del clúster.

## Requisitos

- Terraform >= 1.3.0.
- Cuenta de DigitalOcean y `DO_TOKEN` con permisos para Kubernetes, VPC, Registry y DNS (para external-dns).
- Backend remoto configurado en `provider.tf` (DigitalOcean Spaces via backend S3).

## Variables principales (`variables.tf`)

- `do_token` (sensible)
- `region` (default `nyc3`)
- `cluster_name` (default `portafolio-cluster`)
- `kubernetes_version` (vacío => última estable)
- `auto_upgrade` (default `true`), `surge_upgrade` (default `true`)
- `maintenance_policy_day` (default `sunday`), `maintenance_policy_start_time` (default `03:00`)
- `tags` (lista; default `["portafolio"]`)
- `vpc_name` (default `portafolio-vpc`), `vpc_cidr` (default `10.10.0.0/16`)
- `node_pool_name`, `node_pool_size`, `node_pool_min_nodes`, `node_pool_max_nodes`
- `authorized_sources` (lista de CIDRs para el API server)
- `enable_registry_integration` (default `true`), `registry_name` (default `portafolio-registry`), `registry_tier` (default `basic`)

## Estructura del proyecto

```
.
├── main.tf               # VPC, (opcional) Registry, DOKS cluster
├── provider.tf           # Proveedor DO y backend (Spaces via S3)
├── variables.tf          # Variables de entrada parametrizables
├── output.tf             # Outputs (kubeconfig, ids, endpoint)
├── addons/               # Segundo paso: add-ons
│   ├── providers.tf      # Providers kubernetes y helm
│   ├── variables.tf      # Vars de add-ons y credenciales
│   └── main.tf           # Ingress, cert-manager (+ClusterIssuer), external-dns, metrics-server
└── .github/workflows/    # Plan/Apply/Destroy con allowlist dinámico
```

## Uso local (opcional)

```bash
terraform init
terraform plan -out tfplan \
  -var "do_token=$DO_TOKEN" \
  -var "region=nyc3"
terraform apply tfplan

# kubeconfig
terraform output -raw kubeconfig > kubeconfig

# Add-ons (segundo paso)
cd addons
terraform init
terraform apply \
  -var "kubeconfig_file=../kubeconfig" \
  -var "do_token=$DO_TOKEN" \
  -var "domain_base=alexdevvv.com" \
  -var "letsencrypt_email=alexis.castellano@gmail.com" \
  -var "letsencrypt_environment=production"
```

## GitHub Actions CI/CD

Workflows en `.github/workflows/`:

- **Terraform Plan**: Formatea, init, validate y plan. Obtiene IP del runner y la inyecta en `authorized_sources`.
- **Terraform Apply**: Init → plan → apply → exporta `kubeconfig` como artefacto → segundo paso aplica add-ons desde `addons/` con `kubeconfig`.
- **Terraform Destroy**: Destruye add-ons (si hay `kubeconfig`) y luego el clúster.

### Secrets y Variables

- Secrets requeridos: `DO_TOKEN`, `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY`.
- Repository variables opcionales (para override de defaults):
  - `TF_VAR_CLUSTER_NAME`, `TF_VAR_KUBERNETES_VERSION`, `TF_VAR_TAGS` (JSON)
  - `TF_VAR_REGION`, `TF_VAR_VPC_NAME`, `TF_VAR_VPC_CIDR`
  - `TF_VAR_NODE_POOL_NAME`, `TF_VAR_NODE_POOL_SIZE`, `TF_VAR_NODE_POOL_MIN_NODES`, `TF_VAR_NODE_POOL_MAX_NODES`
  - `TF_VAR_DOMAIN_BASE`, `TF_VAR_LETSENCRYPT_EMAIL`, `TF_VAR_LETSENCRYPT_ENVIRONMENT`

## Backend remoto

El state de Terraform se almacena en DigitalOcean Spaces (backend S3) definido en `provider.tf`:
- Bucket: `alexdevvv-portafolio-terraform-state`
- Key: `terraform.tfstate`
- Endpoint: `https://nyc3.digitaloceanspaces.com`

## Mantenimiento y costos

- Ventana de mantenimiento: domingo 03:00 UTC, con `auto_upgrade` y `surge_upgrade`.
- Revisa precios de DOKS, VPC y Registry (si está habilitado) en la web de DigitalOcean.

## Solución de problemas

- Error con versión de Kubernetes: deja `kubernetes_version` vacío para usar `latest_version` del data source.
- Acceso al API: la allowlist usa la IP pública del runner; si necesitás acceso local, agrega tu IP a `authorized_sources`.
- Add-ons: requieren que el clúster esté listo y que `kubeconfig` sea válido.

## Notas

- El stack anterior basado en Droplet/`cloud-init.sh` fue reemplazado por DOKS. `cloud-init.sh` ya no se utiliza.
