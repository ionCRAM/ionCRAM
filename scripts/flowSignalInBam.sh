if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
    echo "usage: ./flowSingalInBam binaries_folder/ bam_file"
exit 0
fi 


binFolder=$1
bam=$2


beforeSize=$( ls -ls $bam |cut -f1 -d' ')
samtools view -h  $bam |sed -e 's/ZM:B:s,[^\t]*\t//' |samtools view -bS - > $bam.withoutFS.bam
afterSize=$( ls -ls $bam.withoutFS.bam |cut -f1 -d' ')

flowSize=$(( ($beforeSize - $afterSize)))

flowSizePercent=$(( ($flowSize*100)/$beforeSize ))
flowSizeFormatted=$( echo $flowSize | python3 ${binFolder}sizeFormatter.py )
#echo  -e   "${flowSizeFormatted}\t$flowSizePercent%"
echo "Flowsignal Size= ${flowSizeFormatted}"
echo "Flowsignal Percent= $flowSizePercent%"
rm $bam.withoutFS.bam -f
