date
seqLen=$1
it=10
markerLengths="200 400 800 1600"
((midpoint=$seqLen/2))
for markerLen in $markerLengths; do
    echo "markerLen: $markerLen"
    ((markerStart=$midpoint-$markerLen/2))
    ((markerEnd=$midpoint+$markerLen/2))
    file=${markerLen}.txt
    echo -n '' > $file
    for b in $(seq $it); do
	# Generate sample
	stan -r $markerStart-$markerEnd -o -l $seqLen
	# Run fur
	makeFurDb -t targets -n neighbors -d test.db -o 2>&1 > /dev/null
	fur -d test.db > markers.fasta
	# Calculate accuracy
	sblast markers.fasta test.db/r.fasta |
	    awk -v ts=$markerStart -v te=$markerEnd -f acc.awk >> $file
    done
done
date
