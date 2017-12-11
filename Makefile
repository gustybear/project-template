OS                                 = $(shell uname)
COURSE_MATERIAL_DIR                = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_MATERIAL_NAME               = $(notdir $(COURSE_MATERIAL_DIR))
MKFILES                            = $(shell find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
-include $(MKFILES)

# Initialization Rules {{{1
# Rule to initialize the course material {{{2
.PHONY: init
init: init_files prepare_git

# Rule to initialize files {{{2
init_files:
ifdef COURSE_NAME
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.zsh" \) \
		-exec sed -i.bak 's/COURSE_NAME/$(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.zsh" \) \
		-exec sed -i.bak 's/COURSE_MATERIAL_NAME/$(COURSE_MATERIAL_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's/\(^COURSE_NAME[ ]\{1,\}=\).*$$/\1 $(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.zsh" \) \
		   -exec bash -c 'mv "$$1" "$${1/COURSE_NAME_COURSE_MATERIAL_NAME_/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_}"' -- {} \;
endif

# Rule to create necessary links {{{2
link_files:
ifdef ZSH_CUSTOM
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name '$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

# Rule to prepare for git repo initialization {{{2
define GITIGNORE
# Default gitignore for course
public/s3/*
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(COURSE_DIR)/.git
	@echo "$$GITIGNORE" > $(COURSE_DIR)/.gitignore


# Documents Rules {{{1
# Variables {{{2
COURSE_MATERIAL_DOCS_DIR   = $(COURSE_MATERIAL_DIR)/docs
# s3 parameters
# S3_PUBLISH_SRC will be set by course makefile to speed up upload
S3_PUBLISH_SRC             =

# github parameters
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GIT_PUBLISH_SRC            = $(COURSE_MATERIAL_DIR)/public/github
GITHUB_ORG                 =

GITHUB_USER                = $(shell git config --global --includes github.user)
GITHUB_TOKEN               = :$(shell git config --global --includes github.token)
GITHUB_API_URL             = https://api.github.com/orgs/$(GITHUB_ORG)/repos
GITHUB_REPO_URL            = git@github.com:$(GITHUB_ORG)/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo.git

CURRENT_BRANCH             = $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT             = $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

doc_path                   = $(foreach EXT,$(3),$(foreach FILE,$(addprefix $(1),$(join $(2),$(addprefix /$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_,$(2)))),$(FILE)*.$(EXT)))

# Documents to build
ifdef DOCS_TO_COMPILE
TEX_TO_COMPILE              = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(DOCS_TO_COMPILE),tex ipynb)
PDF_TO_COMPILE              = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(DOCS_TO_COMPILE),pdf)
TAR_TO_COMPILE              = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(DOCS_TO_COMPILE),tar.gz)
endif

# Rules to build Documents {{{2
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

$(foreach DOC,$(DOCS_TO_COMPILE),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(TEX_TO_COMPILE)

# PDF {{{3
define pdf_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.pdf: $$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tex
	@cd $$(COURSE_MATERIAL_DOCS_DIR)/$1 && latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $$<
endef

$(foreach DOC,$(DOCS_TO_COMPILE),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(PDF_TO_COMPILE)

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

$(foreach DOC,$(DOCS_TO_COMPILE),$(eval $(call tar_rules,$(DOC))))

.PHONY: build_tar
build_tar: $(TAR_TO_COMPILE)

# ALL {{{3
.PHONY: build_documents
build_documents: build_tex build_pdf build_tar

# Rule to publish documents {{{2
# S3 {{{3
.PHONY: publish_s3
publish_s3:
ifdef S3_PUBLISH_SRC
ifdef EXTS_TO_PUB_VIA_S3
	@test -d $(S3_PUBLISH_SRC) || mkdir -p $(S3_PUBLISH_SRC)
	@cd $(COURSE_MATERIAL_DIR) && rsync -urzL --relative $(call doc_path,docs/,$(DOCS_TO_COMPILE),$(EXTS_TO_PUB_VIA_S3)) $(S3_PUBLISH_SRC)
endif
endif

# GITHUB {{{3
#
# Rule to create the github repo for couse assignment
.PHONY : github_mk
github_mk:
ifdef GITHUB_ORG
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo", "private" : false }'
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^COURSE_MATERIAL_REPO[ ]\{1,\}=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \;
endif
endif

# Rule to publish via github
.PHONY: publish_github
publish_github:
ifdef EXTS_TO_PUB_VIA_GIT
	@if ! git ls-remote -h "$(GITHUB_REPO_URL)" &>-; then \
		echo "run github_mk to generate the github repo first"; \
		exit 1; \
	fi
	@if [ ! -d $(GIT_PUBLISH_SRC) ]; then \
		cd $(COURSE_MATERIAL_DIR); \
		git submodule add $(GITHUB_REPO_URL) public/github; \
		git submodule update --init; \
	else \
		cd $(GIT_PUBLISH_SRC); \
		git pull; \
		cd $(COURSE_MATERIAL_DIR); \
		rsync -urzL --relative $(call doc_path,docs/,$(DOCS_TO_COMPILE),$(EXTS_TO_PUB_VIA_GIT)) $(GIT_PUBLISH_SRC); \
		cd $(GIT_PUBLISH_SRC); \
      		if ! git diff-index --quiet HEAD --; then \
			git add -A ; \
                        LANG=C git -c color.status=false status \
                        | sed -n -e '1,/Changes to be committed:/ d' \
				      -e '1,1 d' \
				      -e '/^Untracked files:/,$ d' \
				      -e 's/^\s*//' \
				      -e '/./p' \
				      > msg.txt; \
			git commit -F msg.txt ;\
			rm -rf msg.txt; \
			git push; \
		fi \
	fi
	# to remove the submodule run:
	# git submodule deinit <asubmodule>
        # git rm <asubmodule>
        # Note: asubmodule (no trailing slash)
        # or, if you want to leave it in your working tree
        # git rm --cached <asubmodule>
        # rm -rf .git/modules/<asubmodule>
endif

# ALL {{{3
.PHONY : publish_documents
publish_documents: publish_s3 publish_github

# Rule to clean documents {{{2
# TEX {{{3
.PHONY: clean_tex
clean_tex:
	@rm -rf $(TEX_TO_COMPILE)

# PDF {{{3
.PHONY : clean_pdf
clean_pdf:
	@$(foreach DOC,$(DOCS_TO_COMPILE),\
		cd $(COURSE_MATERIAL_DOCS_DIR)/$(DOC); \
		latexmk -silent -C; \
		rm -rf *.run.xml *.synctex.gz *.d *.bbl;)

# TAR {{{3
.PHONY : clean_tar
clean_tar:
	@rm -rf $(TAR_TO_COMPILE)

# ALL {{{3
.PHONY: clean_documents
clean_documents: clean_tex clean_pdf clean_tar


# Debug Rules {{{1
# Rule to print makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
