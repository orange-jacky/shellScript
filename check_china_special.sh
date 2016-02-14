#! /bin/bash
send_mail="/data/lxm/scripts/send_mail_to_users"
kafka_offset="/data/lxm/scripts/kafka_offset"
hosts="10.172.170.35:9092,10.172.222.129:9092,10.172.220.147:9092"
topic="SpecialSeat"
#topic="test"
file="/data/lxm/scripts/file.txt"
sleeptime=60
inter=3
users="lixm@133.cn,hujr@133.cn"

while :
do
offset=""
declare -A array 
array=()
declare -A oldarray
oldarray=()

newtime=`date +%s`
result="`$kafka_offset -h $hosts -t $topic | awk '/offset/{print $0}'`"
for i in `echo $result`
do
	array[$i]=$i
	offset="${offset}${i} "
done  

if `ls $file >/dev/null 2>&1` ; then
  oldtime=`cat $file| awk -F\; '{print $1}'`
  oldoffset="`cat $file | awk -F\; '{print $2}'`"
  for old in `echo $oldoffset`
  do
  	oldarray[$old]=$old 
  done

  for key in ${!array[*]}
  do
	echo "$key  ${oldarray[$key]}"
	if [ "x"$key != "x"${oldarray[$key]} ] ;  then
		echo "$newtime;$offset" > $file
		break
	fi 
  done
#file not exist
else 
   echo "$newtime;$offset" > $file
fi
	sub=`expr ${newtime} - ${oldtime}`
	if ((${sub} > ${inter}*3600)) ; then
		${send_mail} -c "kafka's topic $topic has no new data for $inter hours" -t $users
	fi
	sleep $sleeptime
done