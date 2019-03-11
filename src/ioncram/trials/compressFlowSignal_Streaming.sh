###########################################################
# Usage: ./compress.sh  <reference> <Output file.tar> 
############################################################


ref=$1
Out_tar=$2




r=$RANDOM
header="tmp.$r.header"

fs="tmp.$r.fs"
fs2="tmp.$r.fs2"
fs3="tmp.$r.fs3"
fs4="tmp.$r.fs4"

samIn1="tmp.$r.samIn1"
samIn2="tmp.$r.samIn2"
samIn3="tmp.$r.samIn3"

mkfifo  $fs $fs2 $fs3 $fs4 $samIn1 $samIn2  


Out_prefix="${Out_tar%.*}"
filename=$(basename "$Out_prefix")
outDir=$(dirname "$Out_tar")



cat $fs | xz -e -9 -c > $Out_prefix.fs.xz &
cat $fs2 | xz -e  -9  -c  > $Out_prefix.fs2.xz &
cat $fs3 | xz -e  -9  -c  > $Out_prefix.fs3.xz &
cat $fs4 | xz -e  -9  -c  > $Out_prefix.fs4.xz &



tee $samIn1 $samIn2|./icram view - |sed -e 's/ZM:B:s,[^\t]*\t//' | ./icram view -T $ref   -@ 64 -C - > $Out_prefix.cram  &

./icram view -F16  $samIn1  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ./writer_varLenDiffSep   $fs $fs2      & 

./icram view -f16  $samIn2  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ./writer_varLenDiffSep   $fs3 $fs4      & 







#md5sum_original=$(cat $sam2 |md5sum &) 


wait

tar -cf $Out_tar -C $outDir $filename.cram  $filename.fs.xz   $filename.fs2.xz $filename.fs3.xz $filename.fs4.xz

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


