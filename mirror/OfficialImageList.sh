#!/bin/sh


for filename in `ls library`
do
	cat library/${filename} | grep Tags: | grep -v SharedTags: | while read line
	do
		tagsLine=${line:6}
		#echo ${tagsLine}
		array=(${tagsLine//,/ })
		for tag in ${array[@]}
		do
		   echo "$filename:$tag" >> 1.txt
		done 
	done
done
