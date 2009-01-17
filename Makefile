# Packaging documentation

all: HowToMakeDebianPackages.html

RST2HTML=rst2html.py
RST2HTML_OPTS=-d --strict --footnote-references=superscript
RST2HTML_CSS=lsr

ifneq ($(strip $(RST2HTML_CSS)),)
  RST2HTML_OPTS += --stylesheet-path="$(RST2HTML_CSS).css"
endif

%.html: %.rst
	$(RST2HTML) $(RST2HTML_OPTS) $< $@

clean:
	$(RM) HowToMakeDebianPackages.html
