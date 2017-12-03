OS                          := $(shell uname)
TIMESTAMP                   := $(shell date +"%Y%m%d_%H%M%S")
COURSE_DIR                  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_NAME                 := $(subst course_,,$(notdir $(COURSE_DIR)))
COURSE_MATERIALS            := $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name 'materials_*')
MKFILES                     := $(shell find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
-include $(MKFILES)


# Initialization Rules {{{1
# Rule to initialize the course {{{2
.PHONY: init
init: init_files link_files prepare_git

# Rule to initialize files {{{2
.PHONY: init_files
init_files:
ifneq ($(COURSE_MATERIALS),)
	@for dir in $(COURSE_MATERIALS); \
		do (echo "Entering $$dir."; $(MAKE) -C $$dir init_files COURSE_NAME=$(COURSE_NAME)); done
endif
	@find $(COURSE_DIR) -type f \
		\( -name "COURSE_NAME_*.bib" -o \
		   -name "COURSE_NAME_*.jem*" -o -name "MENU" -o \
		   -name "COURSE_NAME_*.*sh" \) \
		-exec sed -i.bak 's/COURSE_NAME/$(COURSE_NAME)/g' {} \;
	@find $(COURSE_DIR) -type f -name '*.bak' -exec rm -f {} \;

	@find $(COURSE_DIR) -type f -name 'COURSE_NAME_*.*' \
		-exec bash -c 'mv "$$1" "$${1/COURSE_NAME_/$(COURSE_NAME)_}"' -- {} \;

# Rule to create necessary links {{{2
.PHONY: link_files
link_files:
ifdef ZSH_CUSTOM
# ifneq ($(COURSE_MATERIALS),)
# 	@for dir in $(COURSE_MATERIALS); \
# 		do (echo "Entering $$dir."; $(MAKE) -C $$dir link_files); done
# endif
	@find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name '$(COURSE_NAME)_*.zsh' \
		-exec ln -sf {} $(ZSH_CUSTOM) \;
endif

# Rule to prepare for git {{{2
# Rule to prepare for git repo initialization {{{2
define GITIGNORE
# not track the html files in the webpages
__webpages/*/*.html
# Only track the download script in the data directory
data/*
Makefile
inputs.mk
$(COURSE_NAME)_config.zsh
!/$(COURSE_NAME)_get_data.sh

endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(COURSE_DIR)/.git
	@echo "$$GITIGNORE" > $(COURSE_DIR)/.gitignore

# Material Rules {{{1
# Variables {{{2
COURSE_BIB_DIR             := $(COURSE_DIR)/bib
COURSE_FIGS_DIR            := $(COURSE_DIR)/figures
COURSE_DOCS_DIR            := $(COURSE_DIR)/docs

COURSE_MATERIAL_REPO        := git@github.com:gustybear/templates.git
COURSE_MATERIAL_BRANCH      := course_material

COURSE_CURRICULUM_DIR       := materials_curriculum
COURSE_PROJECT_DIR          := materials_project

NUM_OF_WEEKS                := $(words $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name '*week*'))
NUM_OF_NEXT_WEEKS           := $(shell echo $$(( $(NUM_OF_WEEKS) + 1 )))
NEXT_WEEKS_DIR              := materials_week_$(shell printf "%02d" $(NUM_OF_NEXT_WEEKS))

# The default folder to publish the materials
PUBLISH_MATERIALS_DIR       := $(COURSE_WEBPAGES_DIR)/des
PUBLISTH_DOCS_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/docs
PUBLISTH_CODE_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/codes
PUBLISTH_DATA_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/data
PUBLISTH_PICS_SUBDIR        := $(PUBLISH_MATERIALS_DIR)/pics

# Rule to add curriculum {{{2
.PHONY : add_curriculum
add_curriculum:
	@git clone -b $(COURSE_MATERIAL_BRANCH) $(COURSE_MATERIAL_REPO) $(COURSE_CURRICULUM_DIR)
	@echo "Entering $(COURSE_CURRICULUM_DIR)."
	@$(MAKE) -C $(COURSE_CURRICULUM_DIR) init COURSE_NAME=$(COURSE_NAME)

# Rule to add a new week {{{2
.PHONY : add_a_week
add_a_week:
	@git clone -b $(COURSE_MATERIAL_BRANCH) $(COURSE_MATERIAL_REPO) $(NEXT_WEEKS_DIR)
	@echo "Entering $(NEXT_WEEKS_DIR)."
	@$(MAKE) -C $(NEXT_WEEKS_DIR) init COURSE_NAME=$(COURSE_NAME)

# Rule to add a project {{{2
.PHONY : add_a_project
add_project:
	@git clone -b $(COURSE_MATERIAL_BRANCH) $(COURSE_MATERIAL_REPO) $(COURSE_PROJECT_DIR)
	@echo "Entering $(COURSE_PROJECT_DIR)."
	@$(MAKE) -C $(COURSE_PROJECT_DIR) init COURSE_NAME=$(COURSE_NAME)

# Rule to publish materials {{{2
.PHONY : publish_materials
publish_materials:
ifneq ($(COURSE_MATERIALS),)
	@for dir in $(COURSE_MATERIALS); do (echo "Entering $$dir."; $(MAKE) -C $$dir publish_materials PUBLISH_MATERIALS_DIR=$(PUBLISH_MATERIALS_DIR)); done
endif

# Git Rules {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                      := $(shell git config --global --includes github.user)
GITHUB_TOKEN                     := :$(shell git config --global --includes github.token)
GITHUB_API_URL                   := https://api.github.com/user/repos
GITHUB_REPO_URL                  := git@github.com:$(GITHUB_USER)/$(notdir $(COURSE_DIR)).git
CURRENT_BRANCH                   := $(shell test -d $(COURSE_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   := $(shell test -d $(COURSE_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

# Rule to create the remote github repo {{{2
.PHONY : github_mk
github_mk:
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(notdir $(COURSE_DIR))", "private" : true }'
	@find $(COURSE_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^GITHUB_REPO[ ]\{1,\}:=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
	@find $(COURSE_DIR) -type f -name '*.bak' -exec rm -f {} \;
	@git init
	@git add -A
	@git commit -m "First commit"
	@git remote add origin $(GITHUB_REPO_URL)
	@git push -u origin master
endif


# Debug Rules {{{1
# Rule to print makefile variables {{{2
print-%:
	@echo '$*=$($*)'
