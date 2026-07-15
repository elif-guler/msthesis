for a in 200 400 800 1600; do
    echo -n $a ' '
    awk '{print $2}' $a.txt |
	var |
	tail -n +2 |
	awk '{print $2, $4/sqrt($5)}'
done
