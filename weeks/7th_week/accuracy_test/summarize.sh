tool=$1
for a in 200 400 800 1600 3200 7200 10000; do
    echo -n $a ' '
    awk '{print $2}' ${tool}_${a}.txt |
        var |
        tail -n +2 |
        awk '{print $2, $4/sqrt($5)}'
done
