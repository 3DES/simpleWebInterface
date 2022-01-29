#!/bin/bash

sourcePath=html
targetPath=html/compressed

if [ -d $targetPath ]; then
    # compress js files
    for file in $sourcePath/*.js
    do
        fileName=$(basename $file)
        echo compress [$fileName]
        uglifyjs --compress --mangle --mangle-props --verbose -- "$file" > "$targetPath/$fileName"
    done

    # compress html files
    for file in $sourcePath/*.html
    do
        fileName=$(basename $file)
        echo compress [$fileName]
        html-minifier --collapse-whitespace --remove-comments --remove-optional-tags --remove-redundant-attributes --remove-script-type-attributes --remove-tag-whitespace --use-short-doctype --minify-css true --minify-js true "$file" > "$targetPath/$fileName"
    done

    # compress css files (not implemented so far..., so copy rest just over)
    for file in $sourcePath/*
    do
        if [ -f $file ]; then
            fileName=$(basename $file)
            extension="${file#*.}"
            if [ $extension != "html" ] && [ $extension != "js" ] ; then
                echo copy [$fileName]
                cp $file $targetPath
            fi
        fi
    done
else
    echo "ERROR target path doesn't exist: $targetpath"
fi



