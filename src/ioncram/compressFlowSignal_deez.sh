#!/bin/bash
###########################################################
# Usage: ./compress.sh  <reference> <Output file.tar>
# Bam/SAM is feeded through the stdin
# Example: ./compress.sh hg19.fa out.icram.tar < Ion.bam
############################################################


ref=$1
Out_tar=$2
compression=$3
bedFile=$4

deezBinary=''
binFolder='/home/mostafa/Documents/SHGP/icram/ioncram-2.2/bin/'

r=$RANDOM

fs="tmp.$r.fs"
fs2="tmp.$r.fs2"
aux="tmp.$r.aux"


samIn1="tmp.$r.samIn1"
samIn2="tmp.$r.samIn2"
header="tmp.$r.header"

set -e
function cleanup {
    rm -f  $Out_prefix.dz  $auxOut $fsOut $fs2Out $headerOut  tmp.$r.*
}
trap cleanup EXIT


mkfifo  $fs $fs2 $samIn1  $aux  $header


Out_prefix="${Out_tar%.*}"
filename=$(basename "$Out_prefix")
outDir=$(dirname "$Out_tar")

bed=''
if [ $bedFile != 'no' ]
then
    bed="-L $bedFile "
fi


samtools view $bed -h -| tee >(grep -P "^@" > $header) $samIn1  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ${binFolder}writer_varLenDiffSep   $fs $fs2 &

cat $samIn1 |sed -e 's/ZM:B:s,[^\t]*\t//'|  python3 ${binFolder}separate_ION_data.py $aux  | samtools view -bS - > $samIn2 &



if [ $compression == 'xz' ]
then
    fsOut=$Out_prefix.fs.xz
    fs2Out=$Out_prefix.fs2.xz
    auxOut=$Out_prefix.aux.xz
    headerOut=$Out_prefix.header.xz
    cat $header | xz -e -9 -c > $Out_prefix.header.xz &
    cat $aux | xz -e -9 -c > $Out_prefix.aux.xz &
    cat $fs | xz -e -9 -c > $Out_prefix.fs.xz &
    cat $fs2 | xz -e  -9  -c  > $Out_prefix.fs2.xz &
elif [ $compression == 'gzip' ]
then
    fsOut=$Out_prefix.fs.gz
    fs2Out=$Out_prefix.fs2.gz
    auxOut=$Out_prefix.aux.gz
    headerOut=$Out_prefix.header.gz
    cat $header | gzip -9 -c > $Out_prefix.header.gz &
    cat $aux | gzip -9 -c > $Out_prefix.aux.gz &
    cat $fs | gzip -9 -c > $Out_prefix.fs.gz &
    cat $fs2 | gzip  -9  -c  > $Out_prefix.fs2.gz &
elif [ $compression == 'bzip2' ]
then
    fsOut=$Out_prefix.fs.bz2
    fs2Out=$Out_prefix.fs2.bz2
    auxOut=$Out_prefix.aux.bz2
    headerOut=$Out_prefix.header.bz2
    cat $header | bzip2 -9 -c > $Out_prefix.header.bz2 &
    cat $aux | bzip2 -9 -c > $Out_prefix.aux.bz2 &
    cat $fs | bzip2 -9 -c > $Out_prefix.fs.bz2 &
    cat $fs2 | bzip2  -9  -c  > $Out_prefix.fs2.bz2 &
elif [ $compression == 'zstd' ]
then
    fsOut=$Out_prefix.fs.zst
    fs2Out=$Out_prefix.fs2.zst
    auxOut=$Out_prefix.aux.zst
    headerOut=$Out_prefix.header.zst
    cat $header  | zstd --ultra -22 -c > $Out_prefix.header.zst  &
    cat $aux  | zstd --ultra -22 -c > $Out_prefix.aux.zst  &
    cat $fs  | zstd --ultra -22 -c > $Out_prefix.fs.zst  &
    cat $fs2 | zstd --ultra -22 -c > $Out_prefix.fs2.zst &
else
    fsOut=$Out_prefix.fs.gz
    fs2Out=$Out_prefix.fs2.gz
    auxOut=$Out_prefix.aux.gz
    headerOut=$Out_prefix.header.gz
    cat $header | gzip -9 -c > $Out_prefix.header.gz &
    cat $aux | gzip -9 -c > $Out_prefix.aux.gz &
    cat $fs | gzip -9 -c > $Out_prefix.fs.gz &
    cat $fs2 | gzip  -9  -c  > $Out_prefix.fs2.gz &
fi


wait

#./icram view  -C -T hg19.fa -o $Out_prefix.dz $samIn2
${deezBinary}   -r $ref $samIn2 -o $Out_prefix.dz
fsSize=$(ls --block-size=M -lsh $fsOut $fs2Out | tr -d 'M' |awk '{sum+=$6} END {print sum"MB"}')
>&2 echo "Flowsignal size=" $fsSize

tar -cf $Out_tar -C $outDir $filename.dz  $( basename $fsOut )   $( basename $fs2Out ) $( basename $auxOut ) $( basename $headerOut )

rm -f  $Out_prefix.dz  $auxOut $fsOut $fs2Out $headerOut  tmp.$r.*
