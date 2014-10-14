#! /sbin/sh

#log file info
filepath=/home/xiaoxu
filename=group-1
absfile=$filepath/$filename

#flag file info
flagpath=$filepath
flagfilename=flag_$filename
absflagfile=$flagpath/$flagfilename

#initlize variable value
flagline=0
lastline=0
programname=`basename $0`
threshold=15


#exit state
ok=0
warning=1
critical=2
unknown=3



curdate=`date +%y%m%d`
checktime=`date +%X`	


#avoid call this shell again before the privious call not finished
count=`ps -ef | grep $programname | wc -l` 
if [ $count -gt 3 ] ; then
	 echo "ok - check time is $checktime,last call is running,current call exit"
	 exit $ok
fi



#flag file exist
if `ls $absflagfile > /dev/null 2>&1` ; then
	
	#check date changes or not
	lastcheckdate=`awk '{print $1}' $absflagfile`
	flagline=`awk '{print $2}' $absflagfile`
	curtotalline=`wc -l $absfile | awk '{print $1}'`

	if [ "x"$flagline = "x" ] ; then
			rm -f $absflagfile
			echo "ok - check time is $checktime,$absflagfile has broke,next check will check the full file again."
			exit $ok
	fi

	if [ "x"$lastcheckdate = "x" ] ; then
			rm -f $absflagfile
			echo "ok - check time is $checktime,$absflagfile has broke,next check will check the full file again."
			exit $ok
	fi
	
	if [ "x"$lastcheckdate != "x"$curdate ] ; then
		rm -f $absflagfile
		echo "ok - check time is $checktime,check date changes from $lastcheckdate to $curdate"
		exit $ok
	fi

	if [ $curtotalline -eq $flagline ] ; then
			echo "ok - check time is $checktime, log not update"
			exit $ok
	elif [ $curtotalline -lt $flagline ] ; then
			rm -f $absflagfile
			echo "ok - check time is $checktime,check date changes from $lastcheckdate to $curdate"
			exit $ok
	else
		nextline=`expr $flagline + 1`
		checkresult=`sed -n ''$nextline',$p' $absfile | \
							 	 awk -F: '{print $NF}' | \
 							   awk '{print substr($0,1,blength-4)}' | \
							   awk 'BEGIN{sum=0;delay=0;totalline=0;delayline=0} \
										  {sum+=$1;totalline++;if($1>=1000){delay+=$1;delayline++}} \
										  END{printf "sum=%d,delay=%d,percent=%d,totalline=%d,delayline=%d", \
									 	  sum,delay,int(delayline*100/totalline),totalline,delayline}'`
									 
		totalline=`echo $checkresult | awk -F, '{print $4}' | awk -F= '{print $2}'`
		percent=`echo $checkresult | awk -F, '{print $3}' | awk -F= '{print $2}'`
		
		totalline=`expr $totalline + $flagline` 
		echo "$curdate $totalline" > $absflagfile
	
		if [ $percent -ge $threshold ] ; then
				echo "warning - check time is $checktime, current percent is $percent"
				exit $warning
		else	
				echo "ok - check time is $checktime, current percent is $percent"
				exit $ok
		fi
	
	fi


#flag file not exit
else
	checkresult=`awk -F: '{print $NF}' $absfile | \
 							 awk '{print substr($0,1,blength-4)}' | \
							 awk 'BEGIN{sum=0;delay=0;totalline=0;delayline=0} \
									 {sum+=$1;totalline++;if($1>=1000){delay+=$1;delayline++}} \
									 END{printf "sum=%d,delay=%d,percent=%d,totalline=%d,delayline=%d", \
									 sum,delay,int(delayline*100/totalline),totalline,delayline}'`
									 
	totalline=`echo $checkresult | awk -F, '{print $4}' | awk -F= '{print $2}'`
	percent=`echo $checkresult | awk -F, '{print $3}' | awk -F= '{print $2}'`
	
	echo "$curdate $totalline" > $absflagfile

	if [ $percent -ge $threshold ] ; then
			echo "warning - check time is $checktime, current percent is $percent"
			exit $warning
	else	
			echo "ok - check time is $checktime, current percent is $percent"
			exit $ok
	fi
fi



