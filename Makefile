# default values for 
COURSE_NAME           :=
COURSE_BIB        	  :=
PUBLISH_MATERIALS_DIR :=

MATERIAL_DIR          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifdef COURSE_NAME
MATERIAL_NAME_PREFIX  := $(COURSE_NAME)_$(notdir $(MATERIAL_DIR))
endif


SYLLABUS_READY        := no

SYLLABUS_DIR          := $(MATERIAL_DIR)/docs/syllabus

.PHONY : none
none: ;

.PHONY : init
init:
	find . -name '_*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s]\{1,\}\)/\/$(COURSE_NAME)\1\.\2/g' {} +

	find . \( -name '_*.tex' -o -name '_*.eps' -o -name '_*.tikz' \) \
		 -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;

	rm -rf .git

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