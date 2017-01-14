PROJ_DIR = $(shell pwd)
TMP_DIR_PREFIX = $(PROJ_DIR)/tmp
PARENT_DIR = $(shell dirname $(PROJ_DIR))
PROJ_NAME = $(shell echo $(notdir $(PROJ_DIR)) | sed 's/project_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')
INIT_FILE = .init

REPORT_READY = no
COF_READY = no
JNL_READY = yes
SLD_READY = no

DOC_DIR =$(PROJ_DIR)/__webpages/src/_asset/doc
PAR_DOC_DIR = $(PARENT_DIR)/__webpages/src/_asset/doc
REPORT_DIR =$(PROJ_DIR)/docs/report
COF_DIR =$(PROJ_DIR)/docs/conf
JNL_DIR =$(PROJ_DIR)/docs/jnl
SLD_DIR =$(PROJ_DIR)/docs/slides
REF_DIR =$(PROJ_DIR)/bib
FIG_DIR =$(PROJ_DIR)/figures

tmp_dir = $(addprefix $(TMP_DIR_PREFIX)_,$(notdir $(1)))
pack_name = $(addprefix $(PROJ_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_pack
	# create directory
	mkdir -p $(addprefix $(call tmp_dir, $(1)),/bib)
	mkdir -p $(addprefix $(call tmp_dir, $(1)),/figures)
	# sync files
	cd $(REF_DIR); \
		find . -name '*.bib' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/bib) \;
	cd $(FIG_DIR); \
		find . -name '*.eps' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/figures) \;
	cd $(FIG_DIR); \
		find . -name '*.tikz' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/figures) \;
	cd $(FIG_DIR); \
		find . -name '*.pdf' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/figures) \;
	cd $(1); \
		find . -name '*.cls' -exec rsync -R {} $(call tmp_dir, $(1)) \;
	cd $(1); \
	    find . -name '*.bst' -exec rsync -R {} $(call tmp_dir, $(1)) \;
	cd $(1); \
	    find . -name '*.sty' -exec rsync -R {} $(call tmp_dir, $(1)) \;
	cd $(1); \
	    find . -name '*.tex' -exec rsync -R {} $(call tmp_dir, $(1)) \;

	## correct the path to include figures and bib
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
	#add project title
	find . -name '*.jemdoc' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.jemseg' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.bib' -exec bash -c 'mv {} `dirname {}`/_$(PROJ_NAME)`basename {}`' \;
	find . -name '*.tex' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.eps' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;
	find . -name '*.tikz' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)`basename {}`' \;

	find . -name '*.jemdoc' -exec \
		sed -i '' 's/\([^/]*\.jeminc\)/_$(PROJ_NAME)\1/g' {} +
	find . -name '*.jemdoc' -exec \
		sed -i '' 's/\([^/]*\.bib\)/_$(PROJ_NAME)\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.bib\)/_$(PROJ_NAME)\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.tex\)/$(PROJ_NAME)\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.eps\)/$(PROJ_NAME)\1/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\([^/\s]*\.tikz\)/$(PROJ_NAME)\1/g' {} +

	rm -rf .git
	git init
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : pack
pack:
ifeq ($(REPORT_READY),yes)
	$(call gen_pack, $(REPORT_DIR))
endif

ifeq ($(COF_READY),yes)
	$(call gen_pack, $(COF_DIR))
endif

ifeq ($(JNL_READY),yes)
	$(call gen_pack, $(JNL_DIR))
endif

.PHONY : publish
publish:
ifeq ($(REPORT_READY),yes)
	rsync -P -urvz $(REPORT_DIR)/*.pdf $(DOC_DIR)/
	rsync -P -urvz $(REPORT_DIR)/*.pdf $(PAR_DOC_DIR)/
endif

ifeq ($(COF_READY),yes)
	rsync -P -urvz $(COF_DIR)/*.pdf $(DOC_DIR)/
	rsync -P -urvz $(COF_DIR)/*.pdf $(PAR_DOC_DIR)/
endif

ifeq ($(JNL_READY),yes)
	rsync -P -urvz $(JNL_DIR)/*.pdf $(DOC_DIR)/
	rsync -P -urvz $(JNL_DIR)/*.pdf $(PAR_DOC_DIR)/
endif

ifeq ($(SLD_READY),yes)
	rsync -P -urvz $(SLD_DIR)/*.pdf $(DOC_DIR)/
	rsync -P -urvz $(SLD_DIR)/*.pdf $(PAR_DOC_DIR)/
endif

print-%:
	@echo '$*=$($*)'