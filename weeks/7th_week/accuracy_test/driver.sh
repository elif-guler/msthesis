date
seqLen=$1
tool=$2
it=10
markerLengths="200 400 800 1600 3200 7200 10000"

((midpoint=$seqLen/2))

for markerLen in $markerLengths; do
    echo "markerLen: $markerLen"
    ((markerStart=$midpoint-$markerLen/2))
    ((markerEnd=$midpoint+$markerLen/2))

    file=${tool}_${markerLen}.txt
    echo -n '' > $file

    for b in $(seq $it); do

        # Generate sample
        stan -r $markerStart-$markerEnd -o -l $seqLen

        # Run selected tool
        if [ "$tool" = "fur" ]; then
            makeFurDb -t targets -n neighbors -d test.db -o 2>&1 > /dev/null
            fur -d test.db > markers_fur.fasta
        else
            seqwin --tar-dir targets --neg-dir neighbors -o seqwin-out --overwrite > /dev/null
            cp seqwin-out/signatures.fasta markers_seqwin.fasta
        fi

	# Calculate accuracy
        if [ "$tool" = "fur" ]; then
            sblast markers_fur.fasta targets/t1.fasta |
                awk -v ts=$markerStart -v te=$markerEnd -v seqLen=$seqLen -f acc.awk >> $file
        else
            sblast markers_seqwin.fasta targets/t1.fasta |
                awk -v ts=$markerStart -v te=$markerEnd -v seqLen=$seqLen -f acc.awk >> $file
        fi

    done
done

date
