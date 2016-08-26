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

buildFolder="${dir}/build"
taxonIdFolder="${dir}/build/taxonId"

mkdir -p "${buildFolder}"
mkdir -p "${taxonIdFolder}"

wg="wget --load-cookies ${buildFolder}/imgt-cookies.txt --save-cookies ${buildFolder}/imgt-cookies.txt -qO-"

if [ ! -f "${buildFolder}/speciesIMGT" ]
then
  $wg 'http://imgt.org/genedb/' | pup '#Species option attr{value}' | grep -v any > ${buildFolder}/speciesIMGT
fi

speciesA=()

while read sp;
do
  speciesA+=("$sp")
done < <(cat ${buildFolder}/speciesIMGT | grep Homo)

speciesCount="${#speciesA[@]}"

echo "${speciesCount}"

for species in "${speciesA[@]}";
do
    if [ -z "${species}" ];
    then
        continue
    fi

    echo "Processing ${species}"

    taxonIdFile="${taxonIdFolder}/$(echo ${species} | sed 's/ /_/g')"
    prefix='http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=taxonomy&term='
    url=$(echo ${species} | sed 's/ /%20/g')
    url="${prefix}${url}"
    if [ ! -f "${taxonIdFile}" ]
    then
        wget -qO- "$url" | xmllint --xpath '/eSearchResult/IdList/Id[1]/text()' - > "${taxonIdFile}"
    fi
    taxonId=$(cat "${taxonIdFile}")
    echo "OK. TaxonId=${taxonId}"
done
