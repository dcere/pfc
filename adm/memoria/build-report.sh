#!/bin/bash
ARCHIVO=ppal
FLAGS="-shell-escape"

./clean.sh

pdflatex $FLAGS   $ARCHIVO
bibtex            $ARCHIVO
pdflatex $FLAGS   $ARCHIVO
pdflatex $FLAGS   $ARCHIVO
