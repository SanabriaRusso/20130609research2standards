# LaTeX Makefile for dvi, ps, and pdf file creation.
# By Jeffrey Humpherys
# Written April 05, 2004
# Revised January 13, 2005
# Thanks Bjorn and Boris
#
# Adapted by Jaume Barcelo
#
# Usage:
# make	  # make dvi, ps, and pdf
# make dvi      # make dvi
# make ps       # make ps (and dvi)
# make pdf      # make pdf
#

MAIN		= paper
SOURCES		= $(wildcard ./*.tex)
EPSFIGURES	= $(wildcard ./figures/*.eps)
PDFFIGURES	= $(patsubst %.fig,%.pdf,$(wildcard ./figures/*.fig))

all: bbl dvi pdf

bbl: ${MAIN}.bbl
dvi: ${MAIN}.dvi
pdf: ${MAIN}.pdf
diff: ${MAIN}_diff.pdf

publish: ${MAIN}.pdf ${MAIN}_diff.pdf
	s3cmd put --acl-public paper.pdf s3://www.jaumebarcelo.info/papers/
	s3cmd put --acl-public paper_diff.pdf s3://www.jaumebarcelo.info/papers/

%.bbl: my_bib.bib ${MAIN}.tex
	latex $*
	@while ( grep "Rerun to get cross-references"	\
			$*.log > /dev/null ); do		\
				echo '** Re-running LaTeX **';		\
		latex $*;				\
	done
	bibtex $*
	latex $*
	@while ( grep "Rerun to get cross-references"	\
			$*.log > /dev/null ); do		\
				echo '** Re-running LaTeX **';		\
		latex $*;				\
	done
	

${MAIN}.dvi : ${SOURCES} ${EPSFIGURES}
	latex ${MAIN}
	@while ( grep "Rerun to get cross-references"	\
			${MAIN}.log > /dev/null ); do		\
				echo '** Re-running LaTeX **';		\
		latex ${MAIN};				\
	done

${MAIN}.pdf : ${MAIN}.dvi ${EPSFIGURES}
	dvips -o ${MAIN}.ps -Ppdf -G0 -t a4 ${MAIN}.dvi
	ps2pdf -sPAPERSIZE=a4 -dPDFSETTINGS=/prepress -dEmbedAllFonts=true ${MAIN}.ps
	evince ${MAIN}.pdf &

${MAIN}_diff.tex: ${MAIN}.tex
	latexdiff ${MAIN}.old ${MAIN}.tex > ${MAIN}_diff.tex
	
${MAIN}_diff.dvi : ${MAIN}_diff.tex ${MAIN}_diff.bbl ${EPSFIGURES}
	latex ${MAIN}_diff
	@while ( grep "Rerun to get cross-references"	\
			${MAIN}_diff.log > /dev/null ); do		\
				echo '** Re-running LaTeX **';		\
		latex ${MAIN}_diff;				\
	done

${MAIN}_diff.pdf : ${MAIN}_diff.dvi ${EPSFIGURES}
	dvips -o ${MAIN}_diff.ps -Ppdf -G0 -t a4 ${MAIN}_diff.dvi
	ps2pdf -sPAPERSIZE=a4 -dPDFSETTINGS=/prepress -dEmbedAllFonts=true ${MAIN}_diff.ps
	evince ${MAIN}_diff.pdf &

clean:
	rm -f ./figures/*.tex
	rm -f ./figures/*.bak
	rm -f ./*.aux
	rm -f ./*.tex~
	rm paper.bbl paper.blg paper.dvi paper.log paper.ps 
#
# (re)Make .eps is .fig if newer
#
%.eps : %.fig
	#Creates .eps file
	fig2dev -L pstex $*.fig > $*.eps


