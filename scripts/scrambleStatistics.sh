if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
    echo "usage: ./scrambleStatistics.sh binaries_folder/ bam_file  reference_fasta_file "
exit 0
fi 

binFolder=$1
bam=$2
ref=$3

beforeSize=$( ls -ls $bam |cut -f1 -d' ')
/usr/bin/time -v -o $bam.compress.time ${binFolder}/scramble -O cram -p -P -Z -9 -r $ref $bam $bam.cram



afterSize=$( ls -ls $bam.cram |cut -f1 -d' ')

beforeSizeFormated=$( echo  $beforeSize |python3 ${binFolder}/sizeFormatter.py )
afterSizeFormated=$( echo  $afterSize |python3 ${binFolder}/sizeFormatter.py )

cramPercent=$((  100-(($afterSize*100)/$beforeSize) ))

${binFolder}/cram_size $bam.cram > $bam.log

 
flowSize=$(grep "ZMB" $bam.log|grep -oP "total size *[0-9]*" |sed -e 's/[^0-9]*//g'|awk '{print $1/1024}' |python3 ${binFolder}/sizeFormatter.py)


compressTime=$(grep "Elapsed" $bam.compress.time |grep -oP "[^ ]*$")
compressMemory=$(grep "Maximum resident set size" $bam.compress.time  |grep -oP "[^ ]*$")
compressMemory=$(( $compressMemory / 1024))

/usr/bin/time -v -o $bam.decompress.time ${binFolder}/scramble -O bam  -r $ref $bam.cram  $bam.bam 2> /dev/null
#/usr/bin/time -v -o $bam.decompress.time ${binFolder}/icram view -@ 4 -b  -T $ref $bam.cram > $bam.bam 2> /dev/null

decompressTime=$(grep "Elapsed" $bam.decompress.time |grep -oP "[^ ]*$")
decompressMemory=$(grep "Maximum resident set size" $bam.decompress.time  |grep -oP "[^ ]*$")
decompressMemory=$(( $decompressMemory / 1024))


#echo -e  "$bam\t${beforeSizeFormated}\t${afterSizeFormated}\t$cramPercent%\t$flowSize\t$compressTime\t${compressMemory}MB\t$decompressTime\t${decompressMemory}MB"

echo "Bam Name = " $bam
echo "Bam Size= " ${beforeSizeFormated}
echo "CRAM Size= " ${afterSizeFormated}
echo "Saved % = " $cramPercent
echo "Flowsignal size= " $flowSize
echo "Compression Time= " $compressTime
echo "Compression Memory= " $compressMemory "MB"
echo "Decompression Time= " $decompressTime
echo "Decompression Memory= " $decompressMemory "MB"

rm $bam.cram  $bam.log $bam.compress.time $bam.decompress.time $bam.bam -f
