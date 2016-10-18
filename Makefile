PROJ_NAME = $(lastword $(subst _, ,$(notdir $(shell pwd))))

COF_READY = yes
JNL_READY = no
SLD_READY = no

DOC_DIR =../__webpages/src/_asset/doc
COF_DIR =./conf
JNL_DIR =./jnl
SLD_DIR =./slides

define generate_submit_package
	# create directory
	mkdir -p $(1)_submit/ref
	mkdir -p $(1)_submit/figures
	# sync files
	find ref -name '*.bib' -exec rsync -R {} $(1)_submit \;
	find figures -name '*.eps' -exec rsync -R {} $(1)_submit \;
	find figures -name '*.tikz' -exec rsync -R {} $(1)_submit \;

	find $(1) -name '*.cls' -exec rsync -R {} $(1)_submit \;
	find $(1) -name '*.bst' -exec rsync -R {} $(1)_submit \;
	find $(1) -name '*.sty' -exec rsync -R {} $(1)_submit \;
	find $(1) -name '*.tex' -exec rsync -R {} $(1)_submit \;
	
	## correct the path to include figures and bib
	find $(1)_submit -name '*.tex' -exec \
		sed -i '' 's/\.\.\/figures/\.\/figures/g' {} +

	find $(1)_submit -name '*.tex' -exec \
		sed -i '' 's/\.\.\/ref/\.\/ref/g' {} +

	tar -zcvf $(1)_submit.tar.gz $(1)_submit
	rm -rf $(1)_submit
endef

.PHONY : init
init:
	#set -x
	find . -name '*.tex' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)_`basename {}`' \;
	find . -name '*.bib' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)_`basename {}`' \;
	find . -name '*.eps' -exec bash -c 'mv {} `dirname {}`/$(PROJ_NAME)_`basename {}`' \;
	rm -rf .git
	git init


.PHONY : submit
submit:
ifeq ($(COF_READY),yes)
	$(call generate_submit_package, $(COF_DIR))
endif

ifeq ($(JNL_READY),yes)
	$(call generate_submit_package, $(JNL_DIR))
endif

.PHONY : publish
publish:
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