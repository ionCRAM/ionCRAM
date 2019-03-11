if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
    echo "usage: ./ionStatistics.sh binaries_folder/ bam_file  reference_fasta_file  compression_method(xz|gzip|zstd) "
exit 0
fi 


binFolder=$1
bam=$2
ref=$3
compressionTool=$4


beforeSize=$( ls -ls $bam |cut -f1 -d' ' )
/usr/bin/time -v -o $bam.compress.time ${binFolder}/ioncram  compress -r $ref -i $bam -o $bam.icram -z $compressionTool -v  > $bam.log

afterSize=$( ls -ls $bam.icram |cut -f1 -d' ' )

beforeSizeFormated=$( echo  $beforeSize |python3 ${binFolder}/sizeFormatter.py )
afterSizeFormated=$( echo  $afterSize |python3 ${binFolder}/sizeFormatter.py )
icramPercent=$(( 100- (($afterSize*100)/$beforeSize) ))

flowSize=$(grep "AUX(including FlowSignal)" $bam.log|cut -f2 -d=)

compressTime=$(grep "Elapsed" $bam.compress.time |grep -oP "[^ ]*$")
compressMemory=$(grep "Maximum resident set size" $bam.compress.time  |grep -oP "[^ ]*$")
compressMemory=$(( $compressMemory / 1024))


/usr/bin/time -v -o $bam.decompress.time ${binFolder}/ioncram decompress  -r $ref -i $bam.icram -o $bam.bam 2> /dev/null

decompressTime=$(grep "Elapsed" $bam.decompress.time |grep -oP "[^ ]*$")
decompressMemory=$(grep "Maximum resident set size" $bam.decompress.time  |grep -oP "[^ ]*$")
decompressMemory=$(( $decompressMemory / 1024))


echo "Bam Name = " $bam
echo "Bam Size= " ${beforeSizeFormated}
echo "ioncram Size= " ${afterSizeFormated}
echo "Saved % =  $icramPercent%"
echo "Flowsignal size= " $flowSize
echo "Compression Time= " $compressTime
echo "Compression Memory=  ${compressMemory}MB"
echo "Decompression Time= " $decompressTime
echo "Decompression Memory=  ${decompressMemory}MB"

#echo -e  "$bam\t${beforeSizeFormated}\t${afterSizeFormated}\t$icramPercent%\t$flowSize\t$compressTime\t${compressMemory}MB\t$decompressTime\t${decompressMemory}MB"

rm $bam.icram  $bam.log $bam.compress.time $bam.decompress.time $bam.bam -f
