OS                            := $(shell uname)
COURSE_DIR                    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_NAME                   := $(subst course_,,$(notdir $(COURSE_DIR)))
MKFILES                       := $(shell find $(COURSE_DIR) -type f -maxdepth 1 -mindepth 1 -name "*.mk")
-include $(MKFILES)

MATERIALS                     := $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name 'materials_*')

MATERIAL_REPO                 := git@github.com:gustybear/project-template.git
MATERIAL_BRANCH               := course_material

CURRICULUM_DIR                := materials_curriculum
PROJECT_DIR                   := materials_project

NUM_OF_WEEKS                  := $(words $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name '*week*'))
NUM_OF_NEXT_WEEKS             := $(shell echo $$(( $(NUM_OF_WEEKS) + 1 )))
NEXT_WEEKS_DIR                := materials_week_$(shell printf "%02d" $(NUM_OF_NEXT_WEEKS))

COURSE_BIB_DIR                := $(COURSE_DIR)/bib

ifdef COURSE_WEBPAGES_READY
COURSE_WEBPAGES_DIR           := $(shell find $(COURSE_DIR) -type d -name __webpages)
endif

ifdef COURSE_WEBPAGES_DIR
WEBPAGES_MAKEFILE             := $(COURSE_WEBPAGES_DIR)/Makefile
WEBPAGES_SRC_DIR              := $(COURSE_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR              := $(COURSE_WEBPAGES_DIR)/des

WEBPAGES_SITECONF             := $(WEBPAGES_SRC_DIR)/site.conf
WEBPAGES_CSS_DIR              := $(WEBPAGES_SRC_DIR)/css
WEBPAGES_FONTS_DIR            := $(WEBPAGES_SRC_DIR)/fonts
WEBPAGES_PICS_DIR             := $(WEBPAGES_SRC_DIR)/pics
endif

.PHONY : clean
clean :
ifdef COURSE_WEBPAGES_DIR
	$(MAKE) -C $(COURSE_WEBPAGES_DIR) clean
endif

.PHONY : init
init:
ifeq ($(OS), Darwin)
	find $(COURSE_DIR) -name '_*.*' -exec \
		sed -i '' 's/COURSE_NAME/$(COURSE_NAME)/g' {} +
else
	find $(COURSE_DIR) -name '_*.*' -exec \
		sed -i 's/COURSE_NAME/$(COURSE_NAME)/g' {} +

endif
	find $(COURSE_DIR) -type f -name '_*.*' \
		 -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;

	test -d "$ZSH_CUSTOM" && \
	find $(COURSE_DIR) - type f -name '*_config.zsh' \
		-exec link -s {} $ZSH_CUSTOM \;

	find $(COURSE_DIR) -name '_MENU' \
		   -exec bash -c 'mv {} `dirname {}`/MENU' \;

	rm -rf $(COURSE_DIR)/.git


.PHONY : add_curriculum
add_curriculum:
	git clone -b $(MATERIAL_BRANCH) $(MATERIAL_REPO) $(CURRICULUM_DIR)
	$(MAKE) -C $(CURRICULUM_DIR) init COURSE_NAME=$(COURSE_NAME)


.PHONY : add_a_week
add_a_week:
	git clone -b $(MATERIAL_BRANCH) $(MATERIAL_REPO) $(NEXT_WEEKS_DIR)
	$(MAKE) -C $(NEXT_WEEKS_DIR) init COURSE_NAME=$(COURSE_NAME)

.PHONY : add_project
add_project:
	git clone -b $(MATERIAL_BRANCH) $(MATERIAL_REPO) $(PROJECT_DIR)
	$(MAKE) -C $(PROJECT_DIR) init COURSE_NAME=$(COURSE_NAME)

.PHONY : pack_materials
pack_materials:
ifneq ($(MATERIALS),)
	for dir in $(MATERIALS); do ($(MAKE) -C $$dir pack_materials COURSE_BIB_DIR=$(COURSE_BIB_DIR) COURSE_NAME=$(COURSE_NAME)); done
endif

.PHONY : publish_materials
publish_materials:
ifneq ($(MATERIALS),)
	for dir in $(MATERIALS); do ($(MAKE) -C $$dir publish_materials PUBLISH_MATERIALS_DIR=$(PUBLISH_MATERIALS_DIR)); done
endif

.PHONY : build_webpages
build_webpages:
ifdef COURSE_WEBPAGES_DIR
	find $(COURSE_BIB_DIR) -type f -exec rsync -urzL {} $(WEBPAGES_SRC_DIR) \;
	rsync -urzL $(WEBPAGES_MAKEFILE) $(COURSE_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	$(MAKE) -C $(COURSE_WEBPAGES_DIR)

ifdef PUBLISH_WEBPAGES_DIR
	if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	rsync -urzL $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_PICS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urzL $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif

.PHONY : update_git_repo
update_git_repo:
ifdef GIT_REPO
	cd $(COURSE_DIR) && git add . && git diff --quiet --exit-code --cached || git commit -m "Publish on $$(date)" -a
	cd $(COURSE_DIR) && git push
endif

print-%:
	@echo '$*=$($*)'
