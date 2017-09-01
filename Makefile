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

# Rule to initialize  files {{{2
.PHONY: init_files
init_files:
	@find $(PROJECT_DIR) -type f \
		\( -name "PROJECT_NAME_*.ipynb" -o -name "PROJECT_NAME_*.bib" -o \
		   -name "PROJECT_NAME_*.jem*" -o -name "MENU" -o \
		   -name "PROJECT_NAME_*.*sh" \) \
		-exec sed -i.bak "s/PROJECT_NAME/$(PROJECT_NAME)/g" {} \;
	@find $(PROJECT_DIR) -type f -name "*.bak" -exec rm -f {} \;

	@find $(PROJECT_DIR) -type f -name 'PROJECT_NAME_*.*' \
		-exec bash -c 'mv "$$1" "$${1/PROJECT_NAME_/$(PROJECT_NAME)_}"' -- {} \;

# Rule to create ne cessary links {{{2
.PHONY: link_files
link_files:
ifdef ZSH_CUSTOM
	@find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "$(PROJECT_NAME)_*.zsh" \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

# Rule to initializ e git repo {{{2
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


# Document Rules {{{1
# Variables {{{2
PROJECT_BIB_DIR             := $(PROJECT_DIR)/bib
PROJECT_FIGS_DIR            := $(PROJECT_DIR)/figures
PROJECT_DOCS_DIR            := $(PROJECT_DIR)/docs
PROJECT_IPYNB_FILE          := $(PROJECT_DOCS_DIR)/$(PROJECT_NAME)_master.ipynb
# Function to compile jupyter notebook to tex and pdf files, and create packages for submission {{{2
define gen_materials
	if [ ! -d $(PROJECT_DOCS_DIR)/$(1) ]; then mkdir -p $(PROJECT_DOCS_DIR)/$(1); fi

	jupyter nbconvert --to latex --tempate $(PROJECT_DOCS_DIR)/$(1).tplx \
		--output-dir $(PROJECT_DOCS_DIR)/$(1) --output $(PROJECT_NAME)_$(1).tex
	latexmk -pdf -pdflatex="pdflatex --shell-escape -interactive=nonstopmode %O %S" \
		-use-make $(PROJECT_DOCS_DIR)/$(1)/$(PROJECT_NAME)_$(1).tex

	if [ ! -d $(PROJECT_DOCS_DIR)/$(1)_tmp ]; then mkdir -p $(PROJECT_DOCS_DIR)/$(1)_tmp); fi

	find $(PROJECT_DOCS_DIR)/$(1) \
		 -not \( -path '*/\.*'  -o -path '*/draw' -prune \) \
		 -not \( -name "*.zip" -o -name "*.gz" \) \
		 -type f \
		 -exec rsync -urzL {} $(PROJECT_DOCS_DIR)/$(1)_tmp \;

	cd $(PROJECT_DOCS_DIR)/$(1)_tmp; \
		tar -zcvf $(PROJECT_DOCS_DIR)/$(1)/$(PROJECT_NAME)_$(1).tar.gz *
	rm -rf $(PROJECT_DOCS_DIR)/$(1)_tmp
endef


# Rules to generate documents {{{2
.PHONY : build_materials
build_materials:
	@$(foreach DOC,$(PROJECT_DOCS_READY),$(call gen_materials,$(DOC));)


# Rules to publish the documents to webpages {{{2
.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	@if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	@$(foreach DOC,$(PROJECT_DOCS_READY),\
		find $(PROJECT_DOCSDIR)/$(DOC) -maxdepth 1 -type f -name "*.pdf" \
			 -exec rsync -urzL {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


# Rule to clean up the documents {{{2
.PHONY : clean_materials
clean_materials:
	@$(foreach DOC,$(PROJECT_DOCS_READY),\
		cd $(PROJECT_DOCS_DIR)/$(DOC); \
		latexmk -silent -C; \
		rm -rf *.run.xml *.synctex.gz *.d *.bll;)


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

PUBLISTH_DOCS_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/pics
# Rule to build and publish webpages {{{2
.PHONY : build_webpages
build_webpages:
ifdef PROJECT_WEBPAGES_READY
ifdef PROJECT_WEBPAGES_DIR
# uncomment if there are bib files to include into the webpage
# find $(PROJECT_BIB_DIR) -type f -name "*.bib" -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	@jupyter nbconvert --to html --template basic $(PROJECT_IPYNB_FILE) --output-dir $(WEBPAGES_SRC_DIR)
	@rsync -rzL $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	@rsync -rzL $(WEBPAGES_MAKEFILE) $(PROJECT_WEBPAGES_DIR)
	@$(MAKE) -C $(PROJECT_WEBPAGES_DIR)

ifdef PUBLISH_WEBPAGES_DIR
	@if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	@rsync -urzL $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	@rsync -urzL $(WEBPAGES_PICS_DIR) $(PUBLISH_WEBPAGES_DIR)
	@rsync -urzL $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	@rsync -urzL $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif
endif

# Rule to clean the webpages {{{2
.PHONY : clean_webpages
clean_webpages :
ifdef PROJECT_WEBPAGES_DIR
	@ echo "Cleaning webpages"
	@$(MAKE) -C $(PROJECT_WEBPAGES_DIR) clean
endif

# Git Operations {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                      := $(shell git config --global --includes github.user)
GITHUB_TOKEN                     := :$(shell git config --global --includes github.token)
GITHUB_API_URL                   := https://api.github.com/user/repos
GITHUB_REPO_URL                  := git@github.com:$(GITHUB_USER)/$(notdir $(PROJECT_DIR)).git
CURRENT_BRANCH                   := $(shell git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell git log -n1 | head -n1 | cut -c8-)

# Rule to create the remote github repo {{{2
.PHONY : github_mk
github_mk:
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(notdir $(PROJECT_DIR))", "private" : true }'
	@git init
	@git add -A
	@git commit -m "First commit"
	@git remote add origin $(GITHUB_REPO_URL)
	@git push -u origin master
	@find $(PROJECT_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^GITHUB_REPO[ ]\{1,\}:=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(PROJECT_DIR) -type f -name '*.bak' -exec rm -f {} \;
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
