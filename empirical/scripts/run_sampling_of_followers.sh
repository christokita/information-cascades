while true
do
	Rscript 05_sample_user_follower_ideologies.R
	echo ERROR: Script crashed. Sleeping 10 seconds and restarting...
	sleep 10
done
