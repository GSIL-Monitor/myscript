#!/bin/bash

source /home/qishanqing/myscript/sh/cmdb
source /home/qishanqing/myscript/sh/svn.sh

set +x

export BUILD_ID=dontkillme

DT=`date '+%Y%m%dT%H%M%S'`
branch=$SVN_URL
version=$SVN_REVISION
job_name=$BUILD_URL
owner=$BUILD_USER_ID
jb=$JOB_NAME

if [ -f /mnt/svn/task_id.log ];then
    task_id=`cat /mnt/svn/task_id.log || true`
    rm -f /mnt/svn/task_id.log
    export task_id
fi

function replace_files () {
    #    find $file/ -name 'WEB-INF/classes/servicebus.xml' | xargs -i rm -f {}
    fils_name="upload/$file/WEB-INF/classes/servicebus.xml"
    if [ -f "$fils_name" ];then
	p=$(cat $fils_name | grep PoolPreparedStatements | grep true)
	t=$(cat $fils_name | grep TestOnBorrow | grep false)
	if [ ! -z "$p" ] || [ ! -z "$t" ];then
	    echo "请正确修改servicebus.xml参数PoolPreparedStatements和TestOnBorrow值"
	    exit
	fi
	sed -i '/\"PoolPreparedStatements\"/{s/true/false/g}' $fils_name
	sed -i '/\"TestOnBorrow\"/{s/false/true/g}' $fils_name
    fi
}

function upload_version () {
    rm -rf upload
#    find -maxdepth 2 -name '*.jar' -print -o -maxdepth 3 -name '*.jar' -print >& /dev/null  && echo 请让对应开发人员修改pom配置编译为war格式,不支持jar格式上传 && exit 1
    find -maxdepth 3 -name *.war -print | while read filename
    do	
	mkdir -p upload
	cp -rf $filename upload/
	filename=${filename##*/}
	if [[ "$filename" =~ '-' ]];then
		file="${filename%%-*}-$DT"
	else
		file="${filename%%.*}-$DT"
	fi
	file=dev-$file
	replace_files && createtag
	unzip -oq upload/$filename -d upload/$file
	(
	    cd upload
	    zip -r $file.zip $file/*
	    mv $file.zip /mnt/svn/ && echo "上传成功"
	)
    done
}

upload_version

