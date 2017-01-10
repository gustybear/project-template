COURSE_NAME = $(subst course_,,$(notdir $(shell pwd)))
MATERIALS := $(shell find . -type d -name 'materials_*')
INIT_FILE = .init

.PHONY : none
none: ;

.PHONY : init
init:
ifeq ($(shell cat $(INIT_FILE)),no)
	find . -name '*.ref' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_`basename {}`' \;
	find . -name '*.jemdoc' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_`basename {}`' \;
	find . -name '*.jemseg' -exec bash -c 'mv {} `dirname {}`/$(COURSE_NAME)_`basename {}`' \;

	find . -name '*.jemdoc' -exec \
		sed -i '' 's/\([^/]\+\.jeminc\)/$(COURSE_NAME)_\1/g' {} +

	rm -rf .git
	git init
	$(shell echo yes > $(INIT_FILE))
endif

.PHONY : add_syllabus
add_syllabus: ;

.PHONY : add_a_week
add_a_week: ;

.PHONY : publish
publish:
	$(MAKE) -C $(MATERIALS) publish

print-%:
	@echo '$*=$($*)'