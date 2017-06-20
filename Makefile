OS                          := $(shell uname)
COURSE_DIR                  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_NAME                 := $(subst course_,,$(notdir $(COURSE_DIR)))
MKFILES                     := $(shell find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk")
-include $(MKFILES)

COURSE_MATERIALS            := $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name 'materials_*')

COURSE_MATERIAL_REPO        := git@github.com:gustybear/templates.git
COURSE_MATERIAL_BRANCH      := course_material

COURSE_CURRICULUM_DIR       := materials_curriculum
COURSE_PROJECT_DIR          := materials_project

NUM_OF_WEEKS                := $(words $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name '*week*'))
NUM_OF_NEXT_WEEKS           := $(shell echo $$(( $(NUM_OF_WEEKS) + 1 )))
NEXT_WEEKS_DIR              := materials_week_$(shell printf "%02d" $(NUM_OF_NEXT_WEEKS))

COURSE_BIB_DIR              := $(COURSE_DIR)/bib

ifdef COURSE_WEBPAGES_READY
COURSE_WEBPAGES_DIR         := $(shell find $(COURSE_DIR) -type d -name __webpages)
endif

ifdef COURSE_WEBPAGES_DIR
WEBPAGES_MAKEFILE           := $(COURSE_WEBPAGES_DIR)/Makefile
WEBPAGES_SRC_DIR            := $(COURSE_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR            := $(COURSE_WEBPAGES_DIR)/des

WEBPAGES_SITECONF           := $(WEBPAGES_SRC_DIR)/site.conf
WEBPAGES_CSS_DIR            := $(WEBPAGES_SRC_DIR)/css
WEBPAGES_FONTS_DIR          := $(WEBPAGES_SRC_DIR)/fonts
WEBPAGES_PICS_DIR           := $(WEBPAGES_SRC_DIR)/pics
endif

.PHONY : clean
clean :
ifdef COURSE_WEBPAGES_DIR
	$(MAKE) -C $(COURSE_WEBPAGES_DIR) clean
endif

.PHONY : init init_files link_files prepare_git

init: init_files link_files prepare_git

init_files:
ifneq ($(COURSE_MATERIALS),)
	for dir in $(COURSE_MATERIALS); do ($(MAKE) -C $$dir init_files COURSE_NAME=$(COURSE_NAME)); done
endif
	find $(COURSE_DIR) -type f \
		\( -name '_*.tex' -o -name '_*.bib' -o \
		   -name '_*.jem*' -o -name '_MENU' -o \
		   -name '_*.*sh' \) \
		-exec sed -i.bak 's/COURSE_NAME/$(COURSE_NAME)/g' {} \;
	find $(COURSE_DIR) -type f -name '*.bak' -exec rm -f {} \;

	find $(COURSE_DIR) -type f -name '_*.*' \
		-exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;

	find $(COURSE_DIR) -name '_MENU' \
		   -exec bash -c 'mv {} `dirname {}`/MENU' \;

link_files:
ifdef ZSH_CUSTOM
ifneq ($(COURSE_MATERIALS),)
	for dir in $(COURSE_MATERIALS); do ($(MAKE) -C $$dir link_files); done
endif
	find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name '*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

prepare_git:
	rm -rf $(COURSE_DIR)/.git


.PHONY : add_curriculum
add_curriculum:
	git clone -b $(COURSE_MATERIAL_BRANCH) $(COURSE_MATERIAL_REPO) $(COURSE_CURRICULUM_DIR)
	$(MAKE) -C $(COURSE_CURRICULUM_DIR) init COURSE_NAME=$(COURSE_NAME)

.PHONY : add_a_week
add_a_week:
	git clone -b $(COURSE_MATERIAL_BRANCH) $(COURSE_MATERIAL_REPO) $(NEXT_WEEKS_DIR)
	$(MAKE) -C $(NEXT_WEEKS_DIR) init COURSE_NAME=$(COURSE_NAME)

.PHONY : add_project
add_project:
	git clone -b $(COURSE_MATERIAL_BRANCH) $(COURSE_MATERIAL_REPO) $(COURSE_PROJECT_DIR)
	$(MAKE) -C $(COURSE_PROJECT_DIR) init COURSE_NAME=$(COURSE_NAME)

.PHONY : pack_materials
pack_materials:
ifneq ($(COURSE_MATERIALS),)
	for dir in $(COURSE_MATERIALS); do ($(MAKE) -C $$dir pack_materials COURSE_BIB_DIR=$(COURSE_BIB_DIR) COURSE_NAME=$(COURSE_NAME)); done
endif

.PHONY : publish_materials
publish_materials:
ifneq ($(COURSE_MATERIALS),)
	for dir in $(COURSE_MATERIALS); do ($(MAKE) -C $$dir publish_materials PUBLISH_MATERIALS_DIR=$(PUBLISH_MATERIALS_DIR)); done
endif

.PHONY : build_webpages
build_webpages:
ifdef COURSE_WEBPAGES_DIR
	find $(COURSE_BIB_DIR) -type f -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	rsync -rzL $(WEBPAGES_MAKEFILE) $(COURSE_WEBPAGES_DIR)
	rsync -rzL $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	$(MAKE) -C $(COURSE_WEBPAGES_DIR)

ifdef PUBLISH_WEBPAGES_DIR
	if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	rsync -urzL $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_PICS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif

.PHONY : course_offline
course_offline:
ifneq ($(COURSE_MATERIALS),)
	for dir in $(COURSE_MATERIALS); do ($(MAKE) -C $$dir fast_archive); done
endif
	find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		   -exec bash -c 'mv {} `dirname {}`/inputs.mk.bak' \;

.PHONY : course_online
course_online:
ifneq ($(COURSE_MATERIALS),)
	for dir in $(COURSE_MATERIALS); do ($(MAKE) -C $$dir fast_unarchive); done
endif
	find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk.bak" \
		   -exec bash -c 'mv {} `dirname {}`/inputs.mk' \;

print-%:
	@echo '$*=$($*)'
