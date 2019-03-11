###########
# Usage: ./decompress.sh <cram tar file> <reference fasta file>
# Sam output is printed directly to the stdout
###########


cram_tar=$1
ref=$2


filename=$(basename "$cram_tar")
cram_prefix="${filename%.*}"


binFolder='/home/mostafa/Documents/SHGP/icram/ioncram-2.2/bin/'
deezBinary=''

r=$RANDOM

stream1="tmp.stream1.$r"
stream2="tmp.stream2.$r"
stream3="tmp.stream3.$r"
icramFiles="tmp.files.$r"


set -e
function cleanup {
    rm -f tmp.stream*$r $cram_prefix.dz $fs $fs2 $header $aux
}
trap cleanup EXIT


mkfifo  $stream2 $stream3
tar -xvf  $cram_tar > $icramFiles


fs=$(cat $icramFiles | grep "fs\.")
fs2=$(cat $icramFiles | grep "fs2\.")
header=$(cat $icramFiles | grep "header\.")
aux=$(cat $icramFiles | grep "aux\.")



${deezBinary} -r $ref $cram_prefix.dz -o $stream1



compression=$(file $fs)

if [[ $compression == *"XZ"* ]]
then
    xz -dc $header
    xz -dc $aux > $stream3 &
    ${binFolder}reader_varLenDiffSep <(xz -dc $fs) <(xz -dc $fs2) | awk '{print "ZM:B:s,"$1}'  > $stream2 &
elif [[ $compression == *"gzip"* ]]
then
    gzip -dc $header
    gzip -dc $aux > $stream3 &
    ${binFolder}reader_varLenDiffSep <(gzip -dc $fs) <(gzip -dc $fs2) | awk '{print "ZM:B:s,"$1}'  > $stream2 &
elif [[ $compression == *"bzip2"* ]]
then
    bzip2 -dc $header
    bzip2 -dc $aux > $stream3 &
    ${binFolder}reader_varLenDiffSep <(bzip2 -dc $fs) <(bzip2 -dc $fs2) | awk '{print "ZM:B:s,"$1}'  > $stream2 &
elif [[ $compression == *"zst"* ]]
then
    zstd -dc $header
    zstd -dc $aux > $stream3 &
    ${binFolder}reader_varLenDiffSep <(zstd -dc $fs) <(zstd -dc $fs2) | awk '{print "ZM:B:s,"$1}'  > $stream2 &
fi


paste <(cat $stream1) <(cat $stream2) <(cat $stream3)

rm -f tmp.stream*$r $cram_prefix.dz $fs $fs2 $header $aux
