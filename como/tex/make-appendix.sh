#!/bin/sh

date

echo "MAKE: FIRST LATEX RUN"
pdflatex appendix.tex

echo "MAKE: RUNNING BIBTEX"
bibtex appendix.aux

# now two pdflatex to include references
echo "MAKE: 2ND LATEX RUN"
pdflatex appendix.tex

echo "MAKE: 3RD LATEX RUN"
pdflatex appendix.tex

cp appendix.pdf ~/public_html/pdf
