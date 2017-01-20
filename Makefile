# input parameters
COURSE_NAME           :=
COURSE_BIB_DIR        :=
PUBLISH_MATERIALS_DIR :=

# local variables
OS                    := $(shell uname)
MATERIAL_DIR          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifdef COURSE_NAME
MATERIAL_NAME_PREFIX  := $(COURSE_NAME)_$(notdir $(MATERIAL_DIR))
endif

MATERIAL_DOCS_DIR     := $(MATERIAL_DIR)/docs

PUBLISTH_DOCS_SUBDIR  := docs
PUBLISTH_CODE_SUBDIR  := codes
PUBLISTH_DATA_SUBDIR  := data

###### the default list in the template is:  #########
######               "syllabus"              #########
###### for instance, if the report is ready  #########
###### put it after MATERIAL_DOCS_READY      #########
MATERIAL_DOCS_READY   := 
ifdef MATERIAL_DOCS_READY
MATERIAL_DOCS_SUBDIRS := $(addprefix $(MATERIAL_DOCS_DIR)/,$(MATERIAL_DOCS_READY))
endif

define gen_package
	mkdir -p $(call gen_tmp_dir_name, $(1))
	# sync other files
	find $(1) $(COURSE_BIB_DIR) -type f \
		-exec rsync -urzL {} $(call gen_tmp_dir_name, $(1)) \;

	# ## correct the path
ifeq ($(OS), Darwin)
	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex' \
		-exec sed -i '' 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} +
else
	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex' \
		-exec sed -i 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} +
endif

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef


.PHONY : clean
clean: ;


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
	$(foreach SUBDIR,$(MATERIAL_DOCS_SUBDIRS),$(call gen_package,$(SUBDIR));)


.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISH_MATERIALS_DIR) ]; then mkdir -p $(PUBLISH_MATERIALS_DIR); fi
	$(foreach SUBDIR,$(MATERIAL_DOCS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.pdf" \
		     -exec rsync -urzL {} $(PUBLISH_MATERIALS_DIR)/$(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


print-%:
	@echo '$*=$($*)'