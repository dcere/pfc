#!/bin/bash
ARCHIVO=cover
FLAGS="-shell-escape"

./clean.sh

pdflatex $FLAGS   $ARCHIVO
