kubectl get pods --namespace=cumulus | awk '{print $1}' | sed -n '1!p' > pod-names.txt
for dir in ~/efs-access-logs/*
do
	var=`echo $dir |rev |  cut -d '/' -f1 | rev`
	if grep -Fxq "$var" pod-names.txt
	then
		echo "$var Directory found"
		echo "Files in $var"
		for file in ~/efs-access-logs/$var/*.log; do
			var1=`echo $file |rev |  cut -d '/' -f1 | rev`
			echo $var1
			if [ "$var1" == "access_log.log" ]
			then
				echo "$var1 log file cannot move to EFS as pod is still running"
			else
				echo "$var1 is compressed and moved to s3 bucket"
				pod_name=`echo ${var}|rev | cut -d '-' -f1| rev`
				version=`echo ${var}|rev | cut -d '-' -f2| rev`
				service_name3=`echo ${var}|rev | cut -d '-' -f3| rev`
				service_name2=`echo ${var}|rev | cut -d '-' -f4| rev`
				service_name1=`echo ${var}|rev | cut -d '-' -f5| rev`
				if [ "$service_name1" == "" ]
				then
					service_name=$service_name2-$service_name3
				else
					service_name=$service_name1-$service_name2-$service_name3
				fi
				sudo gzip $file
				sudo aws s3 mv $file.gz s3://<s3-bucket-name>/env/date=`date '+%Y%m%d'`/hour=`date '+%H'`/service=$service_name/version=$version/pod=$pod_name/$var1.gz --metadata "name=$var1,version=$version,podname=$pod_name,compressed=true"
			fi
		done
	else
		echo "$var Directory not found"
		echo "Files in $var"
		for file in ~/efs-access-logs/$var/*.log; do
				var2=`echo $file |rev |  cut -d '/' -f1 | rev`
				echo $var2
                                pod_name=`echo ${var}|rev | cut -d '-' -f1| rev`
                                version=`echo ${var}|rev | cut -d '-' -f2| rev`
                                service_name3=`echo ${var}|rev | cut -d '-' -f3| rev`
                                service_name2=`echo ${var}|rev | cut -d '-' -f4| rev`
                                service_name1=`echo ${var}|rev | cut -d '-' -f5| rev`
                                if [ "$service_name1" == "" ]
                                then
                                        service_name=$service_name2-$service_name3
                                else
                                        service_name=$service_name1-$service_name2-$service_name3
                                fi
                                sudo gzip $file
                                sudo aws s3 mv $file.gz s3://<s3-bucket-name>/env/datetime=`date '+%Y%m%d'`/hour=`date '+%H'`/service=$service_name/version=$version/pod=$pod_name/$var2.gz --metadata "name=$var2,version=$version,podname=$pod_name,compressed=true"
		done
	fi
done
for dir in ~/efs-access-logs/* 
do
	if [ "$(ls -A $dir)" ]; then
     		echo "$dir is not Empty"
	else
    		echo "$dir is Empty"
		sudo rm -rf $dir
		echo "$dir is deleted" 
	fi

done
