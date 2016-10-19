PROJ_NAME = $(lastword $(subst _, ,$(notdir $(shell pwd))))
INIT_FILE = .init

REPORT_READY = no
COF_READY = no
JNL_READY = no
SLD_READY = no

DOC_DIR =../__webpages/src/_asset/doc
REPORT_DIR =./papers/report
COF_DIR =./papers/conf
JNL_DIR =./papers/jnl
SLD_DIR =./papers/slides

define generate_submit_package
	# create directory
	mkdir -p $(notdir $(1))_submit/ref
	mkdir -p $(notdir $(1))_submit/figures
	# sync files
	find ref -name '*.bib' -exec rsync -R {} $(notdir $(1))_submit \;
	find figures -name '*.eps' -exec rsync -R {} $(notdir $(1))_submit \;
	find figures -name '*.tikz' -exec rsync -R {} $(notdir $(1))_submit \;

	cd $(1) && find . -name '*.cls' -exec rsync -R {} ../../$(notdir $(1))_submit \;
	cd $(1) && find . -name '*.bst' -exec rsync -R {} ../../$(notdir $(1))_submit \;
	cd $(1) && find . -name '*.sty' -exec rsync -R {} ../../$(notdir $(1))_submit \;
	cd $(1) && find . -name '*.tex' -exec rsync -R {} ../../$(notdir $(1))_submit \;
	
	## correct the path to include figures and bib
	find $(notdir $(1))_submit -name '*.tex' -exec \
		sed -i '' 's/\.\.\/\.\.\/figures/\.\/figures/g' {} +

	find $(notdir $(1))_submit -name '*.tex' -exec \
		sed -i '' 's/\.\.\/\.\.\/ref/\.\/ref/g' {} +

	tar -zcvf $(notdir $(1))_submit.tar.gz $(notdir $(1))_submit
	rm -rf $(notdir $(1))_submit
endef

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
	$(shell echo yes >>> $(INIT_FILE))
endif

.PHONY : submit
submit:
ifeq ($(REPORT_READY),yes)
	$(call generate_submit_package, $(REPORT_DIR))
endif

ifeq ($(COF_READY),yes)
	$(call generate_submit_package, $(COF_DIR))
endif

ifeq ($(JNL_READY),yes)
	$(call generate_submit_package, $(JNL_DIR))
endif

.PHONY : publish
publish:
ifeq ($(REPORT_READY),yes)
	rsync -P -urvz $(REPORT_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(COF_READY),yes)
	rsync -P -urvz $(COF_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(JNL_READY),yes)
	rsync -P -urvz $(JNL_DIR)/*.pdf $(DOC_DIR)/
endif

ifeq ($(SLD_READY),yes)
	rsync -P -urvz $(SLD_DIR)/*.pdf $(DOC_DIR)/
endif

print-%:
	@echo '$*=$($*)'