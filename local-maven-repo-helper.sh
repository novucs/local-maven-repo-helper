#!/usr/bin/env bash

read -e -p ":: Enter the repo to install to: " repo
repo=$(echo ${repo} | sed -e "s/'//g")

while true
do
  read -e -p ":: Enter the JAR file path: " jar
  jar=$(echo ${jar} | sed -e "s/'//g")

  if [ ! -f ${jar} ]
  then
    continue
  fi

  files=$(jar tf ${jar})

  yml_name=""
  yml_main=""
  yml_version=""

  groupId=""
  artifactId=""
  version=""

  if [[ ${files} == *"plugin.yml"* ]]
  then
    eval $(unzip -p ${jar} plugin.yml | sed \
      -re "/^(([^a-zA-Z\d].*)|([a-zA-Z0-9_-]*:\s*[^a-zA-Z0-9\.\d_\"-]*)|(\s*))$/d" \
      -e "s/:[^:\/\/]/=\"/g;s/$/\"/g;s/ *=/=/g" \
      -e "s/^/yml_/")

    if [[ ${yml_name} != "" && ${yml_main} != "" && ${yml_version} != "" ]]
    then
      groupId=$(echo ${yml_main} | rev | cut -d"." -f2- | rev)
      artifactId=$(echo ${yml_name,,} | sed -e "s/\s\+/-/g")
      version=${yml_version}
      echo "Using groupId:    " ${groupId}
      echo "Using artifactId: " ${artifactId}
      echo "Using version:    " ${version}

      if [[ ${version} == *" "* ]]
      then
        read -p ":: Enter conventional version: [${version}] " version1
        if [[ ${version1} != "" ]]
        then
          version=${version1}
        fi
      fi

      read -p ":: Do you wish to use this information? [Y/n] " input

      case ${input} in
        [Nn]* )
          groupId=""
          artifactId=""
          version=""
      esac
    fi
  fi

  if [[ ${groupId} == "" || ${artifactId} == "" || ${version} == "" ]]
  then
    read -p ":: Enter the groupId: " groupId
    read -p ":: Enter the artifactId: " artifactId
    read -p ":: Enter the version: " version
  fi

  mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file  \
    -Dfile="${jar}" \
    -DgroupId="${groupId}" \
    -DartifactId="${artifactId}" \
    -Dversion="${version}" \
    -Dpackaging=jar \
    -DlocalRepositoryPath="${repo}"

  read -p ":: Do you wish to install another JAR? [Y/n] " input

  case ${input} in
    [Nn]* ) exit;;
    * ) continue;;
  esac
done

