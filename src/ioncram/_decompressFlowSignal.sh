###########
# Usage: ./decompress.sh <cram tar file> <reference fasta file>
# Sam output is printed directly to the stdout
###########


cram_tar=$1
ref=$2


binFolder=
deezBinary=''

if [[ $cram_tar == *"deez"* ]]
then
${binFolder}decompressFlowSignal_deez.sh $cram_tar $ref
exit 0
elif [[ $cram_tar == *"lossy"* ]]
then
    echo "Decompression of lossy not implemented yet"
fi

filename=$(basename "$cram_tar")
cram_prefix="${filename%.*}"

tmpFolder=$( dirname "$cram_tar" )

r=$RANDOM

stream1="$cram_tar.stream1.$r"
stream2="$cram_tar.stream2.$r"
stream3="$cram_tar.stream3.$r"
icramFiles="$cram_tar.files.$r"

mkfifo $stream1 $stream2 $stream3


tar -C $tmpFolder -xvf  $cram_tar > $icramFiles

samtools view -H -T $ref $tmpFolder/$cram_prefix.cram
${binFolder}scramble -O sam -r $ref $tmpFolder/$cram_prefix.cram | grep -vP "^@"> $stream1  &



fs=$(cat $icramFiles | grep "fs\.")
fs2=$(cat $icramFiles | grep "fs2\.")
args=$(cat $icramFiles | grep "args\.")


binning=$(echo $fs |grep -oP "binning[0-9]*" |sed -e 's/binning//')

compression=$(file $tmpFolder/$fs)

if [[ $compression == *"XZ"* ]]
then
    ${binFolder}reader_varLenDiffSep <(xz -dc $tmpFolder/$fs) <(xz -dc $tmpFolder/$fs2)  $binning  | awk '{print "ZM:B:s,"$1}'  > $stream2 &
    xz -dc $tmpFolder/$args > $stream3 &
elif [[ $compression == *"gzip"* ]]
then
    ${binFolder}reader_varLenDiffSep <(gzip -dc $tmpFolder/$fs) <(gzip -dc $tmpFolder/$fs2) $binning | awk '{print "ZM:B:s,"$1}'  > $stream2 &
    gzip -dc $tmpFolder/$args > $stream3 &
elif [[ $compression == *"bzip2"* ]]
then
    ${binFolder}reader_varLenDiffSep <(bzip2 -dc $tmpFolder/$fs) <(bzip2 -dc $tmpFolder/$fs2)  $binning | awk '{print "ZM:B:s,"$1}'  > $stream2 &
    bzip2 -dc $tmpFolder/$args > $stream3 &
elif [[ $compression == *"zst"* ]]
then
    ${binFolder}reader_varLenDiffSep <(zstd -dc $tmpFolder/$fs) <(zstd -dc $tmpFolder/$fs2) $binning | awk '{print "ZM:B:s,"$1}'  > $stream2 &
    zstd -dc $tmpFolder/$args > $stream3 &
fi


paste <(cat $stream1) <(cat $stream3) <(cat $stream2)

rm -f $cram_tar.stream*$r $tmpFolder/$cram_prefix.cram $tmpFolder/$cram_prefix.fs*.xz $tmpFolder/$cram_prefix.fs2.xz $icramFiles $tmpFolder/$args $tmpFolder/$fs $tmpFolder/$fs2
 
