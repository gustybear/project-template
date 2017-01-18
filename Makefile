MATERIAL_DIR         := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifdef COURSE_DIR
COURSE_NAME          := $(subst course_,,$(notdir $(COURSE_DIR)))
COURSE_BIB_DIR       := $(COURSE_DIR)/bib
MATERIAL_NAME_PREFIX := $(COURSE_NAME)_$(notdir $(MATERIAL_DIR))
endif

INIT_FILE            := .init

SLIDES_READY         := yes
NOTES_READY          := no
QUIZ_READY           := no
QUIZ_SOL_READY       := no
ASSG_READY           := yes
ASSG_SOL_READY       := no

SLIDES_DIR           := $(MATERIAL_DIR)/docs/slides
NOTES_DIR            := $(MATERIAL_DIR)/docs/notes
QUIZ_DIR             := $(MATERIAL_DIR)/docs/quiz
QUIZ_SOL_DIR         := $(MATERIAL_DIR)/docs/quiz_sol
ASSG_DIR             := $(MATERIAL_DIR)/docs/assg
ASSG_SOL_DIR         := $(MATERIAL_DIR)/docs/assg_sol

TMP_DIR_PREFIX       := $(MATERIAL_DIR)/tmp

gen_tmp_dir_name     = $(addprefix $(TMP_DIR_PREFIX)_, $(notdir $(1)))
gen_package_name     = $(addprefix $(MATERIAL_NAME_PREFIX)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	# create directory
	mkdir -p $(addprefix $(call gen_tmp_dir_name, $(1)),/bib)
	# sync files

	cd $(COURSE_BIB_DIR); \
		find . -name '*.bib' -exec rsync -R {} $(addprefix $(call gen_tmp_dir_name, $(1)),/bib) \;

	cd $(1); \
		find . \( -name '*.doc' -o -name '*.docx' -o -name '*.tex' -o -name '*.pdf' \) \
			-exec rsync -R {} $(call gen_tmp_dir_name, $(1)) \;
	# ## correct the path to include bib

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
ifdef COURSE_NAME
	find . \( -name '*.tex' -o -name '*.eps' -o -name '*.tikz' \) \
	       -exec bash -c 'mv {} `dirname {}`/$(MATERIAL_NAME_PREFIX)`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s\(bib\)]\{1,\}\)/\/$(MATERIAL_NAME_PREFIX)\1\.\2/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(bib\)/\/$(COURSE_NAME)\1\.\2/g' {} +

	rm -rf .git
	$(shell echo yes > $(INIT_FILE))
endif
endif

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