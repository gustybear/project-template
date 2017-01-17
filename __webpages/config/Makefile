JABREF             := java -Dapple.awt.UIElement=true -jar /Applications/JabRef.app/Contents/java/app/JabRef-3.8.1.jar
JEMDOC             := /usr/local/bin/jemdoc.mathjax

WEBPAGES_DIR	   := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
WEBPAGES_SRC_DIR   := $(WEBPAGES_DIR)/src
WEBPAGES_DES_DIR   := $(WEBPAGES_DIR)/des
JEMDOC_FILES       := $(patsubst $(WEBPAGES_SRC_DIR)/%,%, $(shell find $(WEBPAGES_SRC_DIR) -name '*.jemdoc'))
HTML_FILES         := $(addprefix  $(WEBPAGES_DES_DIR)/, $(subst jemdoc,html, $(SRC)))

BIB_FILES          := $(shell find $(WEBPAGES_SRC_DIR) -name '*.bib')
BIB_FILE_NAMES     := $(notdir $(BIB_FILES))

JEMSEG_FILES       := $(shell find $(WEBPAGES_SRC_DIR) -name '*.jemseg')
JEMSEG_RULE_NAMES  := $(shell sed -e 's/                                                                                                                                                    := .*$$//g' $(JEMSEG_FILES))

include $(JEMSEG_FILES)

PUBLIST_FILE_NAMES := $(addsuffix .publist, $(foreach JEMSEG_RULE_NAME,$(JEMSEG_RULE_NAMES),$(foreach BIB_FILE_NAME,$(BIB_FILE_NAMES),$(subst bib,$(JEMSEG_RULE_NAME), $(BIB_FILE_NAME)))))
PUBLIST_FILES      := $(addprefix  $(WEBPAGES_SRC_DIR)/, $(PUBLIST_FILE_NAMES))

JEMINC_FILE_NAMES  := $(subst bib,jeminc, $(BIB_FILE_NAMES))
JEMINC_FILES       := $(addprefix  $(WEBPAGES_SRC_DIR)/, $(JEMINC_FILE_NAMES))

define gen_publist
$$(WEBPAGES_SRC_DIR)/%.$1.publist: $$(WEBPAGES_SRC_DIR)/%.bib
		$$(JABREF) -n -m $($1),$$@,publist $$<
		@echo '</ol>' >> $$@
endef

.PHONY : all $(PUBLIST_FILES) $(JEMINC_FILES) $(HTML_FILES)
all : $(PUBLIST_FILES) $(JEMINC_FILES) $(HTML_FILES)

$(PUBLIST_FILES):
	for JEMSEG_RULE_NAME in $(JEMSEG_RULE_NAMES); do $(call gen_publist,$(JEMSEG_RULE_NAME)); done

$(JEMINC_FILES): $(WEBPAGES_SRC_DIR)/%.jeminc: $(WEBPAGES_SRC_DIR)/%.bib
	$(JABREF) -n -m \
	,$@,bibover $<

$(HTML_FILES): $(WEBPAGES_DES_DIR)/%.html: $(WEBPAGES_SRC_DIR)/%.jemdoc \
	$(WEBPAGES_SRC_DIR)/site.conf \
	$(WEBPAGES_SRC_DIR)/MENU \
	$(PUBLIST_FILES) \
	$(JEMINC_FILES)
	mkdir -p $(@D)
	$(JEMDOC) -o $@ -c $(<D)/site.conf $<

.PHONY : clean
clean :
	rm -rf $(WEBPAGES_DES_DIR)/*
	rm -f $(PUBLIST_FILES)
	rm -f $(JEMINC_FILES)

print-%:
	@echo '$*=$($*)'