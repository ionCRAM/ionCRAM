#!/bin/bash
###########
# Usage: ./decompress.sh <cram tar file> <reference fasta file>
# Sam output is printed directly to the stdout
###########


cram_tar=$1
ref=$2
noSplits=$3
out_bam=$4

binFolder='/home/mostafa/Documents/SHGP/icram/ioncram-2.2/bin/'

DATE=$(date +"%Y-%m-%d-%H-%M")
r="$DATE.$RANDOM"

tmpFolder="decompressWorkDir.$r"
mkdir $tmpFolder

tarFiles="$tmpFolder/files.$r"
splitFiles="$tmpFolder/splitfiles.$r"
bamFifo="$tmpFolder/bam.$r.fifo"
bamsOrder="$tmpFolder/bam.$r.order"
bamsTmp="$tmpFolder/bam.$r.Tmp"


tar -C $tmpFolder -xvf $cram_tar > $tarFiles

header=$( grep "header" $tarFiles |sed -e 's/.xz//')

prefix=$(echo $header |sed -e 's/.header//')


unmapped=$( grep "unmapped" $tarFiles)
chrs=$( grep "chrs" $tarFiles)



xz -d $tmpFolder/$header.xz

sed -i "/$header/d" $tarFiles
sed -i "/$unmapped/d" $tarFiles
sed -i "/$chrs/d" $tarFiles

#parallel --gnu "mkfifo $tmpFolder/{}.fifo" < $tarFiles
#fifos=$( cat $tarFiles|sed -e "s/\(.*\)/$tmpFolder\/\1.fifo/"| tr -s $'\n' ' ' )

cat $tarFiles |sed -e 's/.forward.tar//' |sed -e 's/.reverse.tar//'|sort |uniq > $splitFiles


bams=$( cat $tmpFolder/$chrs | cut -f1| sed -e "s/\(.*\)/$tmpFolder\/$prefix.\1.bam/" |tr -s $'\n' ' ' )


#parallel --gnu "mkfifo $tmpFolder/{}.split.fifo" < $splitFiles
#noFiles=$( wc -l $tarFiles )
${binFolder}decompressFlowSignal.sh $tmpFolder/$unmapped $ref |samtools view -bS - > $tmpFolder/$unmapped.bam &

parallel --gnu -j $noSplits "samtools merge -p -c -f --reference $ref -h $tmpFolder/$header  -O BAM $tmpFolder/{}.bam  <(${binFolder}decompressFlowSignal.sh $tmpFolder/{}.forward.tar $ref ) <(${binFolder}decompressFlowSignal.sh $tmpFolder/{}.reverse.tar $ref )" :::: $splitFiles

wait
#parallel --gnu  "${binFolder}decompressFlowSignal.sh $tmpFolder/{} $ref |samtools view -bS -  > $tmpFolder/{}.fifo  " < $tarFiles


if [ $out_bam == '-' ]
then
    #    samtools merge -p -c -f --reference $ref -h $tmpFolder/$header  -O BAM >(cat )   $fifos
    samtools cat -h $tmpFolder/$header -o $out_bam $bams $tmpFolder/$unmapped.bam
else
#    samtools merge -p -c -f --reference $ref -h $tmpFolder/$header  -O BAM $out_bam  $fifos
    samtools cat -h $tmpFolder/$header -o $out_bam $bams $tmpFolder/$unmapped.bam
fi





#parallel --gnu 'rm $tmpFolder/{}' < $tarFiles
rm -rf $tmpFolder
