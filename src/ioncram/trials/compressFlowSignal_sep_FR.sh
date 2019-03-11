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
fs4="tmp.$r.fs4"

filename=$(basename "$Out_tar")
Out_prefix="${filename%.*}"

mkfifo  $fs $fs2 $fs3 $fs4



cat $fs | xz -e -9 -c > $Out_prefix.fs.xz &
cat $fs2 | xz -e  -9  -c  > $Out_prefix.fs2.xz &
cat $fs3 | xz -e  -9  -c  > $Out_prefix.fs3.xz &
cat $fs4 | xz -e  -9  -c  > $Out_prefix.fs4.xz &


./icram view -F16 $Bam  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ./writer_varLenDiffSep   $fs $fs2      & 

./icram view -f16 $Bam  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ./writer_varLenDiffSep   $fs3 $fs4      & 

./icram view -h $Bam |sed -e 's/ZM:B:s,[^\t]*\t//' | ./icram view -T $ref   -@ 64 -C - > $Out_prefix.cram  &

#md5sum_original=$(cat $sam2 |md5sum &) 


wait

tar -cf $Out_tar $Out_prefix.cram  $Out_prefix.fs.xz   $Out_prefix.fs2.xz $Out_prefix.fs3.xz $Out_prefix.fs4.xz

rm $Out_prefix.cram  $Out_prefix.fs.xz    tmp.$r.* $Out_prefix.fs2.xz $Out_prefix.fs3.xz $Out_prefix.fs4.xz


#md5sum_cram=$(./decompress.sh $Out_tar | md5sum )

#if [ "$md5sum_original" == "$md5sum_cram" ]
#then
#    echo "compress  and decompress Succesfully  md5sums: $md5sum_original $md5sum_cram"
#    ls -lsah $Out_prefix*
#else
#    echo "Files are not the same md5sums: $md5sum_original $md5sum_cram"
#    python compare_sam_unaligned.py <(samtools view -@ 64 $Bam ) <(./decompress.sh $Out_tar)
#fi


