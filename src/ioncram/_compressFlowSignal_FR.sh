#!/bin/bash
###########################################################
# Usage: ./compress.sh  <reference> <Output file.tar>
# Bam/SAM is feeded through the stdin
# Example: ./compress.sh hg19.fa out.icram.tar < Ion.bam
############################################################

bam=$1
ref=$2
compression=$3
lossy=$4
threshold=$5
bedFile=$6
noSplits=$7
Out_tar=$8


binFolder=

DATE=$(date +"%Y-%m-%d-%H-%M")
r="$DATE.$RANDOM"

tmpFolder="compressWorkDir.$r"
mkdir $tmpFolder
set -e
function cleanup {
    rm -rf $tmpFolder/
}
trap cleanup EXIT





Out_prefix="${Out_tar%.*}"
filename=$(basename "$Out_prefix")
outDir=$(dirname "$Out_tar")


bed=''
if [ $bedFile != 'no' ]
then
    bed="-L $bedFile "
fi


# lossyOut=''
#
# if [ $lossy == 'yes' ]
# then
#     dupFifo="tmp.$r.dupFifo"
#     mkfifo $dupFifo
#     samtools view -h $bed $bam |python3 ${binFolder}seperateDuplicates.py $threshold $dupFifo  |tee $samIn1  > $samIn2 &
#     lossyOut=$Out_prefix.lossy.tar
#     ${binFolder}compressFlowSignal.sh $ref $lossyOut $compression < $dupFifo &
# else
#     samtools view -h $bed  $bam  |tee $samIn1 > $samIn2 &
# fi

chrs="$tmpFolder/$filename.chrs"
simpleH="$tmpFolder/tmp.$r.simpleH"

#samtools view -H $bam | grep "@SQ" |cut -f2 |cut -f2 -d:  > $chrs
$binFolder/splitChrs $bam> $chrs

#samIn1="tmp.$r.samIn1"
#samIn2="tmp.$r.samIn2"

#mkfifo $samIn1 $samIn2
parallel --gnu -a $chrs --colsep '\t' "mkfifo  $tmpFolder/tmp.$r.{1}.samIn1 $tmpFolder/tmp.$r.{1}.samIn2" 



samtools view -H $bam | tee >(xz -c > $tmpFolder/$filename.header.xz)  |grep -v "@CO" > $simpleH



parallel --gnu -a $chrs --colsep '\t' -k -j $noSplits  "cat $simpleH <(samtools view  $bed  $bam {2}| ${binFolder}filterReadsStartBeforeRegion {2}) |tee $tmpFolder/tmp.$r.{1}.samIn1 > $tmpFolder/tmp.$r.{1}.samIn2"  &

parallel --gnu -a $chrs --colsep '\t' -j 0   "samtools view -h  -F16   $tmpFolder/tmp.$r.{1}.samIn2 | ${binFolder}compressFlowSignal.sh $ref $tmpFolder/$filename.{1}.forward.tar $compression " & 

parallel --gnu -a $chrs --colsep '\t'  -j 0  "samtools view -h  -f16  $tmpFolder/tmp.$r.{1}.samIn1  |  ${binFolder}compressFlowSignal.sh $ref $tmpFolder/$filename.{1}.reverse.tar $compression "   &

samtools view -h  $bam "*" | ${binFolder}compressFlowSignal.sh $ref $tmpFolder/$filename.unmapped.tar $compression &

wait

tars=$( parallel  --gnu -a $chrs --colsep '\t' -k echo "$filename.{1}.reverse.tar" "$filename.{1}.forward.tar"  |tr -s $'\n' ' '  )




tar -cf $Out_tar -C $tmpFolder/  $tars  $filename.unmapped.tar $lossyOut $filename.header.xz $filename.chrs

rm -rf $tmpFolder/
#rm -f  tmp.$r.*  $Out_prefix.*.reverse.tar  $Out_prefix.*.forward.tar $Out_prefix.unmapped.tar   $lossyOut $chrs $Out_prefix.header.xz
