OS                                 = $(shell uname)
COURSE_NAME                        = COURSE_NAME
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

# Rule to create necessary links {{{2
link_files:
ifdef ZSH_CUSTOM
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name '$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

# Rule to prepare for git repo initialization {{{2
define GITIGNORE
# Default gitignore for course materials
public/*
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(COURSE_MATERIAL_DIR)/.git
	@echo "$$GITIGNORE" > $(COURSE_MATERIAL_DIR)/.gitignore


# Documents Rules {{{1
# Variables {{{2
COURSE_MATERIAL_DOCS_DIR   = $(COURSE_MATERIAL_DIR)/docs

doc_path                   = $(foreach EXT,$(3),$(foreach FILE,$(addprefix $(1),$(join $(2),$(addprefix /$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_,$(2)))),$(FILE).$(EXT)))


# Rules to build Documents {{{2
# TEX {{{3
ifdef TEX_TO_COMPILE
TEX_FILES                   = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(TEX_TO_COMPILE),tex)
endif

define tex_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tex: $$(COURSE_MATERIAL_DOCS_DIR)/%_master.ipynb $$(COURSE_MATERIAL_DOCS_DIR)/$1.tplx
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@if [ -d $$(COURSE_MATERIAL_DOCS_DIR)/asset ]; then rm -rf $$(COURSE_MATERIAL_DOCS_DIR)/asset/*; fi
	@cd $$(COURSE_MATERIAL_DOCS_DIR) && jupyter nbconvert \
		--NbConvertApp.output_files_dir='./asset' \
		--Exporter.preprocessors=[\"bibpreprocessor.BibTexPreprocessor\"\,\"pymdpreprocessor.PyMarkdownPreprocessor\"] \
		--to=latex $$(word 1,$$^) --template=$$(word 2,$$^) \
		--output-dir=$$(@D) --output=$$(@F)
	@rsync -av --delete $$(COURSE_MATERIAL_DOCS_DIR)/asset $$(@D)
endef

$(foreach DOC,$(TEX_TO_COMPILE),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(TEX_FILES)

# PDF {{{3
ifdef PDF_TO_COMPILE
PDF_FILES                   = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(PDF_TO_COMPILE),pdf)
endif

define pdf_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.pdf: $$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tex
	@cd $$(COURSE_MATERIAL_DOCS_DIR)/$1 && latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $$<
	@cd $$(COURSE_MATERIAL_DOCS_DIR)/$1 && latexmk -c
endef

$(foreach DOC,$(PDF_TO_COMPILE),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(PDF_FILES)

# TAR {{{3
ifdef TAR_TO_COMPILE
TAR_FILES                   = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(TAR_TO_COMPILE),tar.gz)
endif

define tar_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.tar.gz: $$(COURSE_MATERIAL_DOCS_DIR)/$1
	@mkdir -p $$(COURSE_MATERIAL_DOCS_DIR)/tmp)
	@find $$< \
		 -not \( -path '*/\.*' -prune \) \
		 -not \( -name "*.zip" -o -name "*.gz" \) \
		 -type f \
		 -exec rsync -urzL {} $$(COURSE_MATERIAL_DOCS_DIR)/tmp \;

	@cd $$(COURSE_MATERIAL_DOCS_DIR)/tmp; tar -zcvf $$@ *
	@rm -rf $$(COURSE_MATERIAL_DOCS_DIR)/tmp
endef

$(foreach DOC,$(TAR_TO_COMPILE),$(eval $(call tar_rules,$(DOC))))

.PHONY: build_tar
build_tar: $(TAR_FILES)

# MARAKDOWN {{{3
ifdef MD_TO_COMPILE
MD_FILES                   = $(call doc_path,$(COURSE_MATERIAL_DOCS_DIR)/,$(MD_TO_COMPILE),md)
endif

define md_rules
$$(COURSE_MATERIAL_DOCS_DIR)/$1/%_$1.md: $$(COURSE_MATERIAL_DOCS_DIR)/%_master.ipynb $$(COURSE_MATERIAL_DOCS_DIR)/$1.tplx
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@if [ -d $$(COURSE_MATERIAL_DOCS_DIR)/asset ]; then rm -rf $$(COURSE_MATERIAL_DOCS_DIR)/asset/*; fi
	@cd $$(COURSE_MATERIAL_DOCS_DIR) && jupyter nbconvert \
		--NbConvertApp.output_files_dir='./asset' \
		--to=markdown $$(word 1,$$^) --template=$$(word 2,$$^) \
		--output-dir=$$(@D) --output=$$(@F)
	@rsync -av --delete $$(COURSE_MATERIAL_DOCS_DIR)/asset $$(@D)
endef

$(foreach DOC,$(MD_TO_COMPILE),$(eval $(call md_rules,$(DOC))))

.PHONY: build_md
build_md: $(MD_FILES)

# ALL {{{3
.PHONY: build_documents
build_documents: build_tex build_pdf build_tar

# Rule to clean documents {{{2
# TEX {{{3
.PHONY: clean_tex
clean_tex:
ifdef TEX_FILES
	@rm -rf $(TEX_FILES)
	@rm -rf $(addsuffix asset/*,$(dir $(TEX_FILES)))
endif

# PDF {{{3
.PHONY : clean_pdf
clean_pdf:
ifdef PDF_FILES
	@rm -rf $(PDF_FILES)
endif

# TAR {{{3
.PHONY : clean_tar
clean_tar:
ifdef TAR_FILES
	@rm -rf $(TAR_FILES)
endif

# MARKDOWN {{{3
.PHONY: clean_md
clean_md:
ifdef MD_FILES
	@rm -rf $(MD_FILES)
	@rm -rf $(addsuffix asset/*,$(dir $(MD_FILES)))
endif
# ALL {{{3
.PHONY: clean_documents
clean_documents: clean_tex clean_pdf clean_tar clean_md


# Codes Rules {{{1
# Variables {{{2
COURSE_MATERIAL_CODES_DIR   = $(COURSE_MATERIAL_DIR)/codes


# Data Rules {{{1
# Variables {{{2
COURSE_MATERIAL_DATA_DIR    = $(COURSE_MATERIAL_DIR)/data
ARCHIVE_DATA_DIR            = $(COURSE_MATERIAL_DATA_DIR)/archive
CURRENT_DATA_DIR            = $(COURSE_MATERIAL_DATA_DIR)/current

S3_DATA_BUCKET              = s3://gustybear-teaching

# Rule to initialize the data directory {{{2
.PHONY : data_init
data_init:
	@if [ ! -d $(CURRENT_DATA_DIR) && ! -L $(CURRENT_DATA_DIR) ]; then \
		mkdir -p $(CURRENT_DATA_DIR)
	fi
	@if [ ! -d $(ARCHIVE_DATA_DIR) && ! -L $(ARCHIVE_DATA_DIR) ]; then \
		mkdir -p $(ARCHIVE_DATA_DIR)
	fi

# Rule to create archive {{{2
.PHONY : archive_mk
archive_mk:
	@echo "Creating archive file: $(TIMESTAMP).tar.gz."
	@mkdir -p $(ARCHIVE_DATA_DIR)/$(TIMESTAMP)
	@rsync -av --copy-links  $(CURRENT_DATA_DIR)/ $(ARCHIVE_DATA_DIR)/$(TIMESTAMP)
	@tar -zcvf $(ARCHIVE_DATA_DIR)/$(TIMESTAMP).tar.gz -C $(ARCHIVE_DATA_DIR) ./$(TIMESTAMP)
	@rm -rf $(ARCHIVE_DATA_DIR)/$(TIMESTAMP)
	@aws s3 cp $(ARCHIVE_DATA_DIR)/$(TIMESTAMP).tar.gz $(S3_DATA_BUCKET)/$(COURSE_NAME)/data/$(TIMESTAMP).tar.gz

# Rule to list objects in S3 {{{2
.PHONY : s3_ls
s3_ls:
	@aws s3 ls --recursive --human-readable $(S3_DATA_BUCKET)/$(COURSE_NAME)/$(COURSE_MATERIAL_NAME)/data/

# Publish Rules {{{1
# Variables {{{2
COURSE_MATERIAL_PUB_DIR    = $(COURSE_MATERIAL_DIR)/public
# s3 parameters
# S3_PUBLISH_SRC will be set by course makefile to speed up upload
S3_PUBLISH_SRC             = $(COURSE_MATERIAL_PUB_DIR)/s3
S3_PUBLISH_DES             = s3://gustybear-websites

# github parameters
GITHUB_PUBLISH_SRC         = $(COURSE_MATERIAL_PUB_DIR)/github

GITHUB_API_URL             = https://api.github.com/orgs/$(GITHUB_ORG)/repos
GITHUB_REPO_URL            = git@github.com:$(GITHUB_ORG)/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo.git
# # Run 'git config --global github.user <username>' to set username.
# # Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                = $(shell git config --global --includes github.user)
GITHUB_TOKEN               = :$(shell git config --global --includes github.token)

CURRENT_BRANCH             = $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT             = $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

# Rule to publish via S3 {{{2
.PHONY: publish_s3
publish_s3:
	@test -d $(S3_PUBLISH_SRC) || mkdir -p $(S3_PUBLISH_SRC)
ifdef DOCS_TO_PUB_VIA_S3
	-cd $(COURSE_MATERIAL_DIR) && rsync -rzL --relative $(addprefix docs/,$(DOCS_TO_PUB_VIA_S3)) $(S3_PUBLISH_SRC)
endif
ifdef CODES_TO_PUB_VIA_S3
	-cd $(COURSE_MATERIAL_DIR) && rsync -rzL --relative $(addprefix codes/,$(CODES_TO_PUB_VIA_S3)) $(S3_PUBLISH_SRC)
endif

ifdef DATA_TO_PUB_VIA_S3
	-for data in $(DATA_TO_PUB_VIA_S3); \
	do \
	(aws s3 cp $(addprefix $(S3_DATA_BUCKET)/$(COURSE_NAME)/data/,$$data) \
		$(addprefix $(S3_PUBLISH_DES)/$(COURSE_NAME)/data/,$$data)) \
	done
endif

# Rule to publish via GITHUB {{{2
.PHONY: publish_github
publish_github:
ifdef GITHUB_USER
ifdef GITHUB_ORG
ifneq ($(DOCS_TO_PUB_VIA_GIT)$(CODES_TO_PUB_VIA_GIT)$(DOCS_TO_PUB_VIA_GIT),)
	@if ! git ls-remote -h "$(GITHUB_REPO_URL)" >&-; then \
		echo "Creating $(GITHUB_REPO_URL)"; \
		curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
			$(GITHUB_API_URL) \
			-d '{ "name" : "$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo", "private" : false }'; \
		find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
			-exec sed -i.bak 's|\(^COURSE_MATERIAL_REPO[ ]\{1,\}=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \; ; \
		find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \; ; \
		mkdir -p $(GITHUB_PUBLISH_SRC); \
		cd $(GITHUB_PUBLISH_SRC); \
		echo "# $(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo" >> README.md; \
		git init; \
		git add README.md; \
		git commit -m "first commit"; \
		git remote add origin $(GITHUB_REPO_URL); \
		git push -u origin master; \
	else \
		git clone $(GITHUB_REPO_URL) $(GITHUB_PUBLISH_SRC); \
	fi
endif
ifdef DOCS_TO_PUB_VIA_GIT
	-cd $(COURSE_MATERIAL_DIR) && rsync -rzL --relative $(addprefix docs/,$(DOCS_TO_PUB_VIA_GIT)) $(GITHUB_PUBLISH_SRC)
endif
ifdef CODES_TO_PUB_VIA_GIT
	-cd $(COURSE_MATERIAL_DIR) && rsync -rzL --relative $(addprefix codes/,$(CODES_TO_PUB_VIA_DR)) $(GITHUB_PUBLISH_SRC)
endif
ifdef DATA_TO_PUB_VIA_GIT
	-for data in $(DATA_TO_PUB_VIA_GIT); \
	do \
	(aws s3 cp $(addprefix $(S3_DATA_BUCKET)/$(COURSE_NAME)/data/,$$data) \
		$(addprefix $(GITHUB_PUBLISH_SRC)/data/,$$data)) \
	done
endif
	@if [ -d $(GITHUB_PUBLISH_SRC)/.git ]; then \
		cd $(GITHUB_PUBLISH_SRC); \
		if ! git diff-index --quiet $$(git write-tree) -- || [ -n "$$(git status --porcelain)" ]; then \
			git add -A ; \
			LANG=C git -c color.status=false status \
			| sed -n -e '1,/Changes to be committed:/ d' \
				      -e '1,1 d' \
				      -e '/^Untracked files:/,$$ d' \
				      -e 's/^\s*//' \
				      -e '/./p' \
				      > $(GITHUB_PUBLISH_SRC)/.git/msg.txt; \
			git commit -F $(GITHUB_PUBLISH_SRC)/.git/msg.txt; \
			rm -rf $(GITHUB_PUBLISH_SRC)/.git/msg.txt; \
			git push; \
		fi; \
	fi
	@rm -rf $(GITHUB_PUBLISH_SRC)
endif
endif

# Rule to publish all {{{2
.PHONY : publish
publish_documents: publish_s3 publish_github


# Debug Rules {{{1
# Rule to print makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
