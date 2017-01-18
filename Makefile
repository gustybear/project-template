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

ifdef RESEARCH_PROJ_WEBPAGES_DIR
WEBPAGES_CSS_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/config/css
WEBPAGES_FONTS_DIR           := $(RESEARCH_PROJ_WEBPAGES_DIR)/config/fonts
WEBPAGES_MAKEFILE            := $(RESEARCH_PROJ_WEBPAGES_DIR)/config/Makefile
WEBPAGES_SITECONF            := $(RESEARCH_PROJ_WEBPAGES_DIR)/config/site.conf

WEBPAGES_SRC_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/des

WEBPAGES_PIC_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/src/_asset/pic
WEBPAGES_DOC_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/src/_asset/doc
WEBPAGES_CODE_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/src/_asset/code

PUBLISH_WEBPAGES_DIR		 := $(WEBPAGES_DES_DIR)
PUBLISH_MATERIALS_DIR        := $(WEBPAGES_DES_DIR)
endif

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
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISH_MATERIALS_DIR) ]; then mkdir -p $(PUBLISH_MATERIALS_DIR); fi
ifeq ($(RESEARCH_PROJ_REPORT_READY),yes)
	-rsync -urzR $(RESEARCH_PROJ_REPORT_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc
endif

ifeq ($(RESEARCH_PROJ_COF_READY),yes)
	-rsync -urzR $(RESEARCH_PROJ_COF_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc
endif

ifeq ($(RESEARCH_PROJ_JNL_READY),yes)
	-rsync -urzR $(RESEARCH_PROJ_JNL_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc
endif

ifeq ($(RESEARCH_PROJ_SLD_READY),yes)
	-rsync -urzR $(RESEARCH_PROJ_SLD_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc
endif
endif

.PHONY : build_webpages
build_webpages:
ifdef RESEARCH_PROJ_WEBPAGES_DIR
	find $(RESEARCH_PROJ_BIB_DIR) -name '*.bib' -exec rsync -urz {} $(WEBPAGES_SRC_DIR) \;
	rsync -urz $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	rsync -urz $(WEBPAGES_MAKEFILE) $(RESEARCH_PROJ_WEBPAGES_DIR)
	$(MAKE) -C $(RESEARCH_PROJ_WEBPAGES_DIR)

ifneq ($(PUBLISH_WEBPAGES_DIR),$(WEBPAGES_DES_DIR))
	if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	rsync -urz $(WEBPAGES_DES_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzR $(WEBPAGES_PIC_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzR $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzR $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif

.PHONY : clean
clean :
ifdef RESEARCH_PROJ_WEBPAGES_DIR
	$(MAKE) -C $(RESEARCH_PROJ_WEBPAGES_DIR) clean
endif

print-%:
	@echo '$*:=$($*)'