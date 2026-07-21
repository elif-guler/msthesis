date
chmod +x pipeline.sh

for d in clo mtb sen
do
    (
        cd "$d"
        ../pipeline.sh
    )
done
date
