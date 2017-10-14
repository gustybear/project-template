# Global Variables {{{1
OS                          := $(shell uname)
TIMESTAMP                   := $(shell date +"%Y%m%d_%H%M%S")
PROJECT_DIR                 := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME                := $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^[^_]\{1,\}_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')
PROJECT_TYPE                := $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^\([^_]\{1,\}\).*/\1/g')
MKFILES                     := $(shell find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
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
# not track the html files in the webpages
__webpages/*/*.html
# Only track the download script in the data directory
data/*
!/$(PROJECT_NAME)_get_data.sh
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(PROJECT_DIR)/.git
	@echo "$$GITIGNORE" > $(PROJECT_DIR)/.gitignore


# Material Rules {{{1
# Variables {{{2
PROJECT_DOCS_DIR            := $(PROJECT_DIR)/docs

# The default folder to publish the materials
PUBLISH_MATERIALS_DIR       := $(PROJECT_WEBPAGES_DIR)/des
PUBLISTH_DOCS_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/pics

# Materials to build
ifdef PROJECT_DOCS_READY
PROJECT_DOCS_TEX            := $(addprefix $(PROJECT_DOCS_DIR)/,$(join $(PROJECT_DOCS_READY),$(addprefix /$(PROJECT_NAME)_,$(addsuffix .tex,$(PROJECT_DOCS_READY)))))
PROJECT_DOCS_PDF            := $(addprefix $(PROJECT_DOCS_DIR)/,$(join $(PROJECT_DOCS_READY),$(addprefix /$(PROJECT_NAME)_,$(addsuffix .pdf,$(PROJECT_DOCS_READY)))))
PROJECT_DOCS_TAR            := $(addprefix $(PROJECT_DOCS_DIR)/,$(join $(PROJECT_DOCS_READY),$(addprefix /$(PROJECT_NAME)_,$(addsuffix .tar.gz,$(PROJECT_DOCS_READY)))))
endif

# Rules to build materials {{{2
# TEX
define tex_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.tex: $$(PROJECT_DOCS_DIR)/%_master.ipynb $$(PROJECT_DOCS_DIR)/$1.tplx
	@if [ ! -d $$(@D) ]; then mkdir -p $$(@D); fi
	@cd $$(PROJECT_DOCS_DIR) && jupyter nbconvert \
		--NbConvertApp.output_files_dir='$$(@D)/asset' \
		--Exporter.preprocessors=[\"bibpreprocessor.BibTexPreprocessor\"\,\"pymdpreprocessor.PyMarkdownPreprocessor\"] \
		--to=latex $$(word 1,$$^) --template=$$(word 2,$$^) \
		--output-dir=$$(@D) --output=$$(@F)
endef

$(foreach DOC,$(PROJECT_DOCS_READY),$(eval $(call tex_rules,$(DOC))))

.PHONY: build_tex
build_tex: $(PROJECT_DOCS_TEX)

.PHONY: clean_tex
clean_tex:
	@rm -rf $(PROJECT_DOCS_TEX)

# PDF
define pdf_rules
$$(PROJECT_DOCS_DIR)/$1/%_$1.pdf: $$(PROJECT_DOCS_DIR)/$1/%_$1.tex
	@latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $$<
endef

$(foreach DOC,$(PROJECT_DOCS_READY),$(eval $(call pdf_rules,$(DOC))))

.PHONY: build_pdf
build_pdf: $(PROJECT_DOCS_PDF)

.PHONY : clean_pdf
clean_pdf:
	@$(foreach DOC,$(PROJECT_DOCS_READY),\
		cd $(PROJECT_DOCS_DIR)/$(DOC); \
		latexmk -silent -C; \
		rm -rf *.run.xml *.synctex.gz *.d *.bll;)

# TAR
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

.PHONY : clean_tar
clean_tar:
	@rm -rf $(PROJECT_DOCS_TAR)

.PHONY: build_materials
build_materials: build_pdf

# Rule to publish materials
.PHONY : publish_materials
publish_materials:
	@if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	@$(foreach DOC,$(PROJECT_DOCS_READY),\
		find $(PROJECT_DOCSDIR)/$(DOC) -maxdepth 1 -type f -name "*.pdf" \
			 -exec rsync -urzL {} $(PUBLISTH_DOCS_SUBDIR) \; ;)

# Rule to clean materials
.PHONY: clean_materials
clean_materials: clean_pdf


# Webpage Rules {{{1
# Variables {{{2
PROJECT_WEBPAGES_DIR        := $(PROJECT_DIR)/__webpages
WEBPAGES_MAKEFILE           := $(PROJECT_WEBPAGES_DIR)/Makefile
WEBPAGES_SRC_DIR            := $(PROJECT_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR            := $(PROJECT_WEBPAGES_DIR)/des
WEBPAGES_SITECONF           := $(WEBPAGES_SRC_DIR)/site.conf
WEBPAGES_CSS_DIR            := $(WEBPAGES_SRC_DIR)/css
WEBPAGES_FONTS_DIR          := $(WEBPAGES_SRC_DIR)/fonts
WEBPAGES_PICS_DIR           := $(WEBPAGES_SRC_DIR)/pics

# The default folder to publish the webpages
PUBLISH_WEBPAGES_DIR        := $(PROJECT_WEBPAGES_DIR)/des

# Rule to take project offline {{ {2
.PHONY : project_offline
project_offline:
	@find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		   -exec sed -i.bak 's/^\(PROJECT_WEBPAGES_READY[ ]\{1,\}:=.*$$\)/\#\1/g' {} \;
	@find $(PROJECT_DIR) -name 'inputs.mk.bak' -exec rm -f {} \;

# Rule to take project online {{{2
.PHONY : project_online
project_online:
	@find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		   -exec sed -i.bak 's/^#\(PROJECT_WEBPAGES_READY[ ]\{1,\}:=.*$$\)/\1/g' {} \;
	@find $(PROJECT_DIR) -type f -name 'inputs.mk.bak' -exec rm -f {} \;

# Rule to build webpages {{{2
.PHONY : build_webpages
build_webpages:
ifdef PROJECT_WEBPAGES_READY
	@jupyter nbconvert --to html --template basic $(PROJECT_IPYNB_FILE) --output-dir $(WEBPAGES_SRC_DIR)
	@rsync -rzL $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	@rsync -rzL $(WEBPAGES_MAKEFILE) $(PROJECT_WEBPAGES_DIR)
	@$(MAKE) -C $(PROJECT_WEBPAGES_DIR)
endif

# Rule to publish webpages {{{2
.PHONY : publish_webpages
publish_webpages:
	@if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	@rsync -urzL $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	@rsync -urzL $(WEBPAGES_PICS_DIR) $(PUBLISH_WEBPAGES_DIR)
	@rsync -urzL $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	@rsync -urzL $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)

# Rule to clean webpages {{{2
.PHONY : clean_webpages
clean_webpages :
ifdef PROJECT_WEBPAGES_READY
	@ echo "Cleaning webpages"
	@$(MAKE) -C $(PROJECT_WEBPAGES_DIR) clean
endif


# Git Rules {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                      := $(shell git config --global --includes github.user)
GITHUB_TOKEN                     := :$(shell git config --global --includes github.token)
GITHUB_API_URL                   := https://api.github.com/user/repos
GITHUB_REPO_URL                  := git@github.com:$(GITHUB_USER)/$(notdir $(PROJECT_DIR)).git
CURRENT_BRANCH                   := $(shell test -d $(PROJECT_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell test -d $(PROJECT_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

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

# Rule to update the local and remote git repo {{{2
.PHONY : github_update
github_update:
ifdef GITHUB_REPO
#fast commit and push to git repository
	@cd $(PROJECT_DIR) && git pull
	@cd $(PROJECT_DIR) && git add . && git diff --quiet --exit-code --cached || git commit -m "Publish on $$(date)" -a
	@cd $(PROJECT_DIR) && git push
endif


# Data Rules {{{1
# Variables {{{2
PROJECT_DATA_DIR            := $(PROJECT_DIR)/data
ARCHIVE_DATA_DIR            := archive
CURRENT_DATA_DIR            := current
S3_DATA_DIR                 := s3
# name of the archive
ARCHIVE_TARGET              :=
# name of the s3 object
S3_TARGET                   :=

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
			$(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)/$(TIMESTAMP)_$(ARCHIVE_TARGET) \
			$(RSYNC_DATA_EXCLUDE); \
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
	@rsync -av --delete --copy-links $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR)/ $(PROJECT_DATA_DIR)/$(S3_DATA_DIR) \
		$(RSYNC_DATA_EXCLUDE) # --dry-run
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
	@rsync -av --delete --keep-dirlinks $(PROJECT_DATA_DIR)/$(S3_DATA_DIR)/ $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR) \
		$(RSYNC_DATA_EXCLUDE) # --dry-run
endif
endif


# Debug Rules {{{1
# Rule to print makefile variables {{{2
print-%:
	@echo '$*:=$($*)'
