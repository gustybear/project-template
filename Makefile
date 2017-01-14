MATERIAL_DIR = $(shell pwd)
TMP_DIR_PREFIX = $(MATERIAL_DIR)/tmp
WEEK_NAME = $(notdir $(MATERIAL_DIR))
COURSE_DIR = $(shell dirname $(MATERIAL_DIR))
COURSE_REF_DIR = $(COURSE_DIR)/bib
COURSE_NAME = $(subst course_,,$(notdir $(COURSE_DIR)))
MATERIAL_NAME_PREFIX = $(COURSE_NAME)_$(WEEK_NAME)
INIT_FILE = .init

SLIDES_READY = no
NOTES_READY = no
QUIZ_READY = no
QUIZ_SOL_READY = no
ASSG_READY = no
ASSG_SOL_READY = no

SLIDES_DIR = $(MATERIAL_DIR)/docs/slides
NOTES_DIR = $(MATERIAL_DIR)/docs/notes
QUIZ_DIR = $(MATERIAL_DIR)/docs/quiz
QUIZ_SOL_DIR = $(MATERIAL_DIR)/docs/quiz_sol
ASSG_DIR = $(MATERIAL_DIR)/docs/assg
ASSG_SOL_DIR = $(MATERIAL_DIR)/docs/assg_sol

DOC_DIR = $(COURSE_DIR)/__webpages/src/_asset/doc
PIC_DIR = $(COURSE_DIR)/__webpages/src/_asset/pic
CODES_DIR = $(COURSE_DIR)/__webpages/src/_asset/codes

tmp_dir = $(addprefix $(TMP_DIR_PREFIX)_,$(notdir $(1)))
pack_name = $(addprefix $(MATERIAL_NAME_PREFIX)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_pack
	# create directory
	mkdir -p $(addprefix $(call tmp_dir, $(1)),/bib)
	# sync files
	find $(COURSE_BIB_DIR) -name '*.bib' -exec \
		cp {} $(call tmp_dir,$(1)) \;

	cd $(REF_DIR); \
		find . -name '*.bib' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/bib) \;

	cd $(1); \
		find . -name '*.doc' -exec rsync -R {} $(call tmp_dir, $(1)) \;
	cd $(1); \
		find . -name '*.docx' -exec rsync -R {} $(call tmp_dir, $(1)) \;
	cd $(1); \
		find . -name '*.tex' -exec rsync -R {} $(call tmp_dir, $(1)) \;
	cd $(1); \
		find . -name '*.pdf' -exec rsync -R {} $(call tmp_dir, $(1)) \;	
	# ## correct the path to include bib

	find $(call tmp_dir, $(1)) -name '*.tex' -exec \
		sed -i '' 's/\(\.\.\/\)\{1,\}/\.\//g' {} +

	cd $(call tmp_dir, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call pack_name,$(1))) *
	rm -rf $(call tmp_dir, $(1))
endef

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	find . \( -name '*.tex' -o -name '*.eps' -o -name '*.tikz' \) \
	       -exec bash -c 'mv {} `dirname {}`/$(MATERIAL_NAME_PREFIX)`basename {}`' \;

	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s\(bib\)]\{1,\}\)/\/$(MATERIAL_NAME_PREFIX)\1\.\2/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(bib\)/\/$(COURSE_NAME)\1\.\2/g' {} +

	rm -rf .git
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : pack
pack:
ifeq ($(ASSG_READY),yes)
	$(call gen_pack, $(ASSG_DIR))
endif

.PHONY : publish
publish:
ifeq ($(SLIDES_READY),yes)
	-rsync -P -urvz $(SLIDES_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(NOTES_READY),yes)
	-rsync -P -urvz $(NOTES_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(QUIZ_READY),yes)
	-rsync -P -urvz $(QUIZ_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(QUIZ_SOL_READY),yes)
	-rsync -P -urvz $(QUIZ_SOL_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(ASSG_READY),yes)
	-rsync -P -urvz $(ASSG_DIR)/*.tar.gz $(DOC_DIR)/
endif

ifeq ($(ASSG_SOL_READY),yes)
	-rsync -P -urvz $(ASSG_SOL_DIR)/*.pdf $(DOC_DIR)/
endif

print-%:
	@echo '$*=$($*)'