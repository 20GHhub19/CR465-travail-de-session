# Empreinte d'auteur

> Ce document rend vérifiable, par un tiers et sans faire confiance au dépôt, qui a produit quoi
> et à quel moment. Il complète `CODEOWNERS` (propriété déclarée) par une preuve technique.

## 1. Auteur

| Élément | Valeur |
|---|---|
| Pseudo Git | `fokomaximejoel` |
| Nom | Maxime |
| Branche | `Projet-CR465-D-Maxime` |
| Commits | **24** |
| Fichiers distincts touchés | **77** |
| Verticales | architecture, sécurité, base de données, identité, SSO, intégrations, livrables |

## 2. Empreintes

Les valeurs courantes sont générées automatiquement dans **`authorship/empreintes.txt`** par
`scripts/authorship-manifest.sh`, exécuté sur l'étiquette (et non sur la tête de branche, qui
avance à chaque commit) :

```bash
./scripts/authorship-manifest.sh fokomaximejoel empreinte-maxime-v2
```

| Objet | Rôle |
|---|---|
| Étiquette `empreinte-maxime-v2` | Point de référence signé (SSH) sur l'état décrit |
| `authorship/fokomaximejoel-commits.txt` | Liste des commits de l'auteur avec SHA et date |
| `authorship/empreintes.txt` | SHA-256 du manifeste et du bundle |
| `authorship/fokomaximejoel.bundle` | Historique complet, **conservé hors du dépôt** |

## 2 bis. Signatures

Depuis la réécriture du 19 octobre 2026, **les 26 commits de l'auteur sont signés en SSH**
(`gpg.format = ssh`, clé `~/.ssh/id_ed25519_cr465_signing`). Vérification locale :

```bash
git log --format='%h %G? %s' --author=fokomaximejoel   # G = signature valide
```

Les commits des autres membres n'ont pas été réécrits : leurs SHA sont inchangés.

## 3. Vérification par un tiers

```bash
# 1. Le bundle est intact
shasum -a 256 authorship/fokomaximejoel.bundle
# → doit afficher 1d0bda44...fbfae79

# 2. Le bundle contient un historique cohérent
git bundle verify authorship/fokomaximejoel.bundle

# 3. Les commits de l'auteur sont présents et identiques
git clone authorship/fokomaximejoel.bundle verif/
cd verif && git log --author=fokomaximejoel --oneline | wc -l
# → doit afficher 24
```

Si l'empreinte du bundle correspond et que `git log` renvoie les mêmes SHA, alors l'historique
n'a pas été modifié — quelle que soit l'état du dépôt en ligne.

## 4. Régénérer l'empreinte

```bash
./scripts/authorship-manifest.sh fokomaximejoel Projet-CR465-D-Maxime
```

Puis reporter les nouvelles valeurs dans ce fichier et consigner le bloc hors du dépôt.

## 5. Ce que cela garantit — et ce que cela ne garantit pas

| Garantit | Ne garantit pas |
|---|---|
| Chaque commit porte une identité et un contenu dont le SHA est fixé | Qu'un propriétaire du dépôt ne puisse pas supprimer la branche |
| Le bundle permet de reconstruire l'historique complet hors ligne | Qu'un tiers ne puisse pas produire un autre historique |
| Toute altération change les SHA-256 | L'identité légale derrière un pseudo |

**L'ancrage réel est externe** : un courriel daté, un GitBook publié, un dépôt miroir sous un
autre compte. C'est pour cela que le bloc d'empreintes doit sortir du dépôt.
