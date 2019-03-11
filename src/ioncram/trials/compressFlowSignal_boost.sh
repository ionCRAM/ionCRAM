###########################################################
# Usage: ./compress.sh <Bam_file> <reference> <Output file.tar> 
############################################################


Bam=$1
ref=$2
Out_tar=$3




r=$RANDOM
header="tmp.$r.header"
sam1="tmp.$r.sam1"
sam2="tmp.$r.sam2"
fs="tmp.$r.fs"
fs2="tmp.$r.fs2"
fs3="tmp.$r.fs3"

filename=$(basename "$Out_tar")
Out_prefix="${filename%.*}"

mkfifo $header $sam1 

./icram view -H $Bam >$header &


./icram view $Bam |tee $sam1  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ./writer_varLenDiffCompressed   $Out_prefix.fs.bz2      & 

cat $header  $sam1 |sed -e 's/ZM:B:s,[^\t]*\t//' | ./icram view -T $ref   -@ 64 -C - > $Out_prefix.cram  &

#md5sum_original=$(cat $sam2 |md5sum &) 


wait

tar -cf $Out_tar $Out_prefix.cram  $Out_prefix.fs.bz2  
rm $Out_prefix.cram  $Out_prefix.fs.bz2    tmp.$r.* 


#md5sum_cram=$(./decompress.sh $Out_tar | md5sum )

#if [ "$md5sum_original" == "$md5sum_cram" ]
#then
#    echo "compress  and decompress Succesfully  md5sums: $md5sum_original $md5sum_cram"
#    ls -lsah $Out_prefix*
#else
#    echo "Files are not the same md5sums: $md5sum_original $md5sum_cram"
#    python compare_sam_unaligned.py <(samtools view -@ 64 $Bam ) <(./decompress.sh $Out_tar)
#fi


