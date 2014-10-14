#!/usr/bin/sh

logfile=/var/adm/nettl.LOG000
flagfile=/var/opt/OV/tmp/flag_4a5b.txt
timestampFile=/var/opt/OV/tmp/timestamp_4a5b.txt
tmpFile=/var/opt/OV/tmp/tmp_4a5b.txt

keyword=trying
flap=7
tStamp=

#get timestamp
ls $timestampFile > /dev/null 2>&1
if [ $? -eq 0 ] ; then
tStamp="`cat $timestampFile`"
fi

#get keyword line number
lines=`netfmt -NL $logfile | grep -n $keyword | awk -F: '{print $1}'`

#fetch string up to $flap line
for end in $lines
do
	start=`expr $end - $flap`
	netfmt -NL $logfile | sed -n ''$start','$end'p' | \
		awk -v timestampfile=$timestampFile -v tmpfile=$tmpFile \
				' /Timestamp/ {timestamp=sprintf("%s", $0);}
					/Subsystem/ {subsystem=sprintf("%s", $NF);}
					/Log Class/ {logclass=sprintf("%s", $NF);}
					/trying/	  {msg=sprintf("%s", $0);}
					
					END{
							#printf("%s\n", timestamp);
							#printf("%s^%s^%s^%s\n", timestamp, subsystem, logclass, msg);					
							printf("%s\n", timestamp) > timestampfile;
							printf("%s^%s^%s^%s\n", timestamp, subsystem, logclass, msg) >> tmpfile ;
					}
				'
done


#frist check
if [ x"$tStamp" =  x"" ] ; then
	rm -f $flagfile
	#awk 'BEGIN{FS="^";OFS="^";}{print $2,$3,$4}' $tmpFile >> $flagfile
	echo "" > $flagfile
	rm -f $tmpFile 
	
	echo "frist check"
	
#more than one check
else

	timestampline=`grep -n "$tStamp" $tmpFile | awk -F: '{print $1}'`
	totalline=`wc -l $tmpFile | awk '{print $1}'`
	#echo "$timestampline $totalline"
	if [ $timestampline -lt $totalline ] ; then
		nextline=`expr $timestampline + 1`
		rm -f $flagfile
		sed -n ''$nextline',$p' $tmpFile | awk 'BEGIN{FS="^";OFS="^";}{print $2,$3,$4}' >> $flagfile
		rm -f $tmpFile
		echo "have lastest ip conflict"
	else
		echo "" > $flagfile
		echo "no lastest ip conflict"
		rm -f $tmpFile		
	fi
fi


exit 0;


