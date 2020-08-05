#! /bin/bash

start=`date +%s`

counter_file="scanCount.txt"
if [ -f $counter_file ]
then
	count=`cat $counter_file`
else
    echo ERROR: the file $counter_file does not exist.
fi

scanDir="/media/card/"
prefix="kresse"
dpi="600"
date=$(date -d "today" +"%Y-%m-%d-%H-%M")
filename=$prefix-$dpi-$(printf %04d $count)

((count++))
echo $count > $counter_file

startScan=`date +%s`
scanimage --mode=color --resolution=$dpi --format=tiff -l0 -t0 -x215 -y297 > $filename.tiff
endScan=`date +%s`
runtimeScan=$((endScan-startScan))
echo "scan done. $runtimeScan sec"

startConversion=`date +%s`
convert $filename.tiff $scanDir$filename.png
endConversion=`date +%s`
runtimeConversion=$((endConversion-startConversion))
echo "conversion done. $runtimeConversion sec"

rm $filename.tiff
echo "cleanup done"

end=`date +%s`
runtime=$((end-start))

echo "$date img $count duration: $runtime sec"