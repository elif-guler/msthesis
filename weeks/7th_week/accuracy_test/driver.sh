date
seqLen=$1
tool=$2
it=10
markerLengths="200 400 800 1600"

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
            fur -d test.db > markers.fasta
        else
            seqwin --tar-dir targets --neg-dir neighbors -o seqwin-out --overwrite --penalty-th 0.2 > /dev/null
            cp seqwin-out/signatures.fasta markers.fasta
        fi

        # Calculate accuracy
        sblast markers.fasta targets/t1.fasta |
            awk -v ts=$markerStart -v te=$markerEnd -f acc.awk >> $file

    done
done
date
