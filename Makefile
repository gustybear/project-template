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
init: init_files link_files prepare_git

# Rule to initialize files {{{2
.PHONY: init_files
init_files:
	@find $(PROJECT_DIR) -type f \
		\( -name "PROJECT_NAME_*.ipynb" -o \
		   -name "PROJECT_NAME_*.jem*" -o -name "MENU" -o \
		   -name "PROJECT_NAME_*.*sh" \) \
		-exec sed -i.bak "s/PROJECT_NAME/$(PROJECT_NAME)/g" {} \;
	@find $(PROJECT_DIR) -type f -name "*.bak" -exec rm -f {} \;

	@find $(PROJECT_DIR) -type f -name 'PROJECT_NAME_*.*' \
		-exec bash -c 'mv "$$1" "$${1/PROJECT_NAME_/$(PROJECT_NAME)_}"' -- {} \;

# Rule to create necessary links {{{2
.PHONY: link_files
link_files:
ifdef ZSH_CUSTOM
	@find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "$(PROJECT_NAME)_*.zsh" \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

# Rule to prepare for git repo initialization {{{2
define GITIGNORE
public/*
data/*
!data/$(PROJECT_NAME)_get_data.sh
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(PROJECT_DIR)/.git
	@echo "$$GITIGNORE" > $(PROJECT_DIR)/.gitignore


# Documents Rules {{{1
# Variables {{{2
PROJECT_DOCS_DIR            = $(PROJECT_DIR)/docs

doc_path                   = $(foreach EXT,$(3),$(foreach FILE,$(addprefix $(1),$(join $(2),$(addprefix /$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_,$(2)))),$(FILE)*.$(EXT)))

# Documents to build
ifdef DOCS_TO_COMPILE
TEX_TO_COMPILE              = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(DOCS_TO_COMPILE),.tex)
PDF_TO_COMPILE              = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(DOCS_TO_COMPILE),.pdf)
TAR_TO_COMPILE              = $(call doc_path,$(PROJECT_DOCS_DIR)/,$(DOCS_TO_COMPILE),.tar.gz)
endif

# Rules to build Documents {{{2
# TEX {{{3
define tex_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.tex: $$(PROJECT_DOCS_DIR)/%_master.ipynb $$(PROJECT_DOCS_DIR)/$1.tplx
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@cd $$(PROJECT_DOCS_DIR) && jupyter nbconvert \
		--NbConvertApp.output_files_dir='./asset' \
		--Exporter.preprocessors=[\"bibpreprocessor.BibTexPreprocessor\"\,\"pymdpreprocessor.PyMarkdownPreprocessor\"] \
		--to=latex $$(word 1,$$^) --template=$$(word 2,$$^) \
		--output-dir=$$(@D) --output=$$(@F)
	@rsync -av --delete $$(PROJECT_DOCS_DIR)/asset $$(@D)
endef

$(foreach DOC,$(DOCS_TO_COMPILE),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(TEX_TO_COMPILE)

# PDF {{{3
define pdf_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.pdf: $$(PROJECT_DOCS_DIR)/$1/%_$1.tex
	@cd $$(PROJECT_DOCS_DIR)/$1 && latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $$<
endef

$(foreach DOC,$(DOCS_TO_COMPILE),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(PDF_TO_COMPILE)

# TAR {{{3
define tar_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.tar.gz: $$(PROJECT_DOCS_DIR)/$1
	@mkdir -p $$(PROJECT_DOCS_DIR)/tmp)
	@find $$< \
		 -not \( -path '*/\.*' -prune \) \
		 -not \( -name "*.zip" -o -name "*.gz" \) \
		 -type f \
		 -exec rsync -urzL {} $$(PROJECT_DOCS_DIR)/tmp \;

	@cd $$(PROJECT_DOCS_DIR)/tmp; tar -zcvf $$@ *
	@rm -rf $(PROJECT_DOCS_DIR)/tmp
endef

$(foreach DOC,$(DOCS_TO_COMPILE),$(eval $(call tar_rules,$(DOC))))

.PHONY: build_tar
build_tar: $(TAR_TO_COMPILE)

# ALL {{{3
.PHONY: build_documents
build_documents: build_tex build_pdf build_tar

# Rule to clean documents {{{2
# TEX {{{3
.PHONY: clean_tex
clean_tex:
	@rm -rf $(TEX_TO_COMPILE)

# PDF {{{3
.PHONY : clean_pdf
clean_pdf:
	@$(foreach DOC,$(DOCS_TO_COMPILE),\
		cd $(PROJECT_DOCS_DIR)/$(DOC); \
		latexmk -silent -C; \
		rm -rf *.run.xml *.synctex.gz *.d *.bbl;)

# TAR {{{3
.PHONY : clean_tar
clean_tar:
	@rm -rf $(TAR_TO_COMPILE)

# ALL {{{3
.PHONY: clean_documents
clean_documents: clean_tex clean_pdf clean_tar

# Codes Rules {{{1
# Variables {{{2
PROJECT_CODES_DIR            = $(PROJECT_DIR)/codes

# Data Rules {{{1
# Variables {{{2
PROJECT_DATA_DIR            = $(PROJECT_DIR)/data
ARCHIVE_DATA_DIR            = $(PROJECT_DATA_DIR)/archive
CURRENT_DATA_DIR            = $(PROJECT_DATA_DIR)/current

S3_DATA_BUCKET              = s3://gustybear-research

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
	@aws s3 cp $(ARCHIVE_DATA_DIR)/$(TIMESTAMP).tar.gz $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/$(TIMESTAMP).tar.gz

# Rule to list objects in S3 {{{2
.PHONY : s3_ls
s3_ls:
	@aws s3 ls --recursive --human-readable $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/

# Publish Rules {{{1
# Variables {{{2
# s3 parameters
S3_PUBLISH_SRC              = $(PROJECT_DIR)/public/s3
S3_PUBLISH_DES              = s3://gustybear-websites

# dropbox parameters
DROPBOX_UPLOADER            = dropbox_uploader.sh
DR_PUBLISH_SRC              = $(PROJECT_DIR)/public/dropbox
DR_PUBLISH_DES              = $(notdir $(PROJECT_DIR))

# Rules to publish {{{2
# S3 {{{3
.PHONY: publish_s3
publish_s3:
	@test -d $(S3_PUBLISH_SRC) || mkdir -p $(S3_PUBLISH_SRC)
	@rm -rf $(S3_PUBLISH_SRC)/*
ifdef DOCS_TO_PUB_VIA_S3
	@cd $(PROJECT_DIR) && rsync -urzL --relative $(call doc_path,docs/,$(DOCS_TO_COMPILE),$(DOCS_TO_PUB_VIA_S3)) $(S3_PUBLISH_SRC)
endif
ifdef CODES_TO_PUB_VIA_S3
	@cd $(PROJECT_DIR) && rsync -urzL --relative $(CODES_TO_PUB_VIA_S3) $(S3_PUBLISH_SRC)
endif
	@aws s3 cp $(S3_PUBLISH_SRC)/ $(S3_PUBLISH_DES)/$(notdir $(PROJECT_DIR))/ --recursive # --dryrun

ifdef DATA_TO_PUB_VIA_S3
	@aws s3 cp $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/$(DATA_TO_PUB_VIA_S3) $(S3_PUBLISH_DES)/$(notdir $(PROJECT_DIR))/data/$(DATA_TO_PUB_VIA_S3)
endif

# DROPBOX {{{3
.PHONY: publish_dropbox
publish_dropbox:
	@test -d $(DR_PUBLISH_SRC) || mkdir -p $(DR_PUBLISH_SRC)
	@rm -rf $(DR_PUBLISH_SRC)/*
ifdef DOCS_TO_PUB_VIA_DR
	@cd $(PROJECT_DIR) && rsync -urzL --relative $(call doc_path,docs/,$(DOCS_TO_COMPILE),$(DOCS_TO_PUB_VIA_DR)) $(DR_PUBLISH_SRC)
endif
ifdef CODES_TO_PUB_VIA_DR
	@cd $(PROJECT_DIR) && rsync -urzL --relative $(CODES_TO_PUB_VIA_DR) $(DR_PUBLISH_SRC)
endif
ifdef DATA_TO_PUB_VIA_DR
	@aws s3 cp $(S3_DATA_BUCKET)/$(notdir $(PROJECT_DIR))/data/$(DATA_TO_PUB_VIA_DR) $(DR_PUBLISH_SRC)/data/$(DATA_TO_PUB_VIA_DR)
endif
	@$(DROPBOX_UPLOADER) upload $(DR_PUBLISH_SRC)/* $(DR_PUBLISH_DES)/

# ALL {{{3
.PHONY : publish_documents
publish_documents: publish_s3 publish_dropbox


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
	@git remote add origin $(GITHUB_REPO_URL)
	@git add -A
	@git commit -m "First commit"
	@git push -u origin master
endif


# Debug Rules {{{1
# Rule to print Makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
