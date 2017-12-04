OS                                  := $(shell uname)
COURSE_MATERIAL_DIR                 := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_MATERIAL_NAME                := $(notdir $(COURSE_MATERIAL_DIR))
MKFILES                             := $(shell find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
-include $(MKFILES)

# Initialization Rules {{{1
# Rule to initialize the coursematerial {{{2
.PHONY: init
init: init_files prepare_git

# Rule to initialize files {{{2
init_files:
ifdef COURSE_NAME
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.*sh" \) \
		-exec sed -i.bak 's/COURSE_NAME/$(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.*sh" \) \
		-exec sed -i.bak 's/COURSE_MATERIAL_NAME/$(COURSE_MATERIAL_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's/\(^COURSE_NAME[ ]\{1,\}:=\).*$$/\1 $(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.*sh" \) \
		   -exec bash -c 'mv "$$1" "$${1/COURSE_NAME_COURSE_MATERIAL_NAME_/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_}"' -- {} \;
endif

# Rule to create necessary links {{{2
link_files:
ifdef ZSH_CUSTOM
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name '[^_]*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

# Rule to prepare for git repo initialization {{{2
.PHONY: prepare_git
prepare_git:
	@rm -rf $(COURSE_MATERIAL_DIR)/.git

# Material Rules {{{1
# Variables {{{2
COURSE_MATERIAL_DOCS_DIR            = $(COURSE_MATERIAL_DIR)/docs

# The default folder to publish the materials
PUBLISH_MATERIALS_DIR       = $(COURSE_MATERIAL_DOCS_DIR)/web
PUBLISTH_DOCS_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/pics

# Materials to build
ifdef COURSE_MATERIAL_DOCS_READY
COURSE_MATERIAL_DOCS_TEX            = $(addprefix $(COURSE_MATERIAL_DOCS_DIR)/,$(join $(COURSE_MATERIAL_DOCS_READY),$(addprefix /$(COURSE_MATERIAL_NAME)_,$(addsuffix .tex,$(COURSE_MATERIAL_DOCS_READY)))))
COURSE_MATERIAL_DOCS_PDF            = $(addprefix $(COURSE_MATERIAL_DOCS_DIR)/,$(join $(COURSE_MATERIAL_DOCS_READY),$(addprefix /$(COURSE_MATERIAL_NAME)_,$(addsuffix .pdf,$(COURSE_MATERIAL_DOCS_READY)))))
COURSE_MATERIAL_DOCS_TAR            = $(addprefix $(COURSE_MATERIAL_DOCS_DIR)/,$(join $(COURSE_MATERIAL_DOCS_READY),$(addprefix /$(COURSE_MATERIAL_NAME)_,$(addsuffix .tar.gz,$(COURSE_MATERIAL_DOCS_READY)))))
endif

# Rules to build materials {{{2

# TEX {{{3
define tex_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tex: $$(COURSE_MATERIAL_DOCS_DIR)/%_master.ipynb $$(COURSE_MATERIAL_DOCS_DIR)/$1.tplx
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@cd $$(COURSE_MATERIAL_DOCS_DIR) && jupyter nbconvert \
		--NbConvertApp.output_files_dir='./asset' \
		--Exporter.preprocessors=[\"bibpreprocessor.BibTexPreprocessor\"\,\"pymdpreprocessor.PyMarkdownPreprocessor\"] \
		--to=latex $$(word 1,$$^) --template=$$(word 2,$$^) \
		--output-dir=$$(@D) --output=$$(@F)
	@rsync -av --delete $$(COURSE_MATERIAL_DOCS_DIR)/asset $$(@D)
endef

$(foreach DOC,$(COURSE_MATERIAL_DOCS_READY),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(COURSE_MATERIAL_DOCS_TEX)

# PDF {{{3
define pdf_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.pdf: $$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tex
	@cd $$(COURSE_MATERIAL_DOCS_DIR)/$1 && latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $$<
endef

$(foreach DOC,$(COURSE_MATERIAL_DOCS_READY),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(COURSE_MATERIAL_DOCS_PDF)

# TAR {{{3
define tar_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tar.gz: $$(COURSE_MATERIAL_DOCS_DIR)/$1
	@mkdir -p $$(COURSE_MATERIAL_DOCS_DIR)/tmp)
	@find $$< \
		 -not \( -path '*/\.*' -prune \) \
		 -not \( -name "*.zip" -o -name "*.gz" \) \
		 -type f \
		 -exec rsync -urzL {} $$(COURSE_MATERIAL_DOCS_DIR)/tmp \;

	@cd $$(COURSE_MATERIAL_DOCS_DIR)/tmp; tar -zcvf $$@ *
	@rm -rf $(COURSE_MATERIAL_DOCS_DIR)/tmp
endef

$(foreach DOC,$(COURSE_MATERIAL_DOCS_READY),$(eval $(call tar_rules,$(DOC))))

.PHONY: build_tar
build_tar: $(COURSE_MATERIAL_DOCS_TAR)

# ALL {{{3
.PHONY: build_materials
build_materials: build_pdf

# Rule to publish materials {{{2

# TEX {{{3
.PHONY: publish_tex
publish_tex: $(COURSE_MATERIAL_DOCS_TEX)
	@rsync -urzL $(COURSE_MATERIAL_DOCS_TEX) $(COURSE_MATERIAL_DOCS_SUBDIR)

# PDF {{{3
.PHONY: publish_pdf
publish_pdf: $(COURSE_MATERIAL_DOCS_PDF)
	@rsync -urzL $(COURSE_MATERIAL_DOCS_PDF) $(COURSE_MATERIAL_DOCS_SUBDIR)

# TAR {{{3
.PHONY: publish_tar
publish_tar: $(COURSE_MATERIAL_DOCS_TAR)
	@rsync -urzL $(COURSE_MATERIAL_DOCS_TAR) $(COURSE_MATERIAL_DOCS_SUBDIR)

.PHONY : publish_materials
publish_materials: publish_pdf

# Rule to clean materials {{{2

# TEX {{{3
.PHONY: clean_tex
clean_tex:
	@rm -rf $(COURSE_MATERIAL_DOCS_TEX)

# PDF {{{3
.PHONY : clean_pdf
clean_pdf:
	@$(foreach DOC,$(COURSE_MATERIAL_DOCS_READY),\
		cd $(COURSE_MATERIAL_DOCS_DIR)/$(DOC); \
		latexmk -silent -C; \
		rm -rf *.run.xml *.synctex.gz *.d *.bbl;)

# TAR {{{3
.PHONY : clean_tar
clean_tar:
	@rm -rf $(COURSE_MATERIAL_DOCS_TAR)

# ALL {{{3
.PHONY: clean_materials
clean_materials: clean_pdf


# Git Rules {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_DIR                       := $(COURSE_MATERIAL_DIR)/github
GITHUB_USER                       := $(shell git config --global --includes github.user)
GITHUB_ORG                       := $(shell git config --global --includes github.org)
GITHUB_TOKEN                     := :$(shell git config --global --includes github.token)
GITHUB_API_URL                   := https://api.github.com/orgs/$(GITHUB_ORG)/repos
GITHUB_REPO_URL                  := git@github.com:$(GITHUB_ORG)/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo.git

CURRENT_BRANCH                   := $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

# Rule to create the github repo for couse assignment {{{2
.PHONY : github_mk
github_mk:
ifdef GITHUB_ORG
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo", "private" : false }'
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^COURSE_MATERIAL_REPO[ ]\{1,\}:=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(COURSE_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@git submodule add $(GITHUB_REPO_URL) $(GITHUB_DIR)
	@git submodule update --init
endif
endif

# Debug Rules {{{1
# Rule to print makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
