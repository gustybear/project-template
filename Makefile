MATERIAL_DIR = $(shell pwd)
COURSE_DIR = $(shell dirname $(MATERIAL_DIR))
COURSE_NAME = $(subst course_,,$(notdir $(COURSE_DIR)))
INIT_FILE := .init

DOC_DIR = $(COURSE_DIR)/__webpages/src/_asset/doc
SYLLABUS_DIR = $(MATERIAL_DIR)/docs/syllabus

SYLLABUS_READY = no

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	#add project title

	find . -name '*.tex' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;
	find . -name '*.eps' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;
	find . -name '*.tikz' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/]*\.tex\)/$(COURSE_NAME)\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/]*\.eps\)/$(COURSE_NAME)\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/]*\.tikz\)/$(COURSE_NAME)\1/g' {} +

	rm -rf .git
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : pack
pack: ;

.PHONY : publish
publish:
ifeq ($(SYLLABUS_READY),yes)
	rsync -P -urvz $(SYLLABUS_DIR)/*.pdf $(DOC_DIR)/
endif

print-%:
	@echo '$*=$($*)'