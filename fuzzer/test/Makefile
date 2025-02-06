#
# Atmels Tools Test
#

CUPLOPTS = -m0

SOURCES	= $(wildcard *.pld)
TARGETS	= $(patsubst %.pld,%.jed, $(SOURCES))

.PHONY: all clean clean-cupl clean-fitter

all: $(TARGETS)

clean: clean-cupl clean-fitter

clean-cupl:
	$(RM) $(patsubst %.pld,%.doc, $(SOURCES))
	$(RM) $(patsubst %.pld,%.pla, $(SOURCES))
	$(RM) $(patsubst %.pld,%.tt2, $(SOURCES))

clean-fitter:
	$(RM) $(patsubst %.pld,%.fit, $(SOURCES))
	$(RM) $(patsubst %.pld,%.io,  $(SOURCES))
	$(RM) $(patsubst %.pld,%.jed, $(SOURCES))
	$(RM) $(patsubst %.pld,%.pin, $(SOURCES))
	$(RM) $(patsubst %.pld,%.tt3, $(SOURCES))

%.tt2: %.pld
	cupl -jx $(CUPLOPTS) $< && test -e $@

%.jed: %.tt2
	fitter $< -cupl $(FITOPTS)
