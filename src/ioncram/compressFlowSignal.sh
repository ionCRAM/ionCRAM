#!/bin/bash
###########################################################
# Usage: ./compress.sh  <reference> <Output file.tar>
# Bam/SAM is feeded through the stdin
# Example: ./compress.sh hg19.fa out.icram.tar < Ion.bam
############################################################


ref=$1
Out_tar=$2
compression=$3

binFolder='/home/mostafa/Documents/SHGP/icram/ioncram-2.2/bin/'

r=$RANDOM

fs="$Out_tar.$r.fs"
fs2="$Out_tar.$r.fs2"




samIn1="$Out_tar.$r.samIn1"
args="$Out_tar.$r.args"


set -e
function cleanup {
    rm  -f $Out_prefix.cram  $fsOut $fs2Out  $Out_tar.$r.* $argsOut
}
trap cleanup EXIT



mkfifo  $fs $fs2 $samIn1 $args


Out_prefix="${Out_tar%.*}"
filename=$(basename "$Out_prefix")
outDir=$(dirname "$Out_tar")


samtools view -h - | tee $samIn1  | grep -oP "ZM:B:s,[^\t]*"|sed -e 's/ZM:B:s,//' | ${binFolder}writer_varLenDiffSep   $fs $fs2 &

cat $samIn1 |sed -e 's/ZM:B:s,[^\t]*\t//'|tee $args |cut -f-11 | ${binFolder}scramble  -O cram  -r $ref -p -P -9 -Z - > $Out_prefix.cram &


if [ $compression == 'xz' ]
then
    fsOut=$Out_prefix.fs.xz
    fs2Out=$Out_prefix.fs2.xz
    argsOut=$Out_prefix.args.xz
    cat $args| samtools view - | cut -f12- | xz  -c > $Out_prefix.args.xz &
    cat $fs | xz  -c > $Out_prefix.fs.xz &
    cat $fs2 | xz   -c  > $Out_prefix.fs2.xz &
elif [ $compression == 'gzip' ]
then
    fsOut=$Out_prefix.fs.gz
    fs2Out=$Out_prefix.fs2.gz
    argsOut=$Out_prefix.args.gz
    cat $args| samtools view - | cut -f12- | gzip -9 -c > $Out_prefix.args.gz &
    cat $fs | gzip -9 -c > $Out_prefix.fs.gz &
    cat $fs2 | gzip  -9  -c  > $Out_prefix.fs2.gz &
elif [ $compression == 'bzip2' ]
then
    fsOut=$Out_prefix.fs.bz2
    fs2Out=$Out_prefix.fs2.bz2
    argsOut=$Out_prefix.args.bz2
    cat $args| samtools view - | cut -f12- | bzip2  -9 -c > $Out_prefix.args.bz2 &
    cat $fs | bzip2 -9 -c > $Out_prefix.fs.bz2 &
    cat $fs2 | bzip2  -9  -c  > $Out_prefix.fs2.bz2 &
elif [ $compression == 'zstd' ]
then
    fsOut=$Out_prefix.fs.zst
    fs2Out=$Out_prefix.fs2.zst
    argsOut=$Out_prefix.args.zst
    cat $args| samtools view - | cut -f12- | zstd --ultra -22 -c > $Out_prefix.args.zst &
    cat $fs  | zstd --ultra -22 -c > $Out_prefix.fs.zst  &
    cat $fs2 | zstd --ultra -22 -c > $Out_prefix.fs2.zst &
else
    fsOut=$Out_prefix.fs.xz
    fs2Out=$Out_prefix.fs2.xz
    argsOut=$Out_prefix.args.xz
    cat $args| samtools view - | cut -f12- | xz -c > $Out_prefix.args.xz &
    cat $fs | xz  -c > $Out_prefix.fs.xz &
    cat $fs2 | xz   -c  > $Out_prefix.fs2.xz &
fi

wait
fsSize=$( ls  -ls $fsOut $fs2Out| cut -f1 -d' '   | awk '{sum+=$1} END {print sum}')
>&2 echo "Flowsignal size=" $fsSize

$binFolder/cram_size $Out_prefix.cram | $binFolder/cram_size_aggregator

tar -cf $Out_tar -C $outDir $filename.cram  $( basename $fsOut )   $( basename $fs2Out ) $( basename $argsOut )

rm $Out_prefix.cram  $fsOut $fs2Out  $Out_tar.$r.* $argsOut
