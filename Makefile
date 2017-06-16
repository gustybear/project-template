OS                                 := $(shell uname)
TIMESTAMP                          := $(shell date +"%Y%m%d_%H%M%S")
PROJECT_DIR                        := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME                       := $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^[^_]\{1,\}_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')
PROJECT_TYPE                       := $(shell echo $(notdir $(PROJECT_DIR)) | sed 's/^\([^_]\{1,\}\).*/\1/g')
MKFILES                            := $(shell find $(PROJECT_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk")
-include $(MKFILES)

PROJECT_BIB_DIR                    := $(PROJECT_DIR)/bib
PROJECT_FIG_DIR                    := $(PROJECT_DIR)/figures
PROJECT_FIG_DRAW_DIR               := $(PROJECT_DIR)/figures/draw
PROJECT_DOCS_DIR                   := $(PROJECT_DIR)/docs
PROJECT_DATA_DIR                   := $(PROJECT_DIR)/data

ifeq ($(PROJECT_TYPE), project)
TRIM_SUBDIRS                       := prpsl suppl
else ifeq ($(PROJECT_TYPE), award)
TRIM_SUBDIRS                       := conf jnl report
else ifeq ($(PROJECT_TYPE), talk)
TRIM_SUBDIRS                       := conf jnl prpsl report suppl
else ifeq ($(PROJECT_TYPE), student)
TRIM_SUBDIRS                       := prpsl suppl conf jnl
else
TRIM_SUBDIRS                       :=
endif

ifdef TRIM_SUBDIRS
PROJECT_TRIM_SUBDIRS               := $(addprefix $(PROJECT_DOCS_DIR)/,$(TRIM_SUBDIRS))
endif

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

	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex'                              \
		-exec sed -i.bak 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} + ;\
	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex'                              \
		-exec sed -i.bak 's/^\\usepackage.*{epstopdf}/\\usepackage{epstopdf}/g' {} +       ;\
	find $(call gen_tmp_dir_name, $(1))  -type f -name '*.bak' -exec rm -f {} \;

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

define GITIGNORE
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


.PHONY : init init_files trim_files prepare_git link_files

init: init_files trim_files prepare_git link_files

init_files:
	find $(PROJECT_DIR) -type f \
		\( -name '_*.tex' -o -name '_*.bib' -o \
		   -name '_*.jem*' -o -name '_MENU' -o \
		   -name '_*.*sh' \) \
		-exec sed -i.bak 's/PROJECT_NAME/$(PROJECT_NAME)/g' {} \;
	find $(PROJECT_DIR) -type f -name '*.bak' -exec rm -f {} \;

	find $(PROJECT_DIR) -type f -name '_*.*' \
		-exec bash -c 'mv {} `dirname {}`/$(PROJECT_NAME)`basename {}`' \;

	find $(PROJECT_DIR) -type f -name '_MENU' \
		-exec bash -c 'mv {} `dirname {}`/MENU' \;

trim_files:
ifdef PROJECT_TRIM_SUBDIRS
	rm -rf $(PROJECT_TRIM_SUBDIRS)
endif

prepare_git:
	rm -rf $(PROJECT_DIR)/.git
	echo "$$GITIGNORE" > $(PROJECT_DIR)/.gitignore

link_files:
ifdef ZSH_CUSTOM
	find $(PROJECT_DIR) -type f -name '*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif


.PHONY : pack_materials
pack_materials:
	$(foreach SUBDIR,$(PROJECT_DOCPACS_SUBDIRS),$(call gen_package,$(SUBDIR));)


.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	$(foreach SUBDIR,$(PROJECT_DOCS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.pdf" \
			 -exec rsync -urzL {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


.PHONY : build_webpages
build_webpages:
ifdef PROJECT_WEBPAGES_DIR
	find $(PROJECT_BIB_DIR) -type f -name "*.bib" -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	find $(PROJECT_DOCS_DIR) -type f -name "*.html" -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	rsync -rzL $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	rsync -rzL $(WEBPAGES_MAKEFILE) $(PROJECT_WEBPAGES_DIR)
	$(MAKE) -C $(PROJECT_WEBPAGES_DIR)

ifdef PUBLISH_WEBPAGES_DIR
	if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	rsync -urzL $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_PICS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif

.PHONY : fast_git
fast_git:
ifdef GIT_REPO
	#fast commit and push to git repository
	cd $(PROJECT_DIR) && git pull
	cd $(PROJECT_DIR) && git add . && git diff --quiet --exit-code --cached || git commit -m "Publish on $$(date)" -a
	cd $(PROJECT_DIR) && git push
endif

.PHONY : fast_archive
fast_archive:
	if [ ! -d $(PROJECT_DATA_DIR)/archive ] && [ ! -L $(PROJECT_DATA_DIR)/archive ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/archive; \
	fi
	mkdir -p $(PROJECT_DATA_DIR)/archive/$(TIMESTAMP)
	rsync -av -L $(PROJECT_DATA_DIR)/ $(PROJECT_DATA_DIR)/archive/$(TIMESTAMP) \
		--exclude 's3/' --exclude 'archive/' --exclude '.DS_Store'

.PHONY : fast_s3_upload
fast_s3_upload:
ifdef S3_BUCKET
	if [ ! -d $(PROJECT_DATA_DIR)/upload ]  && [ ! -L $(PROJECT_DATA_DIR)/upload ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/s3; \
	fi
	if [ ! -d $(PROJECT_DATA_DIR)/archive ] && [ ! -L $(PROJECT_DATA_DIR)/archive ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/archive; \
	fi
	aws s3 sync $(S3_BUCKET) $(PROJECT_DATA_DIR)/s3 --delete --exclude 'archive/*' # --dryrun
	# backward sync will copy the actual files
	rsync -av --delete --copy-links $(PROJECT_DATA_DIR)/ $(PROJECT_DATA_DIR)/s3 --exclude 's3/' --exclude 'archive/' # --dry-run
	aws s3 sync $(PROJECT_DATA_DIR)/s3 $(S3_BUCKET) --delete --exclude 'archive/*' # --dryrun
	aws s3 sync $(PROJECT_DATA_DIR)/archive $(S3_BUCKET)/archive # --dryrun
endif

.PHONY : fast_s3_download
fast_s3_download:
ifdef S3_BUCKET
	if [ ! -d $(PROJECT_DATA_DIR)/upload ]  && [ ! -L $(PROJECT_DATA_DIR)/upload ]; then \
		mkdir -p $(PROJECT_DATA_DIR)/s3; \
	fi
	aws s3 sync $(S3_BUCKET) $(PROJECT_DATA_DIR)/s3 --delete --exclude 'archive/*' # --dryrun
	# forward sync will follow the symbolinks
	rsync -av --delete --keep-dirlinks $(PROJECT_DATA_DIR)/s3/ $(PROJECT_DATA_DIR) --exclude 's3/' --exclude 'archive/' # --dry-run
endif
print-%:
	@echo '$*:=$($*)'
