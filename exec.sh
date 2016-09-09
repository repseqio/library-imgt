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

cacheFolder="${dir}/cache"
outputFolder="${dir}/output"
mkdir -p ${cacheFolder}
mkdir -p ${outputFolder}

wg="wget --load-cookies ${cacheFolder}/imgt-cookies.txt --save-cookies ${cacheFolder}/imgt-cookies.txt -qO-"

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
        pFastaFile=${cacheFolder}/$(basename ${output}).p.fasta

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
        pointsP=$(echo "${rule}" | jq -r '.anchorPoints[] | select(.position != null) | "-P" + .point + "=" + (.position | tostring)' | tr '\n' ' ')
        pointsL=$(echo "${rule}" | jq -r '.anchorPoints[] | select(.aaPattern != null) | @sh "-L" + .point + "=" + (.aaPattern | tostring)' | tr '\n' ' ')
        points="${pointsP} ${pointsL}"

        repseqio fromPaddedFasta -f ${points} --ignore-duplicates --chain ${chain} --taxon-id ${taxonId} --gene-type ${geneType} \
            --name-index 1 --functionality-index 3 ${pFastaFile} ${dir}/${output}.fasta ${dir}/${output}.json

        cat ${dir}/${output}.json | jq ".[].speciesNames |= ${sNames}" > ${dir}/${output}.json.tmp
        mv ${dir}/${output}.json.tmp ${dir}/${output}.json
    fi

    if [[ "${t}" == "fixTraTrd" ]];
    then
        libFile=${dir}/$(echo "${rule}" | jq -r '.file')
        cat ${libFile} | \
          jq '(.[].genes[] | select((.name | test("^TRAV")) == true) .chains) |= ["TRAV"]' | \
          jq '(.[].genes[] | select((.name | test("DV")) == true) .chains) |= . + ["TRDV"]' | \
          jq '(.[].genes[] | select((.name | test("^TRDV")) == true) .chains) |= ["TRDV"]' > ${libFile}.tmp
        mv ${libFile}.tmp ${libFile}
    fi

    if [[ "${t}" == "removeTra" ]];
    then
        libFile=${dir}/$(echo "${rule}" | jq -r '.file')
        cat ${libFile} | \
          jq 'del(.[].genes[] | select((.name | test("^TRAV")) == true))' > ${libFile}.tmp
        mv ${libFile}.tmp ${libFile}
    fi
done
