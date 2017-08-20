OS                                 := $(shell uname)
TIMESTAMP                          := $(shell date +"%Y%m%d_%H%M%S")
PROJECT_DIR                        := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME                       := $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^[^_]\{1,\}_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')
PROJECT_TYPE                       := $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^\([^_]\{1,\}\).*/\1/g')
MKFILES                            := $(shell find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
-include $(MKFILES)

PROJECT_BIB_DIR                    := $(PROJECT_DIR)/bib
PROJECT_FIG_DIR                    := $(PROJECT_DIR)/figures
PROJECT_FIG_DRAW_DIR               := $(PROJECT_DIR)/figures/draw
PROJECT_DOCS_DIR                   := $(PROJECT_DIR)/docs
PROJECT_DATA_DIR                   := $(PROJECT_DIR)/data
ARCHIVE_DATA_DIR                   := archive
CURRENT_DATA_DIR                   := current
S3_DATA_DIR                        := s3

ifdef PROJECT_DOCS_READY
PROJECT_DOCS_SUBDIRS               := $(addprefix $(PROJECT_DOCS_DIR)/,$(PROJECT_DOCS_READY))
endif

ifdef PROJECT_DOCPACS_READY
PROJECT_DOCPACS_SUBDIRS            := $(addprefix $(PROJECT_DOCS_DIR)/,$(PROJECT_DOCPACS_READY))
endif

ifdef PROJECT_WEBPAGES_READY
PROJECT_WEBPAGES_DIR               := $(shell find $(PROJECT_DIR) -type d -name "__webpages")
endif

ifdef PROJECT_WEBPAGES_DIR
WEBPAGES_MAKEFILE                  := $(PROJECT_WEBPAGES_DIR)/Makefile
WEBPAGES_SRC_DIR                   := $(PROJECT_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR                   := $(PROJECT_WEBPAGES_DIR)/des

WEBPAGES_SITECONF                  := $(WEBPAGES_SRC_DIR)/site.conf
WEBPAGES_CSS_DIR                   := $(WEBPAGES_SRC_DIR)/css
WEBPAGES_FONTS_DIR                 := $(WEBPAGES_SRC_DIR)/fonts
WEBPAGES_PICS_DIR                  := $(WEBPAGES_SRC_DIR)/pics
endif

ifdef PUBLISH_MATERIALS_DIR
PUBLISTH_DOCS_SUBDIR               := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR               := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR               := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR               := $(PUBLISH_MATERIALS_DIR)/pics
endif

TMP_DIR_PREFIX                     := $(PROJECT_DIR)/tmp

gen_tmp_dir_name                    = $(addprefix $(TMP_DIR_PREFIX)_,$(notdir $(1)))
gen_package_name                    = $(addprefix $(PROJECT_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	mkdir -p $(call gen_tmp_dir_name, $(1))
	find $(1) $(PROJECT_BIB_DIR) $(PROJECT_FIG_DIR) \
		 -not \( -path $(PROJECT_FIG_DRAW_DIR) -o -path '*/\.*' -prune \) \
		 -not \( -name "*.zip" -o -name "*.gz" \) \
		 -type f \
		 -exec rsync -urzL {} $(call gen_tmp_dir_name, $(1)) \;

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

define GITIGNORE
# not track the html files in the webpages
__webpages/*/*.html
# Only track the download script in the data directory
data/*
!/data.sh
endef
export GITIGNORE

.PHONY : clean
clean :
ifdef PROJECT_WEBPAGES_DIR
	$(MAKE) -C $(PROJECT_WEBPAGES_DIR) clean
endif


.PHONY : init init_files link_files prepare_git

init: init_files link_files prepare_git

init_files:
	@find $(PROJECT_DIR) -type f \
		\( -name "PROJECT_NAME_*.ipynb" -o -name "PROJECT_NAME_*.bib" -o \
		   -name "PROJECT_NAME_*.jem*" -o -name "PROJECT_NAME_MENU" -o \
		   -name "PROJECT_NAME_*.*sh" \) \
		-exec sed -i.bak "s/PROJECT_NAME/$(PROJECT_NAME)/g" {} \;
	@find $(PROJECT_DIR) -type f -name "*.bak" -exec rm -f {} \;

	@find $(PROJECT_DIR) -type f -name 'PROJECT_NAME_*.*' \
		-exec bash -c "mv {} `echo "{}" | sed 's/PROJECT_NAME_/$(PROJECT_NAME)_/g'`" \;

	@find $(PROJECT_DIR) -type f -name "$(PROJECT_NAME)_MENU" \
		-exec bash -c "mv {} `echo "{}" | sed 's/$(PROJECT_NAME)_//g' {}`" \;

	@mkdir -p $(PROJECT_DATA_DIR)/$(CURRENT_DATA_DIR)
	@mkdir -p $(PROJECT_DATA_DIR)/$(ARCHIVE_DATA_DIR)
	@mkdir -p $(PROJECT_DATA_DIR)/$(S3_DATA_DIR)

link_files:
ifdef ZSH_CUSTOM
	@find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "$(PROJECT_NAME)_*.zsh" \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

prepare_git:
	@rm -rf $(PROJECT_DIR)/.git
	@echo "$$GITIGNORE" > $(PROJECT_DIR)/.gitignore


.PHONY : pack_materials
pack_materials:
	@$(foreach SUBDIR,$(PROJECT_DOCPACS_SUBDIRS),$(call gen_package,$(SUBDIR));)


.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	@if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	@$(foreach SUBDIR,$(PROJECT_DOCS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.pdf" \
			 -exec rsync -urzL {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


.PHONY : build_webpages
build_webpages:
ifdef PROJECT_WEBPAGES_DIR
# uncomment if there are bib files to include into the webpage
# find $(PROJECT_BIB_DIR) -type f -name "*.bib" -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	@find $(PROJECT_DOCS_DIR) -not \( -path '*/\.*' -prune \) -type f -name "*.ipynb" \
		-exec jupyter nbconvert --to html --template basic {} --output-dir ${WEBPAGES_SRC_DIR} \;
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


# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                      := $(shell git config --global --includes github.user)
GITHUB_TOKEN                     := :$(shell git config --global --includes github.token)
GITHUB_API_URL                   := https://api.github.com/user/repos
GITHUB_REPO_URL                  := git@github.com:$(GITHUB_USER)/$(notdir $(PROJECT_DIR)).git

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

ifdef GITHUB_REPO
CURRENT_BRANCH                   := $(shell git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell git log -n1 | head -n1 | cut -c8-)
endif

.PHONY : github_update
github_update:
ifdef GITHUB_REPO
#fast commit and push to git repository
	@cd $(PROJECT_DIR) && git pull
	@cd $(PROJECT_DIR) && git add . && git diff --quiet --exit-code --cached || git commit -m "Publish on $$(date)" -a
	@cd $(PROJECT_DIR) && git push
endif


# Archive operation
ARCHIVE_TARGET                   :=

.PHONY : mk_archive
mk_archive:
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


# variables for archive operations
S3_TARGET                         :=

.PHONY : s3_ls
s3_ls:
ifdef S3_BUCKET
	@echo "Local data at $(PROJECT_DATA_DIR)"
	@cd $(PROJECT_DATA_DIR) && \
		find -L . -not \( -path ./$(S3_DATA_DIR)  -prune \) -type f -exec ls -lh {} \;
	@echo "S3 data at $(S3_BUCKET)"
	@aws s3 ls --recursive --human-readable $(S3_BUCKET)
endif


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


print-%:
	@echo '$*:=$($*)'
