for file in `cat file_list.txt`; do
  # Save the current file in PROCESSING, so we know about the progress
  echo "$file" > PROCESSING
  # Abort if file ABORT is present
  if [ -e ABORT ] ; then
    echo "Aborting..."
    break
  fi
  echo "Downloading $file"
  wget --directory-prefix=zip -q -m "ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/$file"
  echo "Processing $file"
  mkdir -p "data/$file"
  tar xfz "zip/ftp.ncbi.nlm.nih.gov/pub/pmc/$file" -C "data/$file/.."
done
