#input parameters
PUBLISH_WEBPAGES_DIR         :=
PUBLISH_MATERIALS_DIR        :=

#local variables
OS                           := $(shell uname)
RESEARCH_PROJ_DIR            := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RESEARCH_PROJ_NAME           := $(shell echo $(notdir $(RESEARCH_PROJ_DIR)) | sed 's/project_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')

RESEARCH_PROJ_BIB_DIR        := $(RESEARCH_PROJ_DIR)/bib
RESEARCH_PROJ_FIG_DIR        := $(RESEARCH_PROJ_DIR)/figures
RESEARCH_PROJ_FIG_DRAW_DIR   := $(RESEARCH_PROJ_DIR)/figures/draw
RESEARCH_PROJ_DOCS_DIR       := $(RESEARCH_PROJ_DIR)/docs

###### change this part to fit the project   #########
###### the default list in the template is:  #########
######      "report conf jnl slides"         #########
###### for instance, if the report is ready  #########
###### put it after RESEARCH_PROJ_DOCS_READY #########
RESEARCH_PROJ_DOCS_READY     :=
ifdef RESEARCH_PROJ_DOCS_READY
RESEARCH_PROJ_DOCS_SUBDIRS   := $(addprefix $(RESEARCH_PROJ_DOCS_DIR)/,$(RESEARCH_PROJ_DOCS_READY))
endif
###################################################

ifdef PUBLISH_MATERIALS_DIR
PUBLISTH_DOCS_SUBDIR         := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR         := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR         := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR         := $(PUBLISH_MATERIALS_DIR)/pics
endif

###### set this flag when the webpage is ready ########
RESEARCH_PROJ_WEBPAGES_READY :=
#######################################################
ifdef RESEARCH_PROJ_WEBPAGES_READY
RESEARCH_PROJ_WEBPAGES_DIR   := $(shell find $(RESEARCH_PROJ_DIR) -type d -name "__webpages")
endif

ifdef RESEARCH_PROJ_WEBPAGES_DIR
WEBPAGES_MAKEFILE            := $(RESEARCH_PROJ_WEBPAGES_DIR)/Makefile
WEBPAGES_SRC_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR             := $(RESEARCH_PROJ_WEBPAGES_DIR)/des

WEBPAGES_SITECONF            := $(WEBPAGES_SRC_DIR)/site.conf
WEBPAGES_CSS_DIR             := $(WEBPAGES_SRC_DIR)/css
WEBPAGES_FONTS_DIR           := $(WEBPAGES_SRC_DIR)/fonts
WEBPAGES_PICS_DIR            := $(WEBPAGES_SRC_DIR)/pics
endif

TMP_DIR_PREFIX               := $(RESEARCH_PROJ_DIR)/tmp

gen_tmp_dir_name             = $(addprefix $(TMP_DIR_PREFIX)_,$(notdir $(1)))
gen_package_name             = $(addprefix $(RESEARCH_PROJ_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	mkdir -p $(call gen_tmp_dir_name, $(1))
	find $(1) $(RESEARCH_PROJ_BIB_DIR) $(RESEARCH_PROJ_FIG_DIR) \
		 -not \( -path $(RESEARCH_PROJ_FIG_DRAW_DIR) -prune \) \
		 -type f \
		 -exec rsync -urzL {} $(call gen_tmp_dir_name, $(1)) \;

	# correct the path
ifeq ($(OS), Darwin)
	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex' \
		-exec sed -i '' 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} +

	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex' \
		-exec sed -i '' 's/^\\usepackage.*{epstopdf}/\\usepackage{epstopdf}/g' {} +
else
	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex' \
		-exec sed -i 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} +

	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex' \
		-exec sed -i 's/^\\usepackage.*{epstopdf}/\\usepackage{epstopdf}/g' {} +
endif

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef


.PHONY : clean
clean :
ifdef RESEARCH_PROJ_WEBPAGES_DIR
	$(MAKE) -C $(RESEARCH_PROJ_WEBPAGES_DIR) clean
endif


.PHONY : init
init:
ifeq ($(OS), Darwin)
	find . -type f -name '_*.jemdoc' \
		-exec sed -i '' 's/\/\(_[^.]\{1,\}\)\.\(jeminc\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -type f -name '_MENU' \
		-exec sed -i '' 's/\[\(_[^.]\{1,\}\)\.\(html\)/\[$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -type f -name '_*.tex' \
		-exec sed -i '' 's/\/\(_[^.]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
else
	find . -type f -name '_*.jemdoc' \
		-exec sed -i 's/\/\(_[^.]\{1,\}\)\.\(jeminc\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -type f -name '_MENU' \
		-exec sed -i 's/\[\(_[^.]\{1,\}\)\.\(html\)/\[$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -type f -name '_*.tex' \
		-exec sed -i 's/\/\(_[^.]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
endif
	find . -type f -name '_*.*' \
		-exec bash -c 'mv {} `dirname {}`/$(RESEARCH_PROJ_NAME)`basename {}`' \;

	find . -type f -name '_MENU' \
		-exec bash -c 'mv {} `dirname {}`/MENU' \;

	rm -rf .git
	git init


.PHONY : pack_materials
pack_materials:
	$(foreach SUBDIR,$(RESEARCH_PROJ_DOCS_SUBDIRS),$(call gen_package,$(SUBDIR));)


.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	$(foreach SUBDIR,$(RESEARCH_PROJ_DOCS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.pdf" \
		     -exec rsync -urzL {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


.PHONY : build_webpages
build_webpages:
ifdef RESEARCH_PROJ_WEBPAGES_DIR
	find $(RESEARCH_PROJ_BIB_DIR) -type f -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	rsync -urzL $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	rsync -urzL $(WEBPAGES_MAKEFILE) $(RESEARCH_PROJ_WEBPAGES_DIR)
	$(MAKE) -C $(RESEARCH_PROJ_WEBPAGES_DIR)

ifdef PUBLISH_WEBPAGES_DIR
	if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	rsync -urzL $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_PICS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif


print-%:
	@echo '$*:=$($*)'