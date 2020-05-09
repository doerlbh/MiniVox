# author: Baihan Lin (doerlbh@gmail.com)
# to clean up the data for postprocessing

rm idlist.txt

for f in `ls | grep id`
do
	cd $f
	for w in `ls */*`
	do
		rename -v "s#/#_#g" $w
	done 
    find . -type d -empty -delete
    ls *.wav > wavlist.txt
	cd ..
done

ls | grep id > idlist.txt
