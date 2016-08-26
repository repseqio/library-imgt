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

input=""
redownload=false

while [[ $# > 0 ]]
do
    key="$1"
    shift
    case $key in
        -d)
            redownload=true
            ;;
        *)
            input="${key}"
            ;;
    esac
done

buildFolder="${dir}/build"

wg="wget --load-cookies ${buildFolder}/imgt-cookies.txt --save-cookies ${buildFolder}/imgt-cookies.txt -qO-"

taxonId=$(jq -r '.taxonId' ${input})
sNames=$(jq -r -c '.speciesNames' ${input})

jq -r -c '.rules[]' ${input} | \
while read rule;
do
    t=$(echo "${rule}" | jq -r '.ruleType')
    if [[ "${t}" == "import" ]];
    then
        output=$(echo "${rule}" | jq -r '.output')
        chain=$(echo "${rule}" | jq -r '.chain')
        geneType=$(echo "${rule}" | jq -r '.geneType')
        pFastaFile=${buildFolder}/$(basename ${output}).p.fasta

        # Downloading file
        if [ ! -f ${pFastaFile} ] || [ ${redownload} == true ];
        then
            rm -f ${pFastaFile}
            echo "${rule}" | jq -r -c '.sources[]' | \
            while read src;
            do
                echo "Downloading: ${src}"
                $wg ${src} | pup -p 'pre:last-of-type' | sed "/^$/d" | sed "/<.*pre>/d" | sed 's/ *//' >> ${pFastaFile}
            done
        fi

        # Loading points position
        points=$(echo "${rule}" | jq -r '.anchorPoints[] | "-P" + .point + "=" + (.position | tostring)' | tr '\n' ' ')

        repseqio fromPaddedFasta ${points} --chain ${chain} --taxon-id ${taxonId} --gene-type ${geneType} \
            --name-index 1 --functionality-index 3 ${pFastaFile} ${output}.fasta ${output}.json
    fi
done
