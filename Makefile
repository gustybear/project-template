OS                                  := $(shell uname)
COURSE_MATERIAL_DIR                 := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_MATERIAL_NAME                := $(notdir $(COURSE_MATERIAL_DIR))
MKFILES                             := $(shell find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
-include $(MKFILES)

COURSE_MATERIAL_DOCS_DIR            := $(COURSE_MATERIAL_DIR)/docs

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
gen_package_name         = $(addprefix $(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_,$(addprefix $(notdir $(1)),.tar.gz))

define gen_package
	mkdir -p $(call gen_tmp_dir_name, $(1))
	find $(1) $(COURSE_BIB_DIR)  \
		-not \( -path '*/\.*' -prune \) \
		-not \( -name "*.zip" -o -name "*.gz"  \) \
		-type f \
		-exec rsync -urzL {} $(call gen_tmp_dir_name, $(1)) \;

	cd $(call gen_tmp_dir_name, $(1)); \
		tar -zcvf $(addprefix $(1)/,$(call gen_package_name,$(1))) *
	rm -rf $(call gen_tmp_dir_name, $(1))
endef

.PHONY : clear
clear: ;

.PHONY : init init_files prepare_git
init: init_files prepare_git

init_files:
ifdef COURSE_NAME
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.*sh" \) \
		-exec sed -i.bak 's/COURSE_NAME/$(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.*sh" \) \
		-exec sed -i.bak 's/COURSE_MATERIAL_NAME/$(COURSE_MATERIAL_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's/\(^COURSE_NAME[ ]\{1,\}:=\).*$$/\1 $(COURSE_NAME)/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@find $(COURSE_MATERIAL_DIR) -type f \
		\( -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.ipynb" -o \
		   -name "COURSE_NAME_COURSE_MATERIAL_NAME_*.*sh" \) \
		   -exec bash -c 'mv "$$1" "$${1/COURSE_NAME_COURSE_MATERIAL_NAME_/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_}"' -- {} \;
endif


link_files:
ifdef ZSH_CUSTOM
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name '[^_]*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
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


# Git Rules {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_DIR                       := $(COURSE_MATERIAL_DIR)/github
GITHUB_USER                       := $(shell git config --global --includes github.user)
GITHUB_ORG                       := $(shell git config --global --includes github.org)
GITHUB_TOKEN                     := :$(shell git config --global --includes github.token)
GITHUB_API_URL                   := https://api.github.com/orgs/$(GITHUB_ORG)/repos
GITHUB_REPO_URL                  := git@github.com:$(GITHUB_ORG)/$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo.git

CURRENT_BRANCH                   := $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell test -d $(COURSE_MATERIAL_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

# Rule to create the remote github repo {{{2
.PHONY : github_mk
github_mk:
ifdef GITHUB_ORG
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(COURSE_NAME)_$(COURSE_MATERIAL_NAME)_repo", "private" : false }'
	@find $(COURSE_MATERIAL_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^COURSE_MATERIAL_REPO[ ]\{1,\}:=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(COURSE_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@if [ ! -d $(GITHUB_DIR) ]; then mkdir -p $(GITHUB_DIR); fi
	@echo 'github/*' > $(COURSE_MATERIAL_DIR)/.gitignore
	@cd $(GITHUB_DIR) && git init
	@cd $(GITHUB_DIR) && git remote add origin $(GITHUB_REPO_URL)
endif
endif

.PHONY : course_offline
course_offline:
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		-exec sed -i.bak 's/^\(COURSE_MATERIAL_DOCS_READY[ ]\{1,\}:=.*\)$$/#\1/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		-exec sed -i.bak 's/^\(COURSE_MATERIAL_DOCPACS_READY[ ]\{1,\}:=.*\)$$/#\1/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name 'inputs.mk.bak' -exec rm -f {} \;

.PHONY : course_online
course_online:
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		-exec sed -i.bak 's/^#\(COURSE_MATERIAL_DOCS_READY[ ]\{1,\}:=.*\)$$/\1/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -maxdepth 1 -mindepth 1 -type f -name "inputs.mk" \
		-exec sed -i.bak 's/^#\(COURSE_MATERIAL_DOCPACS_READY[ ]\{1,\}:=.*\)$$/\1/g' {} \;
	@find $(COURSE_MATERIAL_DIR) -type f -name '*.bak' -exec rm -f {} \;

print-%:
	@echo '$*:=$($*)'
