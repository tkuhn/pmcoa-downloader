#!/bin/bash

TODAY=`date '+%Y-%m-%d'`

mkdir -p logs
exec >> logs/$TODAY.log 2>&1

rm -f TERMINATED
rm -f PROCESSING


echo "DOWNLOAD FILE LIST"
#     ------------------

mkdir -p filelist
if [ ! -e filelist/$TODAY.txt ] ; then
  wget ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/file_list.txt -O filelist/$TODAY.txt
fi
if [ ! -e filelist/$TODAY.txt ] ; then
  echo "ERROR: Could not find or download file list"
  exit
fi


echo "PREPROCESS FILE LIST"
#     --------------------

cat filelist/$TODAY.txt | sed -e '1,1 d' | awk '{ print $1 }' | sort > file_list.tmp


echo "DOWNLOAD DATA"
#     -------------

mkdir -p zip
mkdir -p data

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
  fi
  if [ -e zip/ftp.ncbi.nlm.nih.gov/pub/pmc/$file ] && [ ! -e data/$file ] ; then
    echo "Processing $file"
    mkdir -p "data/$file"
    tar xfz "zip/ftp.ncbi.nlm.nih.gov/pub/pmc/$file" -C "data/$file/.."
  fi
done


echo "CLEAN UP"
#     --------

rm -f *.tmp
rm -f ABORT

if [ -e PROCESSING ] ; then
  mv PROCESSING TERMINATED
else
  touch TERMINATED
fi
