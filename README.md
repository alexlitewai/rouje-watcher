# rouje-watcher

Surveillance du retour en stock de la **Robe GABIN** (Rouje) en taille **36 ou 38**,
avec notification push via [ntfy.sh](https://ntfy.sh).

Backup cloud du watcher local (launchd sur Mac) : couvre les heures où le Mac est
fermé ou éteint. Détection en ~4 minutes via GitHub Actions.

## Fonctionnement

- `check_rouje.sh` lit l'endpoint JSON Shopify du produit (`<url>.js`) et envoie un
  push ntfy si la 36 ou la 38 est disponible (une seule fois par retour en stock,
  état persisté dans `state.txt`).
- `.github/workflows/watch.yml` : le cron GitHub étant throttlé, chaque job boucle
  ~5h30 (un check toutes les ~4 min) et le suivant s'enchaîne via le groupe de
  concurrence.

## Configuration

Secret GitHub requis (Settings → Secrets and variables → Actions) :

| Nom | Valeur |
|---|---|
| `NTFY_TOPIC` | le sujet ntfy auquel le téléphone est abonné |

Ajouter un produit = ajouter une ligne `handle|Nom` dans le tableau `PRODUCTS`
de `check_rouje.sh`.
