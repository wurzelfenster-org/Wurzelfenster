#!/bin/bash


print_usage() {
    EXE_NAME="scan.sh"
    echo "    "
    echo "Usage:"
    echo "    ./${EXE_NAME} "
    echo "    "
    echo "    Optional args:"
    echo "    -d <dpi resolution> (default 600)"
    echo "    -f <png|tiff|jpeg> scan output file format (default tiff)"
    echo "    -l list connected scanners and exit"
    echo "    -p <output file prefix> (default 'kresse')"
    echo ""
    echo "    example (simple should-just-work run): ./${EXE_NAME}"
    echo "    example (list connected scanners): ./${EXE_NAME} -l"
    echo "    example (quick scan test): ./${EXE_NAME} -d 50"
}

check_dependencies() {
  hash scanimage 2>/dev/null || {
    echo >&2 "Required 'scanimage' is not installed. Aborting.";
    exit 1;
    }

  hash convert 2>/dev/null || {
    echo >&2 "Required 'convert' is not installed. Aborting.";
    exit 1;
    }
}


# default values
dpi=300
scan_dir="/home/pi/scans/"
counter_file="scanCount.txt"
prefix="kresse"
format=tiff


# validate arguments
while getopts "d:f:p:lh?" OPTION
do
    case ${OPTION} in
        d)  if [[ $OPTARG =~ -.* ]]; then
                echo "Missing argument for -d"
                exit 1
            fi
            dpi=$OPTARG
            ;;
        f)  case ${OPTARG} in
                "tiff") format=tiff;;
                "png") format=png;;
                "jpeg") format=jpeg;;
                *) echo "Wrong argument for -f option!"; print_usage; exit 1;;
            esac
            ;;
        l)  check_dependencies
            scanimage -L
            exit 0
            ;;
        p)  if [[ $OPTARG =~ -.* ]]; then
                echo "Missing argument for -p"
                exit 1
            fi
            prefix=$OPTARG
            ;;
        h)  print_usage
            exit 0
            ;;
        ?)  print_usage
            exit 1
            ;;
    esac
done

check_dependencies

# run the script
start=`date +%s`
date=$(date -d "today" +"%Y-%m-%d-%H-%M")

# get the scan number
if ! [[ -f ${scan_dir}${counter_file} ]]
then
    mkdir -p ${scan_dir}
    echo 1 > ${scan_dir}${counter_file}
else
    count=`cat ${scan_dir}${counter_file}`
    filename=${prefix}-${dpi}-$(printf %04d ${count})
    ((count++))
    echo $count > ${scan_dir}${counter_file}
fi

# scan
startScan=`date +%s`
scanimage --warmup-time=30 --resolution=$dpi --format=$format -l0 -t0 -x210 -y297 --depth=8 -v > ${scan_dir}${filename}.${format}
endScan=`date +%s`
runtimeScan=$((endScan-startScan))
echo "scan done. $runtimeScan sec"

# convert tiff to png
startConversion=`date +%s`
convert ${scan_dir}${filename}.${format} ${scan_dir}${filename}.png
endConversion=`date +%s`
runtimeConversion=$((endConversion-startConversion))
echo "conversion done. $runtimeConversion sec"
rm ${scan_dir}${filename}.${format}
echo "cleanup done"

end=`date +%s`
runtime=$((end-start))

echo "$date img $count duration: $runtime sec"
