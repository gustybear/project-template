# default values for 
COURSE_NAME           :=
COURSE_BIB        	  :=
PUBLISH_MATERIALS_DIR :=

MATERIAL_DIR          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifdef COURSE_NAME
MATERIAL_NAME_PREFIX  := $(COURSE_NAME)_materials
endif


SYLLABUS_READY        := no

SYLLABUS_DIR          := $(MATERIAL_DIR)/docs/syllabus

.PHONY : clean
clean: ;

.PHONY : init
init:
	find . -type f -name '_*.tex' \
		-exec sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s\(bib\)]\{1,\}\)/\/$(MATERIAL_NAME_PREFIX)\1\.\2/g' {} +
	find . -type f -name '_*.tex' \
		-exec sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(bib\)/\/$(COURSE_NAME)\1\.\2/g' {} +
	
	find . -type f -name '_*.*' \
	       -exec bash -c 'mv {} `dirname {}`/$(MATERIAL_NAME_PREFIX)`basename {}`' \;

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