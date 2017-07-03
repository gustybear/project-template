OS                                  := $(shell uname)
COURSE_MATERIAL_DIR                 := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_MATERIAL_NAME                := $(notdir $(COURSE_MATERIAL_DIR))
MKFILES                             := $(shell find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk")
-include $(MKFILES)

ifdef COURSE_NAME
COURSE_NAME_AND_MATERIAL_NAME       := $(COURSE_NAME)_$(COURSE_MATERIAL_NAME)
endif

COURSE_MATERIAL_DOCS_DIR            := $(COURSE_MATERIAL_DIR)/docs

ifeq ($(findstring curriculum,$(COURSE_MATERIAL_NAME)),curriculum)
TRIM_SUBDIRS                        := assg assg_sol notes quiz quiz_sol slides topics
else ifeq ($(findstring week,$(COURSE_MATERIAL_NAME)),week)
TRIM_SUBDIRS                        := syllabus topics
else ifeq ($(findstring project,$(COURSE_MATERIAL_NAME)),project)
TRIM_SUBDIRS                        := assg assg_sol notes quiz quiz_sol slides syllabus
else
TRIM_SUBDIRS                        :=
endif

ifdef TRIM_SUBDIRS
COURSE_MATERIAL_TRIM_SUBDIRS        := $(addprefix $(COURSE_MATERIAL_DOCS_DIR)/,$(TRIM_SUBDIRS))
endif

ifdef COURSE_MATERIAL_DOCS_READY
COURSE_MATERIAL_DOCS_SUBDIRS        := $(addprefix $(COURSE_MATERIAL_DOCS_DIR)/,$(COURSE_MATERIAL_DOCS_READY))
endif

ifdef COURSE_MATERIAL_DOCPACS_READY
COURSE_MATERIAL_DOCPACS_SUBDIRS     := $(addprefix $(COURSE_MATERIAL_DOCS_DIR)/,$(COURSE_MATERIAL_DOCPACS_READY))
endif

ifdef PUBLISH_MATERIALS_DIR
PUBLISTH_DOCS_SUBDIR                := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR                := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR                := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR                := $(PUBLISH_MATERIALS_DIR)/pics
endif

TMP_DIR_PREFIX                      := $(COURSE_MATERIAL_DIR)/tmp

gen_tmp_dir_name         = $(addprefix $(TMP_DIR_PREFIX)_, $(notdir $(1)))
gen_package_name         = $(addprefix $(COURSE_NAME_AND_MATERIAL_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	mkdir -p $(call gen_tmp_dir_name, $(1))
	find $(1) $(COURSE_BIB_DIR)  \
		-not \( -path '*/\.*' -prune \) \
		-not \( -name "*.zip" -o -name "*.gz"  \) \
		-type f \
		-exec rsync -urzL {} $(call gen_tmp_dir_name, $(1)) \;

	find $(call gen_tmp_dir_name, $(1)) -type f -name '*.tex'                              \
		-exec sed -i.bak 's/{.*\/\([^/]\{1,\}\)\.\([a-zA-Z0-9]\{1,\}\)/{\.\/\1\.\2/g' {} + ;\
	find $(call gen_tmp_dir_name, $(1))  -type f -name '*.bak' -exec rm -f {} \;

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

.PHONY : clear
clear: ;

.PHONY : init init_files trim_files prepare_git link_files
init: init_files trim_files prepare_git link_files

init_files:
ifdef COURSE_NAME
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name '_*.tex' -o -name '_*.bib' -o \
		   -name '_*.jem*' -o -name '_MENU' -o \
		   -name '_*.*sh' \) \
		-exec sed -i.bak 's/COURSE_NAME/$(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's/\(^COURSE_NAME[ ]\{1,\}:=$$\)/\1 $(COURSE_NAME)/g' {} \;
endif
	@find $(COURSE_MATERIAL_DIR) -type f -name '_*.*' \
		-exec sed -i.bak 's/COURSE_MATERIAL_NAME/$(COURSE_MATERIAL_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \;

	@find $(COURSE_MATERIAL_DIR) -type f -name '_*.*' \
		   -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME_AND_MATERIAL_NAME)`basename {}`' \;

link_files:
ifdef ZSH_CUSTOM
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name '*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

trim_files:
ifdef COURSE_MATERIAL_TRIM_SUBDIRS
	@rm -rf $(COURSE_MATERIAL_TRIM_SUBDIRS)
endif

prepare_git:
	@rm -rf $(COURSE_MATERIAL_DIR)/.git

.PHONY : pack_materials
pack_materials:
	@$(foreach SUBDIR,$(COURSE_MATERIAL_DOCPACS_SUBDIRS),$(call gen_package,$(SUBDIR));)


.PHONY : publish_materials
publish_materials:
ifdef PUBLISH_MATERIALS_DIR
	@if [ ! -d $(PUBLISTH_DOCS_SUBDIR) ]; then mkdir -p $(PUBLISTH_DOCS_SUBDIR); fi
	@$(foreach SUBDIR,$(COURSE_MATERIAL_DOCS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.pdf" \
			 -exec rsync -urz {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
	@$(foreach SUBDIR,$(COURSE_MATERIAL_DOCPACS_SUBDIRS),\
		find $(SUBDIR) -maxdepth 1 -type f -name "*.tar.gz" \
			 -exec rsync -urz {} $(PUBLISTH_DOCS_SUBDIR) \; ;)
endif


ifdef GITHUB_REPO
CURRENT_BRANCH                   := $(shell git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell git log -n1 | head -n1 | cut -c8-)
endif
.PHONY : github_update
github_update:
ifdef GITHUB_REPO
#fast commit and push to git repository
	@cd $(COURSE_MATERIAL_DIR) && git pull
	@cd $(COURSE_MATERIAL_DIR) && git add . && git diff --quiet --exit-code --cached || git commit -m "Publish on $$(date)" -a
	@cd $(COURSE_MATERIAL_DIR) && git push
endif


.PHONY : course_offline
course_offline:
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		   -exec bash -c 'mv {} `dirname {}`/inputs.mk.bak' \;

.PHONY : course_online
course_online:
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk.bak" \
		   -exec bash -c 'mv {} `dirname {}`/inputs.mk' \;

print-%:
	@echo '$*:=$($*)'
