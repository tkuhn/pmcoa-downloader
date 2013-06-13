wget ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/file_list.txt -O original_file_list.txt
cat original_file_list.txt | sed -e '1,1 d' | sort > file_list.txt
