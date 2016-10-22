SLIDES_READY = no
NOTES_READY = no
CODES_READY = no
PROBLEMS_READY = no
SOLUTION_READY = no

SLIDES_DIR = ./slides
NOTES_DIR = ./notes
CODES_DIR = ./codes
PROBLEMS_DIR = ./problems
SOLUTIONS_DIR = ./solutions

DOC_DIR =../__webpages/src/_asset/doc
PIC_DIR =../__webpages/src/_asset/pic
CODES_DIR =../__webpages/src/_asset/codes

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	#add project title
	find . -name '*.tex' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.bib' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.eps' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.tikz' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\/_ref/\/$(PROJ_NAME)_ref/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/_slides/\/$(PROJ_NAME)_slides/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/_report/\/$(PROJ_NAME)_conf/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/_conf/\/$(PROJ_NAME)_conf/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/_jnl/\/$(PROJ_NAME)_jnl/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/_fig/\/$(PROJ_NAME)_fig/g' {} +

	rm -rf .git
	git init
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

ifeq ($(CODES_READY),yes)
	rsync -P -urvz $(CODES_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(PROBLEMS_READY),yes)
	rsync -P -urvz $(PROBLEMS_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(SOLUTIONS_DIR),yes)
	rsync -P -urvz $(SOLUTIONS_DIR)/*.pdf $(DOC_DIR)/
endif