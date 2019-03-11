
###########################################################
# Usage: ./compress.sh <Bam_file> <reference> <Output file.tar>
############################################################


Bam=$1
ref=$2
threshold=$3
Out_tar=$4

binFolder=


r=$RANDOM
dup="tmp.$r.dup"



Out_prefix="${Out_tar%.*}"
filename=$(basename "$Out_prefix")
outDir=$(dirname "$Out_tar")


mkfifo  $dup

${binFolder}compressFlowSignal_Streaming.sh $ref $Out_prefix.duplicates.icram.tar < $dup &

samtools  view -h $Bam | python3 ${binFolder}seperateDuplicates.py $threshold $dup | ${binFolder}compressFlowSignal_Streaming.sh $ref  $Out_prefix.icram.tar &




wait

tar -cf $Out_tar -C $outDir  $filename.duplicates.icram.tar $filename.icram.tar

rm tmp.$r.*  $Out_prefix.duplicates.icram.tar $Out_prefix.icram.tar
