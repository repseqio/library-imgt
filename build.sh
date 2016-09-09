#!/bin/bash

# Linux readlink -f alternative for Mac OS X
function readlinkUniversal() {
    targetFile=$1

    cd `dirname $targetFile`
    targetFile=`basename $targetFile`

    # iterate down a (possible) chain of symlinks
    while [ -L "$targetFile" ]
    do
        targetFile=`readlink $targetFile`
        cd `dirname $targetFile`
        targetFile=`basename $targetFile`
    done

    # compute the canonicalized name by finding the physical path
    # for the directory we're in and appending the target file.
    phys_dir=`pwd -P`
    result=$phys_dir/$targetFile
    echo $result
}

os=`uname`
delta=100

dir=""

case $os in
    Darwin)
        dir=$(dirname "$(readlinkUniversal "$0")")
    ;;
    Linux)
        dir="$(dirname "$(readlink -f "$0")")"
    ;;
    *)
       echo "Unknown OS."
       exit 1
    ;;
esac

cacheFolder="${dir}/cache"
outputFolder="${dir}/output"

if [[ "$1" == "full" ]];
then
    rm -rf ${cacheFolder}
    rm -rf ${outputFolder}
fi

mkdir -p ${cacheFolder}
mkdir -p ${outputFolder}

wg="wget --load-cookies ${cacheFolder}/imgt-cookies.txt --save-cookies ${cacheFolder}/imgt-cookies.txt -qO-"

for rule in ${dir}/rules/*.json;
do
    ${dir}/exec.sh ${rule}
done

tomerge=()

for file in ${dir}/output/*.json;
do
    out=${outputFolder}/$(basename ${file}).compiled
    repseqio compile -f ${file} ${out}
    tomerge+=("${out}")
done

imgtVersion=$($wg http://www.imgt.org/IMGT_vquest/share/textes/ | pup -p 'a[href="./datareleases.html"] text{}' | sed 's/ *//g')
tag=$(git describe --always --tags)

repseqio merge -f ${tomerge[@]} ${dir}/imgt.${tag}.${imgtVersion}.json.gz

