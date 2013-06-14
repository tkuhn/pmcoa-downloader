#!/bin/bash

TODAY=`date '+%Y-%m-%d'`

mkdir -p logs
exec >> logs/$TODAY.log 2>&1

rm -f TERMINATED
rm -f PROCESSING


echo "DOWNLOAD FILE LIST"
#     ------------------

mkdir -p lists

if [ ! -e lists/file_list-$TODAY.txt ] ; then
  echo "file_list.txt" > PROCESSING
  wget ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/file_list.txt -O lists/file_list-$TODAY.txt
fi
if [ ! -e lists/file_list-$TODAY.txt ] ; then
  echo "ERROR: Could not find or download file_list.txt"
  exit
fi

if [ ! -e lists/PMC-ids-$TODAY.csv ] ; then
  echo "PMC-ids.csv.gz" > PROCESSING
  wget ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/PMC-ids.csv.gz -O lists/PMC-ids.csv.gz
  gunzip lists/PMC-ids.csv.gz
  mv lists/PMC-ids.csv lists/PMC-ids-$TODAY.csv
fi
if [ ! -e lists/PMC-ids-$TODAY.csv ] ; then
  echo "ERROR: Could not find or download PMC-ids.csv"
  exit
fi


echo "DOWNLOAD XML"
#     ------------

mkdir -p xml

if [ ! -e xml/$TODAY ] ; then
  mkdir -p xml/$TODAY
  echo "articles.*.tar.gz" > PROCESSING
  wget --directory-prefix="xml/$TODAY" ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/articles.*.tar.gz
  for f in xml/$TODAY/*.tar.gz ; do
    n=$(basename "$f")
    n="${n%.tar.gz}"
    mkdir -p xml/$TODAY/$n
    tar xfz "$f" -C "xml/$TODAY/$n"
  done
fi


echo "PREPROCESS FILE LIST"
#     --------------------

cat lists/file_list-$TODAY.txt | sed -e '1,1 d' | awk '{ print $1 }' | sort > file_list.tmp
NFILES=`cat file_list.tmp | wc -l`


echo "DOWNLOAD DATA"
#     -------------

mkdir -p zip
mkdir -p data

NDOWN=0
NUNPACK=0

for file in `cat file_list.tmp`; do
  # Save the current file in PROCESSING, so we know about the progress
  echo "$file" > PROCESSING
  # Abort if file ABORT is present
  if [ -e ABORT ] ; then
    echo "Aborting..."
    break
  fi
  if [ ! -e zip/ftp.ncbi.nlm.nih.gov/pub/pmc/$file ] ; then
    echo "Downloading $file"
    wget --directory-prefix=zip -q -m "ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/$file"
    let NDOWN=NDOWN+1
  fi
  d="${file%.tar.gz}"
  p=$(dirname ${file})
  if [ -e zip/ftp.ncbi.nlm.nih.gov/pub/pmc/$file ] && [ ! -e data/$d ] ; then
    echo "Unpacking $file"
    mkdir -p data/$p
    tar xfz "zip/ftp.ncbi.nlm.nih.gov/pub/pmc/$file" -C "data/$p"
    let NUNPACK=NUNPACK+1
  fi
done


echo "CLEAN UP"
#     --------

echo "$TODAY: $NFILES files; $NDOWN downloaded; $NUNPACK unpacked." >> logs/main.log

rm -f *.tmp
rm -f ABORT

if [ -e PROCESSING ] ; then
  mv PROCESSING TERMINATED
else
  touch TERMINATED
fi
