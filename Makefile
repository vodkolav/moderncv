OUT_DIR=output
IN_DIR=markdown
STYLES_DIR="."
STYLE=moderncv

all: tex pdf html docx rtf


tex: init
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.tex; \
		pandoc --standalone --template $(STYLES_DIR)/$(STYLE).tex \
			--lua-filter=pandoc-filters/moderncv.lua \
			--from markdown --to latex \
			--output $(OUT_DIR)/$$FILE_NAME.tex $$f > dbg_lua.log; \
	done


pdf: tex
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo cooking $$FILE_NAME.pdf; \
		pdflatex -interaction=nonstopmode -halt-on-error \
				 -output-directory=$(OUT_DIR) $(OUT_DIR)/$$FILE_NAME.tex >> pdflatex.log; \
	done

html: init
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.html; \
		pandoc --standalone --include-in-header $(STYLES_DIR)/$(STYLE).css \
			--lua-filter=pdc-links-target-blank.lua \
			--from markdown --to html \
			--output $(OUT_DIR)/$$FILE_NAME.html $$f \
			--metadata pagetitle=$$FILE_NAME;\
	done

docx: init
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.docx; \
		pandoc --standalone $$SMART $$f \
		--output $(OUT_DIR)/$$FILE_NAME.docx; \
	done

docx_t: init #docx with template
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.docx; \
		pandoc --standalone $$SMART $$f \
		--reference-doc=templates/reference.docx\
		--template=templates/template.openxml \
		--output $(OUT_DIR)/$$FILE_NAME.docx; \
	done

json: tex
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.json; \
		pandoc --standalone $$SMART $$f \
		-t json \
		--output $(OUT_DIR)/$$FILE_NAME.json; \
	done

rtf: init
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.rtf; \
		pandoc --standalone $$SMART $$f --output $(OUT_DIR)/$$FILE_NAME.rtf; \
	done

init: dir version

dir:
	mkdir -p $(OUT_DIR)

version:
	PANDOC_VERSION=`pandoc --version | head -1 | cut -d' ' -f2 | cut -d'.' -f1`; \
	if [ "$$PANDOC_VERSION" -eq "2" ]; then \
		SMART=-smart; \
	else \
		SMART=--smart; \
	fi \

clean:
	rm -f $(OUT_DIR)/*
