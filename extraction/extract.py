#!/usr/bin/env python3
"""
extract.py — Prototype d'extraction de métadonnées à partir d'un PDF
(natif ou scanné), pour valider l'approche OCR + regex + NER avant toute
intégration dans le frontend.

Usage :
    python extract.py echantillons/mon_fichier.pdf
    python extract.py echantillons/mon_fichier.pdf --json resultat.json
"""

import argparse
import json
import re
import sys
from pathlib import Path

import pdfplumber
import pytesseract
from pdf2image import convert_from_path

try:
    import spacy
except ImportError:
    spacy = None

_NLP = None

MOIS_FR = (
    "janvier|février|mars|avril|mai|juin|juillet|"
    "août|septembre|octobre|novembre|décembre"
)

RE_DATE_NUM = re.compile(r"\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b")
RE_DATE_LETTRES = re.compile(rf"\b(\d{{1,2}})\s+({MOIS_FR})\s+(\d{{4}})\b", re.IGNORECASE)
RE_OBJET = re.compile(r"objet\s*:?\s*(.+)", re.IGNORECASE)
# Couvre les conventions courantes du courrier administratif français :
# "N/Réf", "V/Réf", "Référence", "Réf." — avec ou sans point/deux-points.
RE_REFERENCE = re.compile(
    r"(?:n\s*/\s*r[ée]f|v\s*/\s*r[ée]f|r[ée]f[ée]rence|r[ée]f)\.?\s*:?\s*"
    r"([A-Za-z0-9][A-Za-z0-9\-/._]{2,})",
    re.IGNORECASE,
)

SEUIL_TEXTE_NATIF = 40  # caractères ; en dessous, on considère qu'il faut l'OCR


def charger_nlp():
    """Charge le modèle spaCy français une seule fois (coûteux à charger)."""
    global _NLP
    if spacy is None:
        return None
    if _NLP is None:
        try:
            _NLP = spacy.load("fr_core_news_sm")
        except OSError:
            print(
                "! Modèle spaCy fr_core_news_sm introuvable — lancez :\n"
                "  python -m spacy download fr_core_news_sm",
                file=sys.stderr,
            )
            _NLP = False
    return _NLP or None


def texte_natif(chemin_pdf):
    """Texte déjà présent dans le PDF (calque numérique, pas un scan)."""
    morceaux = []
    with pdfplumber.open(chemin_pdf) as pdf:
        for page in pdf.pages:
            morceaux.append(page.extract_text() or "")
    return "\n".join(morceaux).strip()


def texte_par_ocr(chemin_pdf):
    """Convertit chaque page en image puis lance Tesseract en français."""
    images = convert_from_path(chemin_pdf, dpi=300)
    morceaux = [pytesseract.image_to_string(img, lang="fra") for img in images]
    return "\n".join(morceaux).strip()


def extraire_texte(chemin_pdf):
    texte = texte_natif(chemin_pdf)
    if len(texte) >= SEUIL_TEXTE_NATIF:
        return texte, "natif"
    return texte_par_ocr(chemin_pdf), "ocr"


def extraire_date(texte):
    m = RE_DATE_NUM.search(texte)
    if m:
        return f"{m.group(1).zfill(2)}/{m.group(2).zfill(2)}/{m.group(3)}"
    m = RE_DATE_LETTRES.search(texte)
    return m.group(0) if m else None


def extraire_objet(texte):
    m = RE_OBJET.search(texte)
    if not m:
        return None
    ligne = m.group(1).split("\n")[0].strip()
    return ligne[:500] or None


def extraire_reference(texte):
    m = RE_REFERENCE.search(texte)
    return m.group(1).strip() if m else None


def extraire_organisations(texte, max_candidats=5):
    nlp = charger_nlp()
    if nlp is None:
        return []
    doc = nlp(texte[:20000])  # limite raisonnable pour la vitesse en CPU
    comptes = {}
    for ent in doc.ents:
        if ent.label_ == "ORG":
            comptes[ent.text] = comptes.get(ent.text, 0) + 1
    classement = sorted(comptes.items(), key=lambda kv: -kv[1])
    return [nom for nom, _ in classement[:max_candidats]]


def extraire(chemin_pdf):
    texte, methode = extraire_texte(chemin_pdf)
    return {
        "fichier": str(chemin_pdf),
        "methode_extraction": methode,
        "longueur_texte": len(texte),
        "champs_proposes": {
            "objet": extraire_objet(texte),
            "date_document": extraire_date(texte),
            "reference_externe": extraire_reference(texte),
            "expediteur_candidats": extraire_organisations(texte),
        },
        "texte_brut": texte,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path, help="Chemin du PDF à analyser")
    parser.add_argument("--json", type=Path, help="Fichier de sortie JSON (optionnel)")
    args = parser.parse_args()

    if not args.pdf.exists():
        print(f"Fichier introuvable : {args.pdf}", file=sys.stderr)
        sys.exit(1)

    resultat = extraire(args.pdf)

    apercu = dict(resultat)
    if len(resultat["texte_brut"]) > 300:
        apercu["texte_brut"] = resultat["texte_brut"][:300] + "…"
    print(json.dumps(apercu, indent=2, ensure_ascii=False))

    if args.json:
        args.json.write_text(json.dumps(resultat, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\nRésultat complet écrit dans {args.json}")


if __name__ == "__main__":
    main()
