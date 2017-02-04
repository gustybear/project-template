# input parameters
COURSE_NAME              :=
COURSE_BIB_DIR           :=
PUBLISH_MATERIALS_DIR    :=

# local variables
OS                       := $(shell uname)
MATERIAL_DIR             := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifdef COURSE_NAME
MATERIAL_NAME_PREFIX     := $(COURSE_NAME)_$(notdir $(MATERIAL_DIR))
endif

MATERIAL_DOCS_DIR        := $(MATERIAL_DIR)/docs

###### the default list in the template is:  #########
##    "assg assg_sol quiz quiz_sol notes slides"   ###
###### for instance, if the assg is ready    #########
###### put it after MATERIAL_DOCS_READY      #########
MATERIAL_DOCS_READY      :=
ifdef MATERIAL_DOCS_READY
MATERIAL_DOCS_SUBDIRS    := $(addprefix $(MATERIAL_DOCS_DIR)/,$(MATERIAL_DOCS_READY))
endif

MATERIAL_DOCPACS_READY   := assg
ifdef MATERIAL_DOCPACS_READY
MATERIAL_DOCPACS_SUBDIRS := $(addprefix $(MATERIAL_DOCS_DIR)/,$(MATERIAL_DOCPACS_READY))
endif

ifdef PUBLISH_MATERIALS_DIR
PUBLISTH_DOCS_SUBDIR     := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR     := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR     := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR     := $(PUBLISH_MATERIALS_DIR)/pics
endif

TMP_DIR_PREFIX           := $(MATERIAL_DIR)/tmp

gen_tmp_dir_name         = $(addprefix $(TMP_DIR_PREFIX)_, $(notdir $(1)))
gen_package_name         = $(addprefix $(MATERIAL_NAME_PREFIX)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	mkdir -p $(call gen_tmp_dir_name, $(1))
	# sync other files
	find $(1) $(COURSE_BIB_DIR) -type f \
		-not \( -name "*.zip" -o -name "*.gz" \) \
		-exec rsync -urzL {} $(call gen_tmp_dir_name, $(1)) \;

	# ## correct the path
	if [ $(OS) = Darwin ]; then                                                                \
		find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex'                              \
			-exec sed -i '' 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} + ;\
	else                                                                                       \
		find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex'                              \
			-exec sed -i 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} +    ;\
	fi

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

.PHONY : clear
clear: ;

.PHONY : init
init:
ifeq ($(OS), Darwin)
	find . -type f -name '_*.tex' \
		-exec sed -i '' 's/\/\(_[^.]\{1,\}\)\.\([^ \(bib\)]\{1,\}\)/\/$(MATERIAL_NAME_PREFIX)\1\.\2/g' {} +
	find . -type f -name '_*.tex' \
		-exec sed -i '' 's/\/\(_[^.]\{1,\}\)\.\(bib\)/\/$(COURSE_NAME)\1\.\2/g' {} +
else
	find . -type f -name '_*.tex' \
		-exec sed -i 's/\/\(_[^.]\{1,\}\)\.\([^ \(bib\)]\{1,\}\)/\/$(MATERIAL_NAME_PREFIX)\1\.\2/g' {} +
	find . -type f -name '_*.tex' \
		-exec sed -i 's/\/\(_[^.]\{1,\}\)\.\(bib\)/\/$(COURSE_NAME)\1\.\2/g' {} +
endif

	find . -type f -name '_*.*' \
		   -exec bash -c 'mv {} `dirname {}`/$(MATERIAL_NAME_PREFIX)`basename {}`' \;

	rm -rf .git

.PHONY : pack_materials
pack_materials:
	$(foreach SUBDIR,$(MATERIAL_DOCPACS_SUBDIRS),$(call gen_package,$(SUBDIR));)


.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	$(foreach SUBDIR,$(MATERIAL_DOCS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.pdf" \
			 -exec rsync -urz {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
	$(foreach SUBDIR,$(MATERIAL_DOCPACS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.tar.gz" \
			 -exec rsync -urz {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


print-%:
	@echo '$*:=$($*)'