#!/bin/bash
ARCHIVO=ppal

./clean.sh

pdflatex $ARCHIVO
bibtex   $ARCHIVO
pdflatex $ARCHIVO
pdflatex $ARCHIVO
