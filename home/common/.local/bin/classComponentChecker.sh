#!/bin/bash

echo "Running a component checking script"
counter=0

function find_class_component {
#variables
 local file="$1"
 local searchTerm=$(cat "$file")
 #find and count class components
 if [[ $searchTerm == *"<Column "* || $searchTerm == *"<Row"* ]];
then
echo "$1 is a Column or Row component."
counter=$((counter+1))
fi
}

function read_dir {
for file in "$1"/*; do
if [[ -d "$file" ]];
then
read_dir "$file"
elif [[ $file == *.js || $file == *.jsx || $file == *.tsx ]];
then
find_class_component "$file"
fi
done
}

read_dir "./src"

echo "The project has $counter Column or Row components.
Update them to functional components whenever possible."
