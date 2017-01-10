COURSE_NAME = $(subst course_,,$(notdir $(shell dirname $(shell pwd))))
SYLLABUS_READY = yes

DOC_DIR = ../__webpages/src/_asset/doc
SYLLABUS_DIR = ./docs/syllabus

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	#add project title

	find . -name '*.tex' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_`basename {}`' \;
	find . -name '*.eps' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_`basename {}`' \;
	find . -name '*.tikz' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/]\+\.tex\)/$(COURSE_NAME)_\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/]\+\.eps\)/$(COURSE_NAME)_\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/]\+\.tikz\)/$(COURSE_NAME)_\1/g' {} +

	rm -rf .git
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : publish
publish:
ifeq ($(SYLLABUS_READY),yes)
	rsync -P -urvz $(SYLLABUS_DIR)/*.pdf $(DOC_DIR)/
endif