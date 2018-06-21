# Global Variables {{{1
OS                          = $(shell uname)
TIMESTAMP                   := $(shell date +"%Y%m%d_%H%M%S")
PROJECT_DIR                 = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME                = $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^[^_]\{1,\}_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')
PROJECT_TYPE                = $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^\([^_]\{1,\}\).*/\1/g')
MKFILES                     = $(shell find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
-include $(MKFILES)

# Initialization Rules {{{1
# Rule to initialize the project {{{2
.PHONY : init
init: init_files init_data link_files prepare_git

# Rule to initialize files {{{2
.PHONY: init_files
init_files:
	@find $(PROJECT_DIR) -type f \
		-name "PROJECT_NAME*.*" \
		-exec sed -i.bak "s/PROJECT_NAME/$(PROJECT_NAME)/g" {} \;
	@find $(PROJECT_DIR) -type f -name "*.bak" -exec rm -f {} \;

	@find $(PROJECT_DIR) -type f -name 'PROJECT_NAME*.*' \
		-exec bash -c 'mv "$$1" "$${1/PROJECT_NAME/$(PROJECT_NAME)}"' -- {} \;

# Rule to create necessary links {{{2
.PHONY: link_files
link_files: ;

# Rule to prepare for git repo initialization {{{2
define GITIGNORE
public/*
data/*
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(PROJECT_DIR)/.git
	@echo "$$GITIGNORE" > $(PROJECT_DIR)/.gitignore


# Documents Rules {{{1
# Variables {{{2
PROJECT_DOCS_DIR            = $(PROJECT_DIR)/docs

doc_path                   = $(foreach EXT,$(3),$(foreach FILE,$(addprefix $(1),$(join $(2),$(addprefix /$(PROJECT_NAME)_,$(2)))),$(FILE).$(EXT)))

# Rules to build Documents {{{2
# TEX {{{3
ifdef TEX_TO_COMPILE
TEX_FILES                   = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(TEX_TO_COMPILE),tex)
endif

# NOTE: assuming the bib files and figures are within $(PROJECT_DOCS_DIR)/asset
# TODO: add templates for different types
define tex_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.tex: $$(PROJECT_DOCS_DIR)/%.md
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@cd $$(PROJECT_DOCS_DIR) && cat $$(word 1,$$^) | sed -n '/^---/,/^---/p; /^\[$1:sta\]/,/^\[$1:end\]/p' | pandoc --filter pandoc-citeproc -f markdown+yaml_metadata_block+smart -t latex --standalone -o $$(@D)/$$(@F)
	@rsync -av --delete $$(PROJECT_DOCS_DIR)/asset $$(@D)
endef

$(foreach DOC,$(TEX_TO_COMPILE),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(TEX_FILES)

# PDF {{{3
ifdef PDF_TO_COMPILE
PDF_FILES                   = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(PDF_TO_COMPILE),pdf)
endif

define pdf_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.pdf: $$(PROJECT_DOCS_DIR)/$1/%_$1.tex
	@cd $$(PROJECT_DOCS_DIR)/$1 && latexmk -pdf -pdflatex="pdflatex --shell-escape -interaction=nonstopmode %O %S" \
		-use-make $$<
	@cd $$(PROJECT_DOCS_DIR)/$1 && latexmk -c
endef

$(foreach DOC,$(PDF_TO_COMPILE),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(PDF_FILES)

# TAR {{{3
ifdef TAR_TO_COMPILE
TAR_FILES                   = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(TAR_TO_COMPILE),tar.gz)
endif

define tar_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.tar.gz: $$(PROJECT_DOCS_DIR)/$1
	@mkdir -p $$(PROJECT_DOCS_DIR)/tmp)
	@find $$< \
		 -not \( -path '*/\.*' -prune \) \
		 -not \( -name "*.zip" -o -name "*.gz" \) \
		 -type f \
		 -exec rsync -urzL {} $$(PROJECT_DOCS_DIR)/tmp \;

	@cd $$(PROJECT_DOCS_DIR)/tmp; tar -zcvf $$@ *
	@rm -rf $$(PROJECT_DOCS_DIR)/tmp
endef

$(foreach DOC,$(TAR_TO_COMPILE),$(eval $(call tar_rules,$(DOC))))

.PHONY: build_tar
build_tar: $(TAR_FILES)

# MARAKDOWN {{{3
ifdef MD_TO_COMPILE
MD_FILES                   = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(MD_TO_COMPILE),md)
endif

define md_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.md: $$(PROJECT_CODES_DIR)/%.md
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@cd $$(PROJECT_DOCS_DIR) && cat $$(word 1,$$^) | sed -n '/^---/,/^---/p; /^\[$1:sta\]/,/^\[$1:end\]/p' | pandoc --filter pandoc-citeproc -f markdown+yaml_metadata_block+smart -t markdown -o $$(@D)/$$(@F)
	@rsync -av --delete $$(PROJECT_DOCS_DIR)/asset $$(@D)
endef

$(foreach DOC,$(MD_TO_COMPILE),$(eval $(call md_rules,$(DOC))))

.PHONY: build_md
build_md: $(MD_FILES)

# ALL {{{3
.PHONY: build_documents
build_documents: build_tex build_pdf build_tar build_md

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
PROJECT_CODES_DIR            = $(PROJECT_DIR)/codes

# Data Rules {{{1
# Variables {{{2
PROJECT_DATA_DIR            = $(PROJECT_DIR)/data
ARCHIVE_DATA_DIR            = $(PROJECT_DATA_DIR)/archive

S3_DATA_BUCKET              = s3://gustybear-research

# Rule to initialize the data directory {{{2
.PHONY : init_data
init_data:
	@if [ ! -d $(ARCHIVE_DATA_DIR) ] && [ ! -L $(ARCHIVE_DATA_DIR) ]; then \
		mkdir -p $(ARCHIVE_DATA_DIR); \
	fi

# Rule to create archive {{{2
.PHONY : archive_mk
archive_mk:
	@echo "Creating archive file: $(TIMESTAMP).tar.gz."
	@mkdir -p $(ARCHIVE_DATA_DIR)/$(TIMESTAMP)
	@rsync -av --copy-links --exclude $(ARCHIVE_DATA_DIR) $(PROJECT_DATA_DIR)/ $(ARCHIVE_DATA_DIR)/$(TIMESTAMP)
	@tar -zcvf $(ARCHIVE_DATA_DIR)/$(TIMESTAMP).tar.gz -C $(ARCHIVE_DATA_DIR) ./$(TIMESTAMP)
	@rm -rf $(ARCHIVE_DATA_DIR)/$(TIMESTAMP)
	@echo "Use the following command to upload to Amazon S3"
	@echo "aws s3 cp $(ARCHIVE_DATA_DIR)/$(TIMESTAMP).tar.gz $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/$(TIMESTAMP).tar.gz"

# Rule to list objects in S3 {{{2
.PHONY : s3_ls
s3_ls:
	@aws s3 ls --recursive --human-readable $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/

# Publish Rules {{{1
# Variables {{{2
# s3 parameters
S3_PUBLISH_SRC              = $(PROJECT_DIR)/public/s3
S3_PUBLISH_DES              = s3://gustybear-websites

# Rule to publish via S3 {{{2
.PHONY: publish_s3
publish_s3:
	@test -d $(S3_PUBLISH_SRC) || mkdir -p $(S3_PUBLISH_SRC)
	@rm -rf $(S3_PUBLISH_SRC)/*
	@aws s3 rm $(S3_PUBLISH_DES)/$(notdir $(PROJECT_DIR)) --recursive # --dryrun
ifdef DOCS_TO_PUB_VIA_S3
	-@cd $(PROJECT_DIR) && rsync -av --relative $(addprefix docs/,$(DOCS_TO_PUB_VIA_S3)) $(S3_PUBLISH_SRC)
endif
ifdef CODES_TO_PUB_VIA_S3
	-@cd $(PROJECT_DIR) && rsync -av --relative $(addprefix codes/,$(CODES_TO_PUB_VIA_S3)) $(S3_PUBLISH_SRC)
endif
	@aws s3 cp $(S3_PUBLISH_SRC) $(S3_PUBLISH_DES)/$(notdir $(PROJECT_DIR)) --recursive # --dryrun

ifdef DATA_TO_PUB_VIA_S3
	-@for data in $(DATA_TO_PUB_VIA_S3); \
	do \
	(aws s3 cp $(addprefix $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/,$$data) \
		$(addprefix $(S3_PUBLISH_DES)/$(notdir $(PROJECT_DIR))/data/,$$data)) \
	done
endif

# Rule to publish all {{{2
.PHONY : publish
publish: publish_s3


# Git Rules {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                      = $(shell git config --global --includes github.user)
GITHUB_TOKEN                     = :$(shell git config --global --includes github.token)
GITHUB_API_URL                   = https://api.github.com/user/repos
GITHUB_REPO_URL                  = git@github.com:$(GITHUB_USER)/$(notdir $(PROJECT_DIR)).git
CURRENT_BRANCH                   = $(shell test -d $(PROJECT_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   = $(shell test -d $(PROJECT_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

# Rule to create the remote github repo {{{2
.PHONY : github_mk
github_mk:
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(notdir $(PROJECT_DIR))", "private" : true }'
	@find $(PROJECT_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^GITHUB_REPO[ ]\{1,\}=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(PROJECT_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@git init
	@git add -A
	@git commit -m "First commit"
	@git remote add origin $(GITHUB_REPO_URL)
	@git push -u origin master
endif


# Debug Rules {{{1
# Rule to print Makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
