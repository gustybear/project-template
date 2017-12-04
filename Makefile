# Global Variables {{{1
OS                          = $(shell uname)
TIMESTAMP                   = $(shell date +"%Y%m%d_%H%M%S")
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
# Only track the download script in the data directory
data/*
!/$(PROJECT_NAME)_get_data.sh
dropbox/*
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(PROJECT_DIR)/.git
	@echo "$$GITIGNORE" > $(PROJECT_DIR)/.gitignore


# Material Rules {{{1
# Variables {{{2
PROJECT_DOCS_DIR            = $(PROJECT_DIR)/docs

# The default folder to publish the materials
PUBLISH_MATERIALS_DIR       = $(PROJECT_DOCS_DIR)/web
PUBLISTH_DOCS_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR        = $(PUBLISH_MATERIALS_DIR)/pics

# Materials to build
ifdef PROJECT_DOCS_READY
PROJECT_DOCS_TEX            = $(addprefix $(PROJECT_DOCS_DIR)/,$(join $(PROJECT_DOCS_READY),$(addprefix /$(PROJECT_NAME)_,$(addsuffix .tex,$(PROJECT_DOCS_READY)))))
PROJECT_DOCS_PDF            = $(addprefix $(PROJECT_DOCS_DIR)/,$(join $(PROJECT_DOCS_READY),$(addprefix /$(PROJECT_NAME)_,$(addsuffix .pdf,$(PROJECT_DOCS_READY)))))
PROJECT_DOCS_TAR            = $(addprefix $(PROJECT_DOCS_DIR)/,$(join $(PROJECT_DOCS_READY),$(addprefix /$(PROJECT_NAME)_,$(addsuffix .tar.gz,$(PROJECT_DOCS_READY)))))
endif

# Rules to build materials {{{2

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

$(foreach DOC,$(PROJECT_DOCS_READY),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(PROJECT_DOCS_TEX)

# PDF {{{3
define pdf_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.pdf: $$(PROJECT_DOCS_DIR)/$1/%_$1.tex
	@cd $$(PROJECT_DOCS_DIR)/$1 && latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $$<
endef

$(foreach DOC,$(PROJECT_DOCS_READY),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(PROJECT_DOCS_PDF)

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

$(foreach DOC,$(PROJECT_DOCS_READY),$(eval $(call tar_rules,$(DOC))))

.PHONY: build_tar
build_tar: $(PROJECT_DOCS_TAR)

# ALL {{{3
.PHONY: build_materials
build_materials: build_pdf

# Rule to publish materials {{{2

# TEX {{{3
.PHONY: publish_tex
publish_tex: $(PROJECT_DOCS_TEX)
	@rsync -urzL $(PROJECT_DOCS_TEX) $(PUBLISH_DOCS_SUBDIR)

# PDF {{{3
.PHONY: publish_pdf
publish_pdf: $(PROJECT_DOCS_PDF)
	@rsync -urzL $(PROJECT_DOCS_PDF) $(PUBLISH_DOCS_SUBDIR)

# PDF {{{3
.PHONY: publish_tar
publish_tar: $(PROJECT_DOCS_TAR)
	@rsync -urzL $(PROJECT_DOCS_TAR) $(PUBLISH_DOCS_SUBDIR)

.PHONY : publish_materials
publish_materials: publish_pdf


# Rule to clean materials {{{2

# TEX {{{3
.PHONY: clean_tex
clean_tex:
	@rm -rf $(PROJECT_DOCS_TEX)

# PDF {{{3
.PHONY : clean_pdf
clean_pdf:
	@$(foreach DOC,$(PROJECT_DOCS_READY),\
		cd $(PROJECT_DOCS_DIR)/$(DOC); \
		latexmk -silent -C; \
		rm -rf *.run.xml *.synctex.gz *.d *.bbl;)

# TAR {{{3
.PHONY : clean_tar
clean_tar:
	@rm -rf $(PROJECT_DOCS_TAR)

# ALL {{{3
.PHONY: clean_materials
clean_materials: clean_pdf


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
		-exec sed -i.bak 's|\(^GITHUB_REPO[ ]\{1,\}:=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(PROJECT_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@git init
	@git remote add origin $(GITHUB_REPO_URL)
	@git add -A
	@git commit -m "First commit"
	@git push -u origin master
endif


# Data Rules {{{1
# Variables {{{2
PROJECT_DATA_DIR            = $(PROJECT_DIR)/data
ARCHIVE_DATA_DIR            = archive
CURRENT_DATA_DIR            = current
S3_DATA_DIR                 = s3
# name of the archive
ARCHIVE_TARGET              =
# name of the s3 object
S3_TARGET                   =

# Rule to download the data and add sub directories {{{2
.PHONY : data_init
data_init:
	@if [ ! -d $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR) && ! -L $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR) ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR)
	fi
	@if [ ! -d $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR) && ! -L $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR) ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)
	fi
	@if [ ! -d $(PROJECT_DATA_DIR)/$(S3_DATA_DIR) && ! -L $(PROJECT_DATA_DIR)/$(S3_DATA_DIR) ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/$(S3_DATA_DIR)
	fi
	@sh $(PROJECT_DATA_DIR)/$(PROJECT_NAME)_get_data.sh

# Rule to create archive {{{2
.PHONY : archive_mk
archive_mk:
ifdef ARCHIVE_TARGET
	@if [ -d $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(ARCHIVE_TARGET) ]; then \
		echo "Recreating archive file: $(ARCHIVE_FOLDER).tar.gz."; \
		tar -zcvf $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(ARCHIVE_TARGET).tar.gz \
			-C $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR) ./$(ARCHIVE_TARGET); \
	else \
		echo "Creating archive file: $(TIMESTAMP)_$(ARCHIVE_TARGET).tar.gz."; \
		mkdir -p $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(TIMESTAMP)_$(ARCHIVE_TARGET); \
		rsync -av --copy-links  $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR)/ \
			$(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(TIMESTAMP)_$(ARCHIVE_TARGET); \
		tar -zcvf $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(TIMESTAMP)_$(ARCHIVE_TARGET).tar.gz \
			-C $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR) ./$(TIMESTAMP)_$(ARCHIVE_TARGET); \
		rm -rf $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(TIMESTAMP)_$(ARCHIVE_TARGET); \
	fi
endif

# Rule to list objects in S3 {{{2
.PHONY : s3_ls
s3_ls:
ifdef S3_BUCKET
	@echo "Local data at $(PROJECT_DATA_DIR)"
	@cd $(PROJECT_DATA_DIR) && \
		find -L . -not \( -path ./$(S3_DATA_DIR)  -prune \) -type f -exec ls -lh {} \;
	@echo "S3 data at $(S3_BUCKET)"
	@aws s3 ls --recursive --human-readable $(S3_BUCKET)
endif

# Rule to put file or directory to S3 {{{2
.PHONY : s3_put
s3_put:
ifdef S3_BUCKET
ifdef S3_TARGET
	@echo "Uploading $(S3_TARGET) to s3."
	@if [ -f $(PROJECT_DATA_DIR)/$(S3_TARGET) ]; then \
		aws s3 cp $(PROJECT_DATA_DIR)/$(S3_TARGET) $(S3_BUCKET)/$(S3_TARGET); \
	elif [ -d $(PROJECT_DATA_DIR)/$(S3_TARGET) ]; then \
		aws s3 cp --recursive $(PROJECT_DATA_DIR)/$(S3_TARGET) $(S3_BUCKET)/$(S3_TARGET); \
	fi
else
	@echo "Syncing current data folder to s3."
# backward sync will copy the actual files
	@rsync -av --delete --copy-links $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR)/ $(PROJECT_DATA_DIR)/$(S3_DATA_DIR) # --dry-run
	@aws s3 sync --delete $(PROJECT_DATA_DIR)/$(S3_DATA_DIR) $(S3_BUCKET)/$(CURRENT_DATA_DIR)
endif
endif

# Rule to download file from S3 {{{2
.PHONY : s3_get
s3_get:
ifdef S3_BUCKET
ifdef S3_TARGET
	@echo "Download $(S3_TARGET) from s3."
	@echo "Note: currently can only download file, not directory."
	aws s3 cp $(S3_BUCKET)/$(S3_TARGET) $(PROJECT_DATA_DIR)/$(S3_TARGET)
else
	@echo "Syncing current data folder from s3."
	@aws s3 sync --delete $(S3_BUCKET)/$(CURRENT_DATA_DIR) $(PROJECT_DATA_DIR)/$(S3_DATA_DIR)
# forward sync will follow the symbolinks
	@rsync -av --delete --keep-dirlinks $(PROJECT_DATA_DIR)/$(S3_DATA_DIR)/ $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR) # --dry-run
endif
endif


# Dropbox Rules {{{1
# Variables {{{2
LOCAL_DROPBOX_FOLDER          = $(PROJECT_DIR)/dropbox
REMOTE_DROPBOX_FOLDER         = $(shell echo $(notdir $(PROJECT_DIR)))
# Rules to sync dropbox {{{2
.PHONY: dropbox_init
dropbox_init:
	@if [ ! -d $(LOCAL_DROPBOX_FOLDER) && ! -L $(LOCAL_DROPBOX_FOLDER) ]; then \
		mkdir -p $(LOCAL_DROPBOX_FOLDER)
	$(DROPBOX_UPLOADER) -q mkdir $(REMOTE_DROPBOX_FOLDER)

.PHONY: dropbox_get
dropbox_get:
	@$(DROPBOX_UPLOADER) download $(REMOTE_DROPBOX_FOLDER)/* $(LOCAL_DROPBOX_FOLDER)/

.PHONY: dropbox_put
dropbox_put:
ifdef DROPBOX_SYNC_LIST
	@rsync -av --delete --copy-links --relative $(DROPBOX_SYNC_LIST) $(LOCAL_DROPBOX_FOLDER) # --dry-run
endif
	@$(DROPBOX_UPLOADER) upload $(LOCAL_DROPBOX_FOLDER)/* $(REMOTE_DROPBOX_FOLDER)/

# Conda Rules {{{1
# Variables {{{2
SHELL                         = /bin/bash
PROJECT_CODES_DIR             = $(PROJECT_DIR)/codes

# Rules to manipulate conda environment {{{2
.PHONY: conda_init
conda_init:
	conda create --name ${PROJECT_NAME}

.PHONY: conda_activate
conda_activate:
	source activate ${PROJECT_NAME}

.PHONY: conda_deactivate
conda_deactivate:
	source deactivate ${PRJOECT_NAME}

.PHONY: conda_export
conda_export:
	source activate ${PROJECT_NAME}
	conda env export > ${PROJECT_NAME}_environment.yml

.PHONY: conda_remove
conda_remove:
	conda remove --name ${PROJECT_NAME} --all


# Debug Rules {{{1
# Rule to print makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
