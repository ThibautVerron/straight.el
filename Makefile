EMACS ?= emacs
USER_EMACS_DIRECTORY ?= ~/.emacs.d
MAKE_SYMBOLIC_LINK ?= ln -s

# The order is important for compilation.
for_compile := straight-compat.el straight.el \
	bootstrap.el install.el straight-x.el
for_checkdoc := straight-compat.el straight.el
for_longlines := $(wildcard *.el *.md *.yml) Makefile

.PHONY: all
all: compile checkdoc longlines

.PHONY: compile
compile:
	@for file in $(for_compile); do \
	    echo "[compile] $$file" ;\
	    $(EMACS) -Q --batch -L . -f batch-byte-compile $$file 2>&1 \
	        | grep -v "^Wrote" \
	        | grep . && exit 1 || true ;\
	done

.PHONY: checkdoc
checkdoc:
	@for file in $(for_checkdoc); do \
	    echo "[checkdoc] $$file" ;\
	    $(EMACS) -Q --batch \
	        --eval "(or (fboundp 'checkdoc-file) (kill-emacs))" \
	        --eval "(setq sentence-end-double-space nil)" \
	        --eval "(checkdoc-file \"$$file\")" 2>&1 \
	        | grep . && exit 1 || true ;\
	done

.PHONY: longlines
longlines:
	@echo "[longlines] $(for_longlines)"
	@for file in $(for_longlines); do \
	    cat "$$file" \
	        | sed '/<!-- toc -->/,/<!-- tocstop -->/d' \
	        | sed '/longlines-start/,/longlines-stop/d' \
	        | grep -E '.{80}' \
	        | grep -E -v '\[.+\]: (#|http)' \
	        | sed "s/^/$$file:long line: /" \
	        | grep . && exit 1 || true ;\
	done

.PHONY: toc
toc: README.md
	@echo "[toc] $^"
	@markdown-toc -i $^

.PHONY: clean
clean:
	@echo "[clean]" *.elc
	@rm -f *.elc

# Make sure to test with a package that supports Emacs 24.4 here.
.PHONY: travis
travis: compile checkdoc longlines
	mkdir -p "$(USER_EMACS_DIRECTORY)/straight/repos/"
	$(MAKE_SYMBOLIC_LINK) ${CURDIR} \
	      "$(USER_EMACS_DIRECTORY)/straight/repos/straight.el"
	$(EMACS) --batch \
              -l "$(USER_EMACS_DIRECTORY)/straight/repos/straight.el/bootstrap.el" \
	      --eval "(straight-use-package 'use-package)" \
	      --eval "(use-package clojure-mode :straight t)"
