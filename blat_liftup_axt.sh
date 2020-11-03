#!/bin/bash


#SOFTWARE
BLAT="path/to/blat"
LIFTUP="path/to/liftUp"
AXTCHAIN="path/to/axtChain"


#DATA
OLDBIT=$1
NEWBIT=$2
NEWFA=$3
OOC=$4
LFT=$5
D_ALL_CHAIN=$6


#DIRECTORY
D_WORKING="path/to/local/workdir/on/cluster" ; mkdir -p ${D_WORKING}
BASENAME=$(basename "$NEWFA")
CHUNKNAME=${BASENAME::-3}
D_CHUNK=${D_WORKING}/${CHUNKNAME} ; mkdir -p ${D_CHUNK}
D_CHAIN=${D_WORKING}/CHAINS_LOCAL ; mkdir -p ${D_CHAIN}
cd ${D_CHUNK}


#LOCAL DATA
_OLDBIT=${D_WORKING}/OLD.2bit
_NEWBIT=${D_WORKING}/NEW.2bit
_OOC=${D_WORKING}/OLD.11.ooc
_LFT=${D_WORKING}/NEW.lft


#COPY FILES TO LOCAL MACHINE IF NOT ALREADY DONE
COPYCHECK=${D_WORKING}/CPCHECK
if ! [ -f "$COPYCHECK" ]; then
  cp ${OLDBIT} ${_OLDBIT}
  cp ${NEWBIT} ${_NEWBIT}
  cp ${OOC} ${_OOC}
  cp ${LFT} ${_LFT}
  touch ${COPYCHECK}
  sleep 5s
fi


#COPY FILES TO CHUNK FOLDERS
cp ${_OLDBIT} ${D_CHUNK}/OLD.2bit
cp ${_NEWBIT} ${D_CHUNK}/NEW.2bit
cp ${_OOC} ${D_CHUNK}/OLD.11.ooc
cp ${_LFT} ${D_CHUNK}/NEW.lft
cp ${NEWFA} ${D_CHUNK}/${CHUNKNAME}.fa
sleep 5s


#ALIGN NEW FASTA RECORDS TO OLD GENOME
blat=1
if [ "$blat" = 1 ] ; then
  echo "blat:"
  echo ${BLAT} -ooc=${D_CHUNK}/OLD.11.ooc ${D_CHUNK}/OLD.2bit ${D_CHUNK}/${CHUNKNAME}.fa ${D_CHUNK}/OLD.${CHUNKNAME}.psl -q=dna -t=dna
  ${BLAT} -ooc=${D_CHUNK}/OLD.11.ooc ${D_CHUNK}/OLD.2bit ${D_CHUNK}/${CHUNKNAME}.fa ${D_CHUNK}/OLD.${CHUNKNAME}.psl -q=dna -t=dna
  echo "blat done"
fi


#CHANGE COORDINATE SYSTEM
liftup=1
if [ "$liftup" = 1 ] ; then
	echo "liftUp:"
	echo ${LIFTUP} -pslQ ${D_CHUNK}/${CHUNKNAME}.psl ${D_CHUNK}/NEW.lft warn ${D_CHUNK}/OLD.${CHUNKNAME}.psl
	${LIFTUP} -pslQ ${D_CHUNK}/${CHUNKNAME}.psl ${D_CHUNK}/NEW.lft warn ${D_CHUNK}/OLD.${CHUNKNAME}.psl
	echo "liftup done"
fi


#CHAIN TOGETHER ALIGNMENTS
axtchain=1
if [ "$axtchain" = 1 ] ; then
	echo "axtchain:"
	echo ${AXTCHAIN} -linearGap=loose -psl ${D_CHUNK}/${CHUNKNAME}.psl ${D_CHUNK}/OLD.2bit ${D_CHUNK}/NEW.2bit ${D_CHAIN}/${CHUNKNAME}.chain
	${AXTCHAIN} -linearGap=loose -psl ${D_CHUNK}/${CHUNKNAME}.psl ${D_CHUNK}/OLD.2bit ${D_CHUNK}/NEW.2bit ${D_CHAIN}/${CHUNKNAME}.chain
	echo "axtchain done"
fi


#COLLECT CHAIN FILES
cp ${D_CHAIN}/${CHUNKNAME}.chain ${D_ALL_CHAIN}


#CLEAN UP THE MESS
cd ${D_WORKING}
rm -r ${D_CHUNK}