RESEARCH_PROJ_DIR                 := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RESEARCH_PROJ_NAME                := $(shell echo $(notdir $(RESEARCH_PROJ_DIR)) | sed 's/project_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')

INIT_FILE                         := .init

RESEARCH_PROJ_REPORT_READY        := no
RESEARCH_PROJ_COF_READY           := no
RESEARCH_PROJ_JNL_READY           := no
RESEARCH_PROJ_SLD_READY           := no

RESEARCH_PROJ_REPORT_DIR          := $(RESEARCH_PROJ_DIR)/docs/report
RESEARCH_PROJ_COF_DIR             := $(RESEARCH_PROJ_DIR)/docs/conf
RESEARCH_PROJ_JNL_DIR             := $(RESEARCH_PROJ_DIR)/docs/jnl
RESEARCH_PROJ_SLD_DIR             := $(RESEARCH_PROJ_DIR)/docs/slides
RESEARCH_PROJ_BIB_DIR             := $(RESEARCH_PROJ_DIR)/bib
RESEARCH_PROJ_FIG_DIR             := $(RESEARCH_PROJ_DIR)/figures


RESEARCH_PROJ_WEBPAGES_DIR        := $(shell find $(RESEARCH_PROJ_DIR) -type d -name __webpages)
RESEARCH_PROJ_WEBPAGES_SRC_DIR    := $(RESEARCH_PROJ_WEBPAGES_DIR)/src
RESEARCH_PROJ_WEBPAGES_DES_DIR    := $(RESEARCH_PROJ_WEBPAGES_DIR)/des
RESEARCH_PROJ_WEBPAGES_CONFIG_DIR := $(RESEARCH_PROJ_WEBPAGES_DIR)/config
PUBLISH_DIR                       := $(RESEARCH_PROJ_WEBPAGES_SRC_DIR)/des/doc

TMP_DIR_PREFIX                    := $(RESEARCH_PROJ_DIR)/tmp

gen_tmp_dir_name                  = $(addprefix $(TMP_DIR_PREFIX)_,$(notdir $(1)))
gen_package_name                  = $(addprefix $(RESEARCH_PROJ_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	# create directory
	mkdir -p $(addprefix $(call gen_tmp_dir_name, $(1)),/bib)
	mkdir -p $(addprefix $(call gen_tmp_dir_name, $(1)),/figures)
	# sync files
	cd $(RESEARCH_PROJ_BIB_DIR); \
		find . -name '*.bib' -exec rsync -R {} $(addprefix $(call gen_tmp_dir_name, $(1)),/bib) \;
	cd $(RESEARCH_PROJ_FIG_DIR); \
		find . -name '*.eps' -o -name '*.tikz' -exec rsync -R {} $(addprefix $(call gen_tmp_dir_name, $(1)),/figures) \;
	cd $(1); \
		find . -name '*.cls' -o -name '*.bst' -o -name '*.sty' -o -name '*.tex' \
			   -exec rsync -R {} $(call gen_tmp_dir_name, $(1)) \;

	## correct the path to include figures and bib
	find $(call gen_tmp_dir_name, $(1)) -name '*.tex' -exec \
		sed -i '' 's/\(\.\.\/\)\{1,\}/\.\//g' {} +

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	#add project title
	find . \( -name '*.jemdoc' -o -name '*.jemseg' -o -name '*.bib' -o \
	       -name '*.tex' -o -name '*.eps' -o -name '*.tikz' \) \
	       -exec bash -c 'mv {} `dirname {}`/$(RESEARCH_PROJ_NAME)`basename {}`' \;

	find . -name '*.jemdoc' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(jeminc\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -name 'MENU' -exec \
		sed -i '' 's/\[\(_[^\.]\{1,\}\)\.\(html\)/\[$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s]\{1,\}\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +


	rm -rf .git
	git init
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : pack_materials
pack_materials:
ifeq ($(RESEARCH_PROJ_REPORT_READY),yes)
	$(call gen_package, $(RESEARCH_PROJ_REPORT_DIR))
endif

ifeq ($(RESEARCH_PROJ_COF_READY),yes)
	$(call gen_package, $(RESEARCH_PROJ_COF_DIR))
endif

ifeq ($(RESEARCH_PROJ_JNL_READY),yes)
	$(call gen_package, $(RESEARCH_PROJ_JNL_DIR))
endif


.PHONY : publish_materials
publish_materials:
ifeq ($(RESEARCH_PROJ_REPORT_READY),yes)
	-rsync -urz $(RESEARCH_PROJ_REPORT_DIR)/*.pdf $(PUBLISH_DIR)/
endif

ifeq ($(RESEARCH_PROJ_COF_READY),yes)
	-rsync -urz $(RESEARCH_PROJ_COF_DIR)/*.pdf $(PUBLISH_DIR)/
endif

ifeq ($(RESEARCH_PROJ_JNL_READY),yes)
	-rsync -urz $(RESEARCH_PROJ_JNL_DIR)/*.pdf $(PUBLISH_DIR)/
endif

ifeq ($(RESEARCH_PROJ_SLD_READY),yes)
	-rsync -urz $(RESEARCH_PROJ_SLD_DIR)/*.pdf $(PUBLISH_DIR)/
endif

.PHONY : build_webpages: publish_materials
build_webpages: publish_materials
ifdef WEBSITE_CONFIG_DIR
	rsync -urz $(WEBSITE_CONFIG_DIR) $(RESEARCH_PROJ_WEBPAGES_CONFIG_DIR)
endif
	if [ -d $(RESEARCH_PROJ_WEBPAGES_DIR) ]; then \
	find $(RESEARCH_PROJ_BIB_DIR) -name '*.bib' -exec rsync -urz {} $(RESEARCH_PROJ_WEBPAGES_SRC_DIR) \; ; \
	rsync -urz $(RESEARCH_PROJ_WEBPAGES_CONFIG_DIR)/Makefile $(RESEARCH_PROJ_WEBPAGES_DIR) ; \
	rsync -urz $(RESEARCH_PROJ_WEBPAGES_CONFIG_DIR)/site.conf $(RESEARCH_PROJ_WEBPAGES_DIR)/src/ ; \
	rsync -urz $(RESEARCH_PROJ_WEBPAGES_CONFIG_DIR)/css $(RESEARCH_PROJ_WEBPAGES_DIR)/des/ ; \
	rsync -urz $(RESEARCH_PROJ_WEBPAGES_CONFIG_DIR)/fonts $(RESEARCH_PROJ_WEBPAGES_DIR)/des/ ; \
	rsync -urz $$(RESEARCH_PROJ_WEBPAGES_DIR)/src/_asset/* $(RESEARCH_PROJ_WEBPAGES_DIR)/des/ ; \
	$(MAKE) -C $(RESEARCH_PROJ_WEBPAGES_DIR) ; \
	fi

.PHONY : clean
clean :
	if [ -d $(RESEARCH_PROJ_WEBPAGES_DIR) ]; then \
	$(MAKE) -C $(RESEARCH_PROJ_WEBPAGES_DIR) clean ; \
	fi

print-%:
	@echo '$*:=$($*)'