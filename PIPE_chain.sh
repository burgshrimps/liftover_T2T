#!/bin/bash


#SOFTWARE
FATOTWOBIT="path/to/faToTwoBit"
FASPLIT="path/to/faSplit"
TWOBITINFO="path/to/twoBitInfo"
CHAINMERGESORT="path/to/chainMergeSort"
CHAINNET="path/to/chainNet"
NETCHAINSUBSET="path/to/netChainSubset"


#DATA
NEW_FA="path/to/new.fasta"
OLD_FA="path/to/old.fasta"
CHUNKSIZE=100000  #RECOMMENDED: not above 100k
MAX_FILESIZE=1000000


#WORKING DIRECTORY
D_WORKING="path/to/working/dir" ; mkdir -p ${D_WORKING}
D_NEW="${D_WORKING}/NEW_BUILD" ; mkdir -p ${D_NEW}
D_OLD="${D_WORKING}/OLD_BUILD" ; mkdir -p ${D_OLD}
D_SPLIT="${D_NEW}/FASPLIT" ; mkdir -p ${D_SPLIT}
D_CLUSTERWORK="${D_WORKING}/STDOUT" ; mkdir -p ${D_CLUSTERWORK}
D_CHAIN="${D_WORKING}/CHAIN" ; mkdir -p ${D_CHAIN}
D_FINAL="${D_WORKING}/FINAL" ; mkdir -p ${D_FINAL}
cd ${D_WORKING}
echo -e "NEW (Q): $NEW_FA\nOLD (T): $OLD_FA" > ${D_WORKING}/info.txt


#CREATING TWOBIT FILES FROM FASTA FILES
fa2twobit=1
if [ "$fa2twobit" = 1 ] ; then
	echo "faToTwoBit:"
	echo ${FATOTWOBIT} ${NEW_FA} ${D_NEW}/NEW.2bit
	${FATOTWOBIT} ${NEW_FA} ${D_NEW}/NEW.2bit
	echo ${FATOTWOBIT} ${OLD_FA} ${D_OLD}/OLD.2bit
	${FATOTWOBIT} ${OLD_FA} ${D_OLD}/OLD.2bit
	echo "faToTwoBit done"
fi


#CREATE OOC FILE FOR BLAT TO DECREASE RUNTIME OF ALIGNMENT
makeOOC=1
if [ "$makeOOC" = 1 ] ; then
	echo "makeOOC:"
	echo ${BLAT} ${D_OLD}/OLD.2bit /dev/null /dev/null -tileSize=11 -makeOoc=${D_OLD}/OLD.11.ooc -repMatch=1024
	${BLAT} ${D_OLD}/OLD.2bit /dev/null /dev/null -tileSize=11 -makeOoc=${D_OLD}/OLD.11.ooc -repMatch=1024
	echo "makeOOC done"
fi


#SPLITTING NEW BUILD INTO CHUNKS AND CREATING LIFT FILES
fasplit=1
if [ "$fasplit" = 1 ] ; then
	echo "faSplit:"
	echo ${FASPLIT} size ${NEW_FA} ${CHUNKSIZE} -lift=${D_NEW}/NEW.lft ${D_SPLIT}/chunk
	${FASPLIT} size ${NEW_FA} ${CHUNKSIZE} -lift=${D_NEW}/NEW.lft ${D_SPLIT}/chunk
	echo "faSplit done"
fi


#CAT FASTA FILES IF THEY ARE BELOW CERTAIN FILESIZE TO REDUCE NUMBER OF FILES
facat=1
if [ "$facat" = 1 ] ; then
	echo "faCat:"
	CHUNKS=$(find "$D_SPLIT" -name '*.fa')
	NUM=$(echo "$CHUNKS" | wc -w)
	CHUNKS_ARR=(${CHUNKS})
	i=0
	while [ "$i" -lt "${NUM}" ]
	do
		j=0
		FILESIZE=0
		while [ "${FILESIZE}" -lt "${MAX_FILESIZE}" ]
		do
			if [ $(($i + $j)) -lt $NUM ] ; then
				FILESIZE=$[$FILESIZE + $(stat --printf="%s" ${CHUNKS_ARR[$i+$j]})]
				j=$[$j+1]
			else
				break
			fi
		done
		cat "${CHUNKS_ARR[@]:$i:$j}" > "${D_SPLIT}/cat${i}.fa"
		rm "${CHUNKS_ARR[@]:$i:$j}"
		i=$[$i+$j]
	done
	echo "faCat done"
fi


#OBTAINING SEQUENCE LENGTHS OF FASTA RECORDS
twobitinfo=1
if [ "$twobitinfo" = 1 ] ; then
	echo "twoBitInfo:"
	echo ${TWOBITINFO} ${D_NEW}/NEW.2bit ${D_NEW}/chrom.sizes
	${TWOBITINFO} ${D_NEW}/NEW.2bit ${D_NEW}/chrom.sizes
	echo ${TWOBITINFO} ${D_OLD}/OLD.2bit ${D_OLD}/chrom.sizes
	${TWOBITINFO} ${D_OLD}/OLD.2bit ${D_OLD}/chrom.sizes
	echo "twoBitInfo done"
fi


#BLAT, LIFTUP AND AXTCHAIN ON CLUSTER (REPLACE WITH THE APPROPRIATE COMMAND FOR YOUR CLUSTER)
blatliftaxt=1
if [ "$blatliftaxt" = 1 ] ; then
	echo "blat, liftUp, axtCHain -> cluster"
	CPU=1
	MEM=32
	for FA in ${D_NEW}/FASPLIT/*.fa
	do
		BASENAME=$(basename $FA)
		submit \
			--workdir=${D_CLUSTERWORK} \
			--stdout=${D_CLUSTERWORK}/${BASENAME::-3}.out \
			--stderr=${D_CLUSTERWORK}/${BASENAME::-3}.err \
			--runtime=12h \
			--threads=${CPU} \
			--memory=${MEM}G \
			--group-name=liftover_T2T \
			bash path/to/blat_liftup_axt.sh ${D_OLD}/OLD.2bit ${D_NEW}/NEW.2bit ${FA} ${D_OLD}/OLD.11.ooc ${D_NEW}/NEW.lft ${D_CHAIN}
		sleep 15s
	done
	echo "sent jobs to cluster"
fi


#CHECK IF CLUSTER JOBS WERE SUCCESSFUL
checksuccess=1
if [ "$checksuccess" = 1 ] ; then
	for FILE in ${D_CLUSTERWORK}/*.err
	do
		FILESIZE=$(stat --printf="%s" $FILE)
		if [ "$FILESIZE" -lt 5000 ] ; then
			BASENAME=$(basename $FILE)
			CHUNKNAME=${BASENAME::-4}
			echo ${CHUNKNAME} >> ${D_WORKING}/failed_jobs_size.txt
		fi
	done
	for FILE in ${D_CHAIN}/*.chain
	do
		FILESIZE=$(stat --printf="%s" $FILE)
		if [ "$FILESIZE" -lt 5000 ] ; then
			BASENAME=$(basename $FILE)
			CHUNKNAME=${BASENAME::-6}
			echo ${CHUNKNAME} >> ${D_WORKING}/failed_jobs_size.txt
		fi
	done
fi


#CHECK WHICH CHAIN FILES ARE MISSING COMPARED TO SPLITTED FA FILES
checkmissing=1
if [ "$checkmissing" = 1 ] ; then
	cd ${D_SPLIT}
	ls -l | awk '{print $9}' | cut -f1 -d "." >> ${D_WORKING}/chunk_names_fa.txt
	cd ${D_CHAIN}
	ls -l | awk '{print $9}' | cut -f1 -d "." >> ${D_WORKING}/chunk_names_chain.txt
	cd ${D_WORKING}
	comm -23 <(sort ${D_WORKING}/chunk_names_fa.txt) <(sort ${D_WORKING}/chunk_names_chain.txt) >> ${D_WORKING}/failed_jobs_missing.txt
	rm ${D_WORKING}/chunk_names_fa.txt ${D_WORKING}/chunk_names_chain.txt
	sort ${D_WORKING}/failed_jobs_size.txt ${D_WORKING}/failed_jobs_missing.txt | uniq >> ${D_WORKING}/failed_jobs.txt
fi


#RUN FAILED JOBS AGAIN
runagain=1
if [ "$runagain" = 1 ] ; then
	echo "running failed jobs again:"
	CPU=1
	MEM=32
	while read LINE; do
		FA=${D_NEW}/FASPLIT/${LINE}.fa
		rm ${D_CHAIN}/${LINE}.chain
		submit \
			--workdir=${D_CLUSTERWORK} \
			--stdout=${D_CLUSTERWORK}/${LINE}.out \
			--stderr=${D_CLUSTERWORK}/${LINE}.err \
			--runtime=5d \
			--threads=${CPU} \
			--memory=${MEM}G \
			--group-name=liftover_T2T_rerun \
			bash path/to/blat_liftup_axt.sh ${D_OLD}/OLD.2bit ${D_NEW}/NEW.2bit ${FA} ${D_OLD}/OLD.11.ooc ${D_NEW}/NEW.lft ${D_CHAIN}
		sleep 15s
	done < ${D_WORKING}/failed_jobs.txt
	echo "sent failed jobs to cluster"
fi


#COMBINE AND SORT CHAINFILES
chainmergesort=1
if [ "$chainmergesort" = 1 ] ; then
	echo "chainMergeSort:"
	echo "${CHAINMERGESORT} ${D_CHAIN}/*.chain > ${D_FINAL}/merged.chain"
	${CHAINMERGESORT} ${D_CHAIN}/*.chain > ${D_FINAL}/merged.chain
	echo "chainMergeSort done"
fi


#MAKE ALIGNMENT NETS FROM CHAINS
chainnet=1
if [ "$chainnet" = 1 ] ; then
	echo "chainNet:"
	echo ${CHAINNET} ${D_FINAL}/merged.chain ${D_OLD}/chrom.sizes ${D_NEW}/chrom.sizes ${D_FINAL}/merged.net /dev/null
	${CHAINNET} ${D_FINAL}/merged.chain ${D_OLD}/chrom.sizes ${D_NEW}/chrom.sizes ${D_FINAL}/merged.net /dev/null
	echo "chainNet done"
fi


#CREATE LIFTOVER CHAIN FILE
chainover=1
if [ "$chainover" = 1 ] ; then
	echo "netChainSubset:"
	echo ${NETCHAINSUBSET} ${D_FINAL}/merged.net ${D_FINAL}/merged.chain ${D_FINAL}/merged.over.chain
	${NETCHAINSUBSET} ${D_FINAL}/merged.net ${D_FINAL}/merged.chain ${D_FINAL}/merged.over.chain
	echo "netChainSubset done"
fi
