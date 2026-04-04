---
description: LaTeX Build and Management
---

This workflow provides commands to compile and manage LaTeX documents.

### Build (Japanese/LuaLaTeX)
Use this for Japanese documents or modern LaTeX projects.
// turbo
1. Compile the document with LuaLaTeX:
   `lualatex -synctex=1 -interaction=nonstopmode -file-line-error [filename].tex`

### Build (English/pdfLaTeX)
Use this for traditional English documents.
// turbo
1. Compile the document with pdfLaTeX:
   `pdflatex -synctex=1 -interaction=nonstopmode -file-line-error [filename].tex`

### Clean
Removes auxiliary files created during compilation.
// turbo
1. Clean auxiliary files:
   `rm -f *.aux *.log *.out *.toc *.synctex.gz *.fls *.fdb_latexmk`
