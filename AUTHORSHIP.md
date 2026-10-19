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

## 2. Empreintes (état au 19 octobre 2026)

| Objet | Empreinte |
|---|---|
| `HEAD` de la branche | `014c618cc78bbc9cf07579ee1e66327760bdecd6` |
| Arbre Git (`tree`) | `d9f6a33e8dbd8fa633fe7f747a9f9c69bf9a8492` |
| Manifeste des commits (SHA-256) | `88297167b971ea4ec0d91acc7bde88a945310834ed3215bf61b34a404a101def` |
| Bundle Git `fokomaximejoel.bundle` (SHA-256) | `1d0bda443b4523cc21226704f34f0c4ceddefe4084d2bd77a88f8ac57fbfae79` |
| Étiquette annotée | `empreinte-maxime-v1` |

> **Point de référence** : l'étiquette annotée `empreinte-maxime-v1` pointe sur le commit
> `014c618`. Les empreintes ci-dessus décrivent exactement cet état : c'est cette étiquette —
> et non la tête de branche, qui avance à chaque commit — qu'un tiers doit vérifier.

> Le bundle (`authorship/fokomaximejoel.bundle`, 7,6 Mo) **n'est pas versionné** : il doit être
> conservé hors du dépôt (courriel à soi-même, cloud personnel, clé USB). C'est cette copie qui
> protège contre la réécriture de l'historique.

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
