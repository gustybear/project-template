COURSE_NAME = $(subst course_,,$(notdir $(shell dirname $(shell pwd))))
WEEK_NAME = $(notdir $(shell pwd))
INIT_FILE = .init

SLIDES_READY = no
NOTES_READY = no
QUIZ_READY = no
QUIZ_SOL_READY = no
ASSG_READY = no
ASSG_SOL_READY = no

SLIDES_DIR = ./docs/slides
NOTES_DIR = ./docs/notes
QUIZ_DIR = ./docs/quiz
QUIZ_SOL_DIR = ./docs/quiz_sol
ASSG_DIR = ./docs/assg
ASSG_SOL_DIR = ./docs/assg_sol

DOC_DIR =../__webpages/src/_asset/doc
PIC_DIR =../__webpages/src/_asset/pic
CODES_DIR =../__webpages/src/_asset/codes

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	#add project title
	find . -name '*.tex' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_$(WEEK_NAME)`basename {}`' \;
	find . -name '*.eps' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_$(WEEK_NAME)`basename {}`' \;
	find . -name '*.tikz' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_$(WEEK_NAME)`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.tex\)/$(COURSE_NAME)_$(WEEK_NAME)_\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.eps\)/$(COURSE_NAME)_$(WEEK_NAME)_\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.tikz\)/$(COURSE_NAME)_$(WEEK_NAME)_\1/g' {} +

	rm -rf .git
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : publish
publish:
ifeq ($(SLIDES_READY),yes)
	rsync -P -urvz $(SLIDES_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(NOTES_READY),yes)
	rsync -P -urvz $(NOTES_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(QUIZ_READY),yes)
	rsync -P -urvz $(QUIZ_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(QUIZ_SOL_READY),yes)
	rsync -P -urvz $(QUIZ_SOL_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(ASSG_READY),yes)
	rsync -P -urvz $(ASSG_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(ASSG_SOL_READY),yes)
	rsync -P -urvz $(ASSG_SOL_DIR)/*.pdf $(DOC_DIR)/
endif

print-%:
	@echo '$*=$($*)'