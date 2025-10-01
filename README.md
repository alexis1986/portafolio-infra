# Infraestructura de Portafolio en DigitalOcean (Terraform)

Infraestructura IaC para desplegar una Droplet de DigitalOcean destinada a hospedar un portafolio/proyecto personal. El aprovisionamiento se realiza con Terraform y un `cloud-init` que instala Docker y (opcionalmente) Docker Compose.

Este repo crea:

- Una `digitalocean_droplet` con etiqueta `portafolio` definida en `main.tf`.
- Salida con la IP pública (`output.droplet_ip`).
- Configuración de arranque `cloud-init.sh` que instala y habilita Docker.

## Arquitectura

- Proveedor: `digitalocean/digitalocean` (~> 2.0) configurado en `provider.tf`.
- Recurso principal: `digitalocean_droplet.portafolio` en `main.tf`.
- User data: `cloud-init.sh` para preparar el host (Docker + utilidades).

## Requisitos

- Terraform >= 1.3.0.
- Cuenta de DigitalOcean con un token API válido.
- Una clave SSH pública cargada en DigitalOcean (necesitamos su `ID` o `fingerprint`).
- Opcional: `doctl` (CLI de DigitalOcean) para gestionar claves y probar credenciales.

## Variables principales (`variables.tf`)

- `do_token` (string, sensible): Token API de DigitalOcean.
- `ssh_key_id` (string): ID o fingerprint de la clave SSH subida a DigitalOcean.
- `region` (string, default `nyc3`): Región de la Droplet.
- `droplet_size` (string, default `s-1vcpu-1gb`): Tamaño de la Droplet.
- `droplet_image` (string, default `ubuntu-24-04-x64`): Imagen base.
- `droplet_name` (string, default `portafolio-droplet`): Nombre del recurso.

## Salidas (`output.tf`)

- `droplet_ip`: IPv4 pública de la Droplet provisionada.

## Estructura del proyecto

```
.
├── main.tf              # Recurso Droplet + user_data
├── provider.tf          # Requerimientos y proveedor DO
├── variables.tf         # Variables de entrada
├── output.tf            # Outputs (IP pública)
├── cloud-init.sh        # Script de bootstrap (instala Docker)
├── .terraform.lock.hcl  # Lockfile de proveedores
└── README.md            # Este archivo
```

## Configuración de credenciales

1) Crea un token en DigitalOcean (Control Panel → API → Tokens). Concede permisos de lectura/escritura para Droplets.
2) Sube tu clave SSH pública a DigitalOcean (Control Panel → Settings → Security → Add SSH Key).
3) Obtén el `ID` o `fingerprint` de la clave SSH. Ejemplos:

```bash
# Con doctl (opcional)
doctl auth init
doctl compute ssh-key list

# Vía API (curl), sustituye $DO_TOKEN por tu token
curl -s -H "Authorization: Bearer $DO_TOKEN" \
  https://api.digitalocean.com/v2/account/keys | jq '.ssh_keys[] | {id, name, fingerprint}'
```

## Uso

1) Crea un archivo `terraform.tfvars` con tus valores reales:

```hcl
do_token    = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
ssh_key_id  = "12345678"            # o el fingerprint: "aa:bb:cc:..."
region      = "nyc3"                # opcional, por defecto nyc3
droplet_size = "s-1vcpu-1gb"        # opcional
droplet_image = "ubuntu-24-04-x64"  # opcional
droplet_name  = "portafolio-droplet"# opcional
```

2) Inicializa y valida:

```bash
terraform init
terraform validate
```

3) Previsualiza cambios y aplica:

```bash
terraform plan -out plan.out
terraform apply plan.out
```

4) Obtén la IP pública y conéctate por SSH:

```bash
terraform output droplet_ip
ssh root@$(terraform output -raw droplet_ip)
```

Nota: El `cloud-init` tardará unos minutos en completar la instalación de Docker. Puedes ver el progreso en `/var/log/cloud-init-output.log` dentro de la Droplet.

## ¿Qué hace `cloud-init.sh`?

- Cambia mirrors de DO por los oficiales de Ubuntu (robustez).
- Actualiza paquetes y habilita repos necesarios.
- Instala Docker y habilita el servicio.
- Intenta instalar el plugin `docker-compose-plugin`.
- Si lo anterior falla, intenta la instalación desde el repo oficial de Docker.
- Deja una marca `cloud-init-done.flag` al finalizar.

Verificaciones rápidas después del login:

```bash
docker --version
docker compose version   # puede ser opcional según disponibilidad
```

## Buenas prácticas y seguridad

- No cometas `terraform.tfstate` ni archivos con secretos. Asegúrate de que `.gitignore` cubra `*.tfstate`, `*.tfvars` y similares.
- Trata `do_token` como información sensible. Usa `terraform.tfvars` local o variables de entorno.
- Considera un backend remoto (p. ej., Terraform Cloud) si vas a colaborar o requieres bloqueo de estado.

## Costos

El tamaño por defecto `s-1vcpu-1gb` tiene costo mensual/hora en DigitalOcean. Revisa la [tabla de precios de Droplets](https://www.digitalocean.com/pricing/droplets) y elimina el recurso cuando no lo uses para evitar cargos.

## Solución de problemas

- Docker no está disponible tras el arranque:
  - Revisa `/var/log/cloud-init-output.log`.
  - Ejecuta `systemctl status docker` y `journalctl -u docker`.
  - Vuelve a intentar instalar Compose: `apt-get install -y docker-compose-plugin` o sigue la parte de “repo oficial” del script.

- Error con `ssh_key_id`:
  - Asegúrate de que corresponde al ID o fingerprint de la clave subida a DO.
  - Lista claves: `doctl compute ssh-key list`.

- Error de autenticación del proveedor:
  - Verifica `do_token` y que tenga permisos para gestionar Droplets.

## GitHub Actions CI/CD

Este repositorio incluye workflows automatizados de GitHub Actions para gestionar la infraestructura:

### Workflows disponibles

1. **Terraform Plan** (`.github/workflows/terraform-plan.yml`)
   - Se ejecuta automáticamente en Pull Requests hacia `main`
   - Valida y genera un plan de los cambios
   - Comenta el plan directamente en el PR

2. **Terraform Apply** (`.github/workflows/terraform-apply.yml`)
   - Se ejecuta al hacer merge a `main`
   - Requiere aprobación manual (environment: production)
   - Aplica los cambios a la infraestructura

### Configuración inicial

Para usar GitHub Actions, sigue la guía completa en [GITHUB_SETUP.md](./GITHUB_SETUP.md).

**Resumen:**
1. Configurar secrets en GitHub (DO_TOKEN, SSH_KEY_ID, SPACES_ACCESS_KEY_ID, SPACES_SECRET_ACCESS_KEY)
2. Configurar environment de producción con reviewers
3. Migrar el state local al backend de Spaces: `terraform init -migrate-state`

### Backend remoto

El state de Terraform se almacena en DigitalOcean Spaces:
- **Bucket:** `alexdevvv-portafolio-terraform-state`
- **Region:** `nyc3`
- **Endpoint:** `https://nyc3.digitaloceanspaces.com`

## Mantenimiento y limpieza

- Para destruir la infraestructura creada por este módulo/proyecto:

```bash
terraform destroy
```

Esto eliminará la Droplet y recursos asociados creados por este stack.
