# infra — OpenTofu for Atlas CMMS

Two environments, `test` and `prod`, both in the shared `New-Implementations`
resource group in the `Enterprise` subscription.

```
infra/
  bootstrap/          state storage account. Run once, by hand.
  modules/cmms/       everything one environment needs
  envs/test/          cmms-test    B2 plan,    atlastest
  envs/prod/          cmms-prod    P1v3 plan,  atlasprod
```

## Blast radius

This config **creates only `cmms-*` resources**. The resource group, the
`enerkem` registry, the Log Analytics workspace, the PostgreSQL server and the
VNet integration subnet are all read as data sources or passed in by id.

`tofu destroy` here can therefore never touch another team's application, even
though a dozen of them share the same resource group.

Per environment it creates: a user-assigned identity, an App Service Plan, a
Linux web app, a storage account and blob container, a Key Vault, four role
assignments, and a diagnostic setting.

## What must exist first

| Prerequisite | Who | Notes |
|---|---|---|
| State storage account | `infra/bootstrap`, once | see below |
| Database `atlastest` / `atlasprod` | DBA | on the existing flexible server, owned by the `atlas` role |
| VNet integration subnet, one per env | Network team | `/28`, delegated to `Microsoft.Web/serverFarms`, in a VNet with a route to the database |
| Entra app registration | IT | redirect URI `<public_url>/oauth2/callback/microsoft` |
| The four Key Vault secrets | you, after first apply | see *Seed the vault* |

### Why the subnet is not created here

The database has `publicNetworkAccess: Disabled` and is injected into a
delegated subnet, so regional VNet integration is the only route to it. The
subnets for that live in the shared network resource group, which is outside
this config's blast radius by design — so they are created by whoever owns the
network and passed in by id as `VNET_SUBNET_ID_TEST` / `VNET_SUBNET_ID_PROD`.

⚠️ Regional VNet integration requires the subnet's VNet to be **in the same
region as the App Service Plan**. See the open question in DEVELOPMENT-STATUS.md
§11 before creating it — today's database and today's App Service subnets are
in different regions.

## Bootstrap, once

```bash
cd infra/bootstrap
tofu init && tofu apply          # creates enkmtfstate001 + the tfstate container
```

Its own state starts local. Migrate it into the container it just made so it is
not stranded on one laptop:

```bash
cat > backend.tf <<'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "New-Implementations"
    storage_account_name = "enkmtfstate001"
    container_name       = "tfstate"
    key                  = "cmms/bootstrap.tfstate"
    use_azuread_auth     = true
  }
}
EOF
tofu init -migrate-state
```

## Running an environment locally

```bash
cd infra/envs/test
export TF_VAR_public_url="https://cmms-test.azurewebsites.net"
export TF_VAR_vnet_integration_subnet_id="/subscriptions/.../subnets/..."
tofu init
tofu plan
```

The pipeline runs exactly this. Prefer letting it, so state stays consistent —
a local `apply` while a pipeline run is in flight will block on the state lease
rather than corrupt anything, but it still confuses the audit trail.

## Seed the vault

Tofu creates the vault empty and never reads or writes secret values, so
nothing sensitive reaches the state file or the pipeline. The web app resolves
these at runtime as its managed identity. **Do this before the first deploy** —
an unresolved reference stops the container from starting.

```bash
V=enkm-cmms-test        # or enkm-cmms-prod
az keyvault secret set --vault-name $V --name db-password          --value '...'
az keyvault secret set --vault-name $V --name jwt-secret-key       --value "$(openssl rand -base64 48)"
az keyvault secret set --vault-name $V --name oauth2-client-secret --value '...'
az keyvault secret set --vault-name $V --name smtp-password        --value '...'
```

Setting all four is required even when a value is unused — leave it blank
rather than absent. Because references are unversioned, rotating a secret takes
effect on the next app restart with no redeploy.

The vault uses RBAC, so your own account needs **Key Vault Secrets Officer** on
it to run the commands above.

## Permissions the pipeline service principal needs

On the `New-Implementations` resource group:

- **Contributor** — create and manage the resources
- **User Access Administrator** — the four role assignments. Contributor alone
  cannot grant roles, and this is the permission most likely to need a request.
- **Storage Blob Data Contributor** on `enkmtfstate001` — the backend uses
  `use_azuread_auth`, so it reads and writes state as the SPN rather than with
  an account key

## Identity

Each environment gets a **user-assigned** identity, `id-cmms-<env>`, rather
than a system-assigned one. A system-assigned identity only exists once the web
app does, so its role assignments can only be created afterwards — but the app
needs `AcrPull` to pull its first image and Key Vault access to resolve its
first secret. That is a real dependency cycle, and `tofu validate` rejects it.
A separate identity lets every role land first, so a cold apply produces a
working app instead of one that needs a manual restart.

It holds four roles:

| Role | Scope | Why |
|---|---|---|
| `AcrPull` | `enerkem` registry | pull the image |
| `Key Vault Secrets User` | this env's vault | resolve the four settings above |
| `Storage Blob Data Contributor` | this env's storage | read and write attachments |
| `Storage Blob Delegator` | this env's storage | mint the user delegation key that signs download URLs |

Without the last one, uploads succeed and **every download link fails** — the
app can write blobs but not sign a URL for them.

## Storage is deliberately public

`FileMapper` hands the browser a signed URL for every attachment, image and
thumbnail, and the API never proxies the bytes. So the storage account must be
reachable from end-user browsers, not just from the web app. Blobs themselves
stay private: `allow_nested_items_to_be_public = false`, and access is only ever
via a short-lived signature.

Locking this account to the app's subnet would leave every image in the UI
broken.
