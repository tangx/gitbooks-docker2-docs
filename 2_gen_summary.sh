#!/bin/bash
#

cd $(dirname $0)
source /etc/profile
function gen_local_readme()
{
    # echo "[${1}](README.md)"
    echo "${1}"

    for sub_dir_file in $(ls ${1})
    do
    {
        [ $sub_dir_file == "SUMMARY.md" ] && continue
        [ $sub_dir_file == "README.md" ] && continue

        # set -x
        if [ -d ${1}/$sub_dir_file ]
        then
        {
          echo "  + [$sub_dir_file]($sub_dir_file/README.md)"
          # continue
        }
        fi
        # set +x

        if [ "${sub_dir_file//*./}" == "md" ]
        then
        {
          echo "  + [$sub_dir_file]($sub_dir_file)"
        }
        fi

    }
    done
}

function gen()
{

    cd ${1}
    for dir_file in $(ls )
    do
    {

        [ $dir_file == "SUMMARY.md" ] && continue
        [ $dir_file == "README.md" ] && continue
        [ $dir_file == "999.examples" ] && continue
        [ $dir_file == "998.dockerfiles" ]  && echo "+ [998.dockerfiles](998.dockerfiles/README.md)" && continue
        [ $dir_file == "997.docker-compose-files" ]  && echo "+ [997.docker-compose-files](997.docker-compose-files/README.md)" && continue

        if [ -d $dir_file ]
        then
        {

            ROOT_DIR=${ROOT_DIR}/${dir_file}


            gen_local_readme $dir_file > $dir_file/README.md

            echo "${2}+ [${dir_file}](${ROOT_DIR}/README.md)"
            # echo "${2}+ [${dir_file}]()"


            gen ${dir_file} "${2}  "


            ROOT_DIR=$(dirname ${ROOT_DIR})

        }
        elif [ "${dir_file//*./}" == "md" ]
        then
        {
            # 以文件名作为目录名
            echo "${2}+ [$(basename ${dir_file%%.md})](${ROOT_DIR}/${dir_file})"

            # 以标题行作为目录名
            # title_line=$(grep -w '#' ${dir_file} | head -n 1 | sed 's/# //')
            # echo "${2}+ [$(basename ${title_line})](${ROOT_DIR}/${dir_file})"
        }
        fi
    }
    done
    cd ..

}


ROOT_DIR=.
gen . > SUMMARY.md

# gen $ROOT_DIR

# gen .


echo "+ [本地仓库代理](999.examples/002.registry_proxy/registry_proxy.md)" >> SUMMARY.md