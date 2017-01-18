INIT_FILE := .init

SYLLABUS_DIR = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))/docs/syllabus

SYLLABUS_READY = no

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