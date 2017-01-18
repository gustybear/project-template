COURSE_DIR               := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_NAME              := $(subst course_,,$(notdir $(COURSE_DIR)))
MATERIALS                := $(shell find $(COURSE_DIR) -type d -name 'materials_*')
INIT_FILE                := .init

GIT_REPO                 := git@github.com:gustybear/project-template.git
GIT_BRANCH_SYLLABUS      := course_syllabus
GIT_BRANCH_COURSE_WEEKLY := course_weekly

SYLLABUS_DIR             := materials_syllabus

NUM_OF_WEEKS             := $(words $(shell find $(COURSE_DIR) -type d -name '*week*'))
NUM_OF_NEXT_WEEKS        := $(shell echo $$(( $(NUM_OF_WEEKS) + 1 )))
NEXT_WEEKS_DIR           := materials_week_$(shell printf "%02d" $(NUM_OF_NEXT_WEEKS))

COURSE_WEBPAGES_DIR      := $(shell find $(COURSE_DIR) -type d -name __webpages)

ifdef COURSE_WEBPAGES_DIR
WEBPAGES_CSS_DIR         := $(COURSE_WEBPAGES_DIR)/config/css
WEBPAGES_FONTS_DIR       := $(COURSE_WEBPAGES_DIR)/config/fonts
WEBPAGES_MAKEFILE        := $(COURSE_WEBPAGES_DIR)/config/Makefile
WEBPAGES_SITECONF        := $(COURSE_WEBPAGES_DIR)/config/site.conf

WEBPAGES_SRC_DIR         := $(COURSE_WEBPAGES_DIR)/src
WEBPAGES_DES_DIR         := $(COURSE_WEBPAGES_DIR)/des

WEBPAGES_PIC_DIR         := $(COURSE_WEBPAGES_DIR)/src/_asset/pic
WEBPAGES_DOC_DIR         := $(COURSE_WEBPAGES_DIR)/src/_asset/doc
WEBPAGES_CODE_DIR        := $(COURSE_WEBPAGES_DIR)/src/_asset/code

PUBLISH_WEBPAGES_DIR     := $(WEBPAGES_DES_DIR)
PUBLISH_MATERIALS_DIR    := $(WEBPAGES_DES_DIR)
endif

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	find . \( -name '*.jemdoc' -o -name '*.jemseg' -o -name '*.bib' \) \
	       -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)`basename {}`' \;

	find . -name '*.jemdoc' -exec \
		sed -i '' 's/\/\(_[^\.]\{1,\}\)\.\(jeminc\)/\/$(COURSE_NAME)\1\.\2/g' {} +

	find . -name 'MENU' -exec \
		sed -i '' 's/\[\(_[^\.]\{1,\}\)\.\(html\)/\[$(COURSE_NAME)\1\.\2/g' {} +

	rm -rf .git
	git init
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : add_syllabus
add_syllabus: 
	git clone -b $(GIT_BRANCH_SYLLABUS) $(GIT_REPO) $(SYLLABUS_DIR)
	$(MAKE) -C $(SYLLABUS_DIR) init

.PHONY : add_a_week
add_a_week:
	git clone -b $(GIT_BRANCH_COURSE_WEEKLY) $(GIT_REPO) $(NEXT_WEEKS_DIR)
	$(MAKE) -C $(NEXT_WEEKS_DIR) init

.PHONY : pack_materials
pack_materials:
ifneq ($(MATERIALS),)
	for dir in $(MATERIALS); do ($(MAKE) -C $$dir pack_materials); done
endif

.PHONY : publish_materials
publish_materials:
ifneq ($(MATERIALS),)
	for dir in $(MATERIALS); do ($(MAKE) -C $$dir publish_materials PUBLISH_MATERIALS_DIR=$(PUBLISH_MATERIALS_DIR)); done
endif

.PHONY : build_webpages
build_webpages:
ifdef COURSE_WEBPAGES_DIR
	find $(RESEARCH_PROJ_BIB_DIR) -name '*.bib' -exec rsync -urz {} $(WEBPAGES_SRC_DIR) \;
	rsync -urz $(WEBPAGES_SITECONF) $(WEBPAGES_SRC_DIR)
	rsync -urz $(WEBPAGES_MAKEFILE) $(COURSE_WEBPAGES_DIR)
	$(MAKE) -C $(COURSE_WEBPAGES_DIR)

ifneq ($(PUBLISH_WEBPAGES_DIR),$(WEBPAGES_DES_DIR))
	if [ ! -d $(PUBLISH_WEBPAGES_DIR) ]; then mkdir -p $(PUBLISH_WEBPAGES_DIR); fi
	rsync -urz $(WEBPAGES_DES_DIR)/ $(PUBLISH_WEBPAGES_DIR)
	rsync -urz $(WEBPAGES_PIC_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urz $(WEBPAGES_CSS_DIR) $(PUBLISH_WEBPAGES_DIR)
	rsync -urz $(WEBPAGES_FONTS_DIR) $(PUBLISH_WEBPAGES_DIR)
endif
endif

print-%:
	@echo '$*=$($*)'