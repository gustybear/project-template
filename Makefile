MATERIAL_DIR          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
INIT_FILE             := $(MATERIAL_DIR)/.init


SYLLABUS_READY        := no
SYLLABUS_DIR          := $(MATERIAL_DIR)/docs/syllabus

# default values for COURSE_DIR and PUBLISH_MATERIALS_DIR
COURSE_DIR            := ''
PUBLISH_MATERIALS_DIR := ''
ifdef COURSE_DIR
COURSE_NAME           := $(subst course_,,$(notdir $(COURSE_DIR)))
COURSE_BIB_DIR        := $(COURSE_DIR)/bib
MATERIAL_NAME_PREFIX  := $(COURSE_NAME)_$(notdir $(MATERIAL_DIR))
endif

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
ifdef COURSE_NAME
	find . \( -name '*.tex' -o -name '*.eps' -o -name '*.tikz' \) \
		 -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s]\{1,\}\)/\/$(COURSE_NAME)\1\.\2/g' {} +

	rm -rf .git
	$(shell echo yes > $(INIT_FILE))
endif
endif

.PHONY : pack_materials
pack_materials: ;

.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	if [ ! -d $(PUBLISH_MATERIALS_DIR) ]; then mkdir -p $(PUBLISH_MATERIALS_DIR); fi
ifeq ($(SYLLABUS_READY),yes)
	rsync -P -urvz $(SYLLABUS_DIR)/*.pdf $(PUBLISH_MATERIALS_DIR)/doc/
endif
endif

print-%:
	@echo '$*=$($*)'