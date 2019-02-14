OS                          = $(shell uname)
TIMESTAMP                   := $(shell date +"%Y%m%d_%H%M%S")
COURSE_DIR                  = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
COURSE_NAME                 = $(subst course_,,$(notdir $(COURSE_DIR)))
COURSE_MATERIALS            = $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name 'materials_*')
MKFILES                     = $(shell find $(COURSE_DIR) -maxdepth 1 -mindepth 1 -type f -name "*.mk" | sort)
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
	@find $(COURSE_DIR) -type f -name 'COURSE_NAME*.*' \
		-exec bash -c 'mv "$$1" "$${1/COURSE_NAME/$(COURSE_NAME)}"' -- {} \;

# Rule to create necessary links {{{2
.PHONY: link_files
link_files: ;

# Rule to prepare for git repo initialization {{{2
define GITIGNORE
# Default gitignore for course
public/*
endef
export GITIGNORE

.PHONY: prepare_git
prepare_git:
	@rm -rf $(COURSE_DIR)/.git
	@echo "$$GITIGNORE" > $(COURSE_DIR)/.gitignore

# Material Rules {{{1
# Variables {{{2
COURSE_MATERIAL_REPO        = git@github.com:gustybear/templates.git
COURSE_MATERIAL_BRANCH      = course_material

name_of_dir                 = materials_$(1)_$(shell printf "%02d" \
			      $$(( $(words $(shell find $(COURSE_DIR) -maxdepth 1 -type d -name '*$(1)*')) + 1 )))

# Rule to add materials {{{2
MATERIAL_NAMES              = curriculum week project laboratory exam

define material_rules
.PHONY : add_$1
add_$1:
	$$(eval $$@_DIR := $$(call name_of_dir,$1))
	@git clone -b $$(COURSE_MATERIAL_BRANCH) $$(COURSE_MATERIAL_REPO) $$($$@_DIR)
	@echo "Entering $$($$@_DIR)."
	@$(MAKE) -C $$($$@_DIR) init COURSE_NAME=$$(COURSE_NAME)
endef

$(foreach NAME,$(MATERIAL_NAMES),$(eval $(call material_rules,$(NAME))))

# Documents Rules {{{1
# Rules to build Documents {{{2
.PHONY : build_documents
build_documents:
ifneq ($(COURSE_MATERIALS),)
	@for dir in $(COURSE_MATERIALS); do (echo "Entering $$dir."; $(MAKE) -C $$dir build_documents COURSE_NAME=$(COURSE_NAME)); done
endif

# Rule to clean documents {{{2
.PHONY : clean_documents
clean_documents:
ifneq ($(COURSE_MATERIALS),)
	@for dir in $(COURSE_MATERIALS); do (echo "Entering $$dir."; $(MAKE) -C $$dir clean_documents); done
endif

# Publish Rules {{{1
# Variables {{{2
# s3 parameters
S3_PUBLISH_SRC              = $(COURSE_DIR)/public/s3
S3_PUBLISH_DES              = s3://gustybear-websites

# github parameters
# github orgnization is set in the input.mk
# Rule to publish via S3 {{{2
.PHONY : publish_s3
publish_s3:
	@test -d $(S3_PUBLISH_SRC) || mkdir -p $(S3_PUBLISH_SRC)
	@rm -rf $(S3_PUBLISH_SRC)/*
	@aws s3 rm $(S3_PUBLISH_DES)/$(notdir $(COURSE_DIR)) --recursive
ifneq ($(COURSE_MATERIALS),)
	@for dir in $(COURSE_MATERIALS); do (echo "Entering $$dir."; $(MAKE) -C $$dir publish_s3 S3_PUBLISH_SRC=$(S3_PUBLISH_SRC) COURSE_NAME=$(COURSE_NAME)); done
endif
	@aws s3 cp $(S3_PUBLISH_SRC) $(S3_PUBLISH_DES)/$(notdir $(COURSE_DIR)) --recursive # --dryrun

# Rule to publish via github {{{2
.PHONY : publish_github
publish_github:
ifdef GITHUB_ORG
ifneq ($(COURSE_MATERIALS),)
	@for dir in $(COURSE_MATERIALS); do (echo "Entering $$dir."; $(MAKE) -C $$dir publish_github GITHUB_ORG=$(GITHUB_ORG) COURSE_NAME=$(COURSE_NAME)); done
endif
endif

# Rule to publish all {{{2
.PHONY : publish
publish: publish_s3 publish_github


# Git Rules {{{1
# Variables {{{2
# Run 'git config --global github.user <username>' to set username.
# Run 'git config --global github.token <token>' to set security token.
GITHUB_USER                      = $(shell git config --global --includes github.user)
GITHUB_TOKEN                     = :$(shell git config --global --includes github.token)
GITHUB_API_URL                   = https://api.github.com/user/repos
GITHUB_REPO_URL                  = git@github.com:$(GITHUB_USER)/$(notdir $(COURSE_DIR)).git
CURRENT_BRANCH                   = $(shell test -d $(COURSE_DIR)/.git && git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT                   = $(shell test -d $(COURSE_DIR)/.git && git log -n1 | head -n1 | cut -c8-)

# Rule to create the remote github repo {{{2
.PHONY : github_mk
github_mk:
ifdef GITHUB_USER
	@curl -i -u "$(GITHUB_USER)$(GITHUB_TOKEN)" \
		$(GITHUB_API_URL) \
		-d '{ "name" : "$(notdir $(COURSE_DIR))", "private" : true }'
	@find $(COURSE_DIR) -type f -name "inputs.mk" \
		-exec sed -i.bak 's|\(^GITHUB_REPO[ ]\{1,\}=$$\)|\1 $(GITHUB_REPO_URL)|g' {} \;
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
