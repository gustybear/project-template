# default values for 
COURSE_NAME           :=
COURSE_BIB        	  :=
PUBLISH_MATERIALS_DIR :=

MATERIAL_DIR          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifdef COURSE_NAME
MATERIAL_NAME_PREFIX  := $(COURSE_NAME)_$(notdir $(MATERIAL_DIR))
endif


SLIDES_READY          := no
NOTES_READY           := no
QUIZ_READY            := no
QUIZ_SOL_READY        := no
ASSG_READY            := no
ASSG_SOL_READY        := no

SLIDES_DIR            := $(MATERIAL_DIR)/docs/slides
NOTES_DIR             := $(MATERIAL_DIR)/docs/notes
QUIZ_DIR              := $(MATERIAL_DIR)/docs/quiz
QUIZ_SOL_DIR          := $(MATERIAL_DIR)/docs/quiz_sol
ASSG_DIR              := $(MATERIAL_DIR)/docs/assg
ASSG_SOL_DIR          := $(MATERIAL_DIR)/docs/assg_sol

TMP_DIR_PREFIX        := $(MATERIAL_DIR)/tmp

gen_tmp_dir_name     = $(addprefix $(TMP_DIR_PREFIX)_, $(notdir $(1)))
gen_package_name     = $(addprefix $(MATERIAL_NAME_PREFIX)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	# sync other files
	cd $(1); \
		find . \( -name '*.doc' -o -name '*.docx' -o -name '*.tex' -o -name '*.pdf' \) \
			-exec rsync -R {} $(call gen_tmp_dir_name, $(1)) \;

	# sync bib files
	rsync -R $(COURSE_BIB) $(call gen_tmp_dir_name, $(1))

	# ## correct the path to include bib
	find $(call gen_tmp_dir_name, $(1)) -name '*.tex' -exec \
		sed -i '' 's/{.*\/\([^/]\{1,\}\)\.bib/{\1\.bib/g' {} +

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

.PHONY : none
none: ;

.PHONY : init
init:
	find . -name '_*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s\(bib\)]\{1,\}\)/\/$(MATERIAL_NAME_PREFIX)\1\.\2/g' {} +
	find . -name '_*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(bib\)/\/$(COURSE_NAME)\1\.\2/g' {} +
	
	find . \( -name '_*.tex' -o -name '_*.eps' -o -name '_*.tikz' \) \
	       -exec bash -c 'mv {} `dirname {}`/$(MATERIAL_NAME_PREFIX)`basename {}`' \;

	rm -rf .git

.PHONY : pack_materials
pack_materials:
ifeq ($(ASSG_READY),yes)
	$(call gen_package, $(ASSG_DIR))
endif

.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISH_MATERIALS_DIR) ]; then mkdir -p $(PUBLISH_MATERIALS_DIR); fi
ifeq ($(SLIDES_READY),yes)
	-rsync -P -urvz $(SLIDES_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc/
endif

ifeq ($(NOTES_READY),yes)
	-rsync -P -urvz $(NOTES_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc/
endif

ifeq ($(QUIZ_READY),yes)
	-rsync -P -urvz $(QUIZ_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc/
endif

ifeq ($(QUIZ_SOL_READY),yes)
	-rsync -P -urvz $(QUIZ_SOL_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc/
endif

ifeq ($(ASSG_READY),yes)
	-rsync -P -urvz $(ASSG_DIR)/*.tar.gz $(PUBLISH_MATERIALS_DIR)/doc/
endif

ifeq ($(ASSG_SOL_READY),yes)
	-rsync -P -urvz $(ASSG_SOL_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc/
endif
endif

print-%:
	@echo '$*:=$($*)'