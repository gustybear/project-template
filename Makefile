RESEARCH_PROJ_DIR     := $(shell pwd)
PACK_DIR_PREFIX       := $(RESEARCH_PROJ_DIR)/tmp
RESEARCH_PROJ_NAME    := $(shell echo $(notdir $(RESEARCH_PROJ_DIR)) | sed 's/project_[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_//g')
INIT_FILE             := .init

RESEARCH_REPORT_READY := no
RESEARCH_COF_READY    := no
RESEARCH_JNL_READY    := no
RESEARCH_SLD_READY    := no

WEBPAGES_SRC_DIR      := $(RESEARCH_PROJ_DIR)/__webpages/src
WEBPAGES_DOC_DIR      := $(WEBPAGES_SRC_DIR)/_asset/doc
RESEARCH_REPORT_DIR   := $(RESEARCH_PROJ_DIR)/docs/report
RESEARCH_COF_DIR      := $(RESEARCH_PROJ_DIR)/docs/conf
RESEARCH_JNL_DIR      := $(RESEARCH_PROJ_DIR)/docs/jnl
RESEARCH_SLD_DIR      := $(RESEARCH_PROJ_DIR)/docs/slides
RESEARCH_BIB_DIR      := $(RESEARCH_PROJ_DIR)/bib
RESEARCH_FIG_DIR      := $(RESEARCH_PROJ_DIR)/figures

PUBLISH_DIR           := $(WEBPAGES_DOC_DIR)

tmp_dir               := $(addprefix $(PACK_DIR_PREFIX)_,$(notdir $(1)))
pack_name             := $(addprefix $(RESEARCH_PROJ_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_pack
	# create directory
	mkdir -p $(addprefix $(call tmp_dir, $(1)),/bib)
	mkdir -p $(addprefix $(call tmp_dir, $(1)),/figures)
	# sync files
	cd $(RESEARCH_BIB_DIR); \
		find . -name '*.bib' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/bib) \;
	cd $(RESEARCH_FIG_DIR); \
		find . -name '*.eps' -o -name '*.tikz' -exec rsync -R {} $(addprefix $(call tmp_dir, $(1)),/figures) \;
	cd $(1); \
		find . -name '*.cls' -o -name '*.bst' -o -name '*.sty' -o -name '*.tex' \
			   -exec rsync -R {} $(call tmp_dir, $(1)) \;

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
	find . \( -name '*.jemdoc' -o -name '*.jemseg' -o -name '*.bib' -o \
	       -name '*.tex' -o -name '*.eps' -o -name '*.tikz' \) \
	       -exec bash -c 'mv {} `dirname {}`/$(RESEARCH_PROJ_NAME)`basename {}`' \;

	find . -name '*.jemdoc' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(jeminc\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -name 'MENU' -exec \
		sed -i '' 's/\[\(_[^\.]\{1,\}\)\.\(html\)/\[$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +
	find . -name '*.tex' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\([^\s]\{1,\}\)/\/$(RESEARCH_PROJ_NAME)\1\.\2/g' {} +


	rm -rf .git
	git init
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : pack
pack:
ifeq ($(RESEARCH_REPORT_READY),yes)
	$(call gen_pack, $(RESEARCH_REPORT_DIR))
endif

ifeq ($(RESEARCH_COF_READY),yes)
	$(call gen_pack, $(RESEARCH_COF_DIR))
endif

ifeq ($(RESEARCH_JNL_READY),yes)
	$(call gen_pack, $(RESEARCH_JNL_DIR))
endif

.PHONY : publish
publish:
	find $(RESEARCH_BIB_DIR) -name '*.bib' -exec rsync -urz {} $(WEBPAGES_SRC_DIR) \;
ifeq ($(RESEARCH_REPORT_READY),yes)
	-rsync -urz $(RESEARCH_REPORT_DIR)/*.pdf $(PUBLISH_DIR)/
endif

ifeq ($(RESEARCH_COF_READY),yes)
	-rsync -urz $(RESEARCH_COF_DIR)/*.pdf $(PUBLISH_DIR)/
endif

ifeq ($(RESEARCH_JNL_READY),yes)
	-rsync -urz $(RESEARCH_JNL_DIR)/*.pdf $(PUBLISH_DIR)/
endif

ifeq ($(RESEARCH_SLD_READY),yes)
	-rsync -urz $(RESEARCH_SLD_DIR)/*.pdf $(PUBLISH_DIR)/
endif

print-%:
	@echo '$*:=$($*)'