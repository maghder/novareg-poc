# Module d'extraction — prototype (hors intégration frontend pour l'instant)

Valide l'approche PDF natif / OCR + regex + NER sur de vrais documents,
avant toute intégration dans l'écran d'indexation. Aucune dépendance
externe : tout tourne localement dans le Codespace (CPU, sans clé API).

## Installation (une fois)

```bash
sudo apt-get update && sudo apt-get install -y tesseract-ocr tesseract-ocr-fra poppler-utils

cd extraction
pip install -r requirements.txt --break-system-packages
python -m spacy download fr_core_news_sm
cd ..
```

## Utilisation

1. Déposez un ou plusieurs PDF (scans réels si possible — c'est ce qu'on
   veut évaluer) dans `extraction/echantillons/` — glisser-déposer dans
   l'explorateur du Codespace, comme pour l'archive au tout début.

2. Lancez l'extraction :
```bash
   cd extraction
   python extract.py echantillons/votre_fichier.pdf
```
   Affiche un résumé JSON : méthode utilisée (`natif` ou `ocr`), et les
   champs proposés (objet, date, référence, candidats expéditeur).

3. Pour garder le résultat complet (texte brut inclus) :
```bash
   python extract.py echantillons/votre_fichier.pdf --json resultat.json
```

## Ce qu'il faut regarder en évaluant les résultats

- **`methode_extraction`** : `natif` = calque texte déjà présent dans le
  PDF (rapide, fiable). `ocr` = image scannée, passée par Tesseract
  (qualité dépendante du scan — voir la discussion sur PaperStream).
- **`objet`** : ne fonctionne que si le courrier contient littéralement le
  mot "Objet" — sinon `null`, à corriger manuellement dans l'écran
  d'indexation.
- **`expediteur_candidats`** : liste de noms d'organisations détectés,
  classés par fréquence d'apparition — pas forcément dans le bon ordre,
  l'agent choisit/corrige.
- **`reference_externe`** : cherche les conventions "N/Réf", "V/Réf",
  "Référence" — fréquent dans le courrier administratif, mais pas
  universel.

Rien de tout ça n'est branché à Directus ou au frontend pour l'instant —
c'est volontairement un test isolé, pour juger si la précision est
suffisante avant d'investir dans l'intégration complète (upload,
pré-remplissage du formulaire, `bo_extractions_ia`).
