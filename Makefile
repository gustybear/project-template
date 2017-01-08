SYLLABUS_READY = yes

DOC_DIR = ../__webpages/src/_asset/doc
SYLLABUS_DIR = ./docs/syllabus

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	#add project title

	rm -rf .git
	git init
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : publish
publish:
ifeq ($(SYLLABUS_READY),yes)
	rsync -P -urvz $(SYLLABUS_DIR)/*.pdf $(DOC_DIR)/
endif