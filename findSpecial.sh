#! /bin/bash

path="/data/search/is/logs2/search"
file="search.log"
linefile="myline.txt"
keyword="from=special"
resultfile="myresults.log"
kafka="10.172.170.35:9092,10.172.222.129:9092,10.172.220.147:9092"
topic="myislog"
curdir="/data/search/cf_collectlog"
send_kafka="$curdir/send_kafka"

programname=`basename $0`
ymdh=`date -d "-1 hours" +20%y-%m-%d-%H`

pfile="${path}/${file}"
lfile="${path}/${linefile}"
rfile="${path}/${resultfile}"
oldfile="${path}/${file}.${ymdh}"

pidfile="${path}/pid.txt"
curpid=$$
if `ls $pidfile >/dev/null 2>&1` ; then
    lastpid=`cat $pidfile`
    find="`ps -p $lastpid | wc -l`"
    if (( $find == 2 )) ; then
      echo "last call have not finished. please try agagin"
      exit 0 
    fi
fi
echo $curpid > $pidfile

rm -f $rfile >/dev/null 2>&1
#lfine exist
if `ls $lfile >/dev/null 2>&1` ; then
    lastinode=`cat $lfile | awk '{print $1}'`
    lastline=`cat $lfile | awk '{print $2}'`
    curinode=`ls -i $pfile 2>/dev/null | awk '{print $1}'`
    if [ "x"$curinode = "x" ] ; then
      rm -f $lfile $rfile >/dev/null 2>&1
      exit 0 
    fi
    curline=`wc -l $pfile | awk '{print $1}'`
    ((nextline=lastline+1))
    if (( $lastinode !=  $curinode )) ; then
      sed -n ''$nextline',$p' $oldfile |sed -n '/'${keyword}'/p' >> $rfile    
      sed -n '1,$p'  $pfile | sed -n '/'${keyword}'/p' >> $rfile
      echo "$curinode $curline" > $lfile
    else
      sed -n ''$nextline',$p' $pfile |sed -n '/'${keyword}'/p' >> $rfile    
      echo "$curinode $curline" > $lfile
    fi
#file not exist
else 
   inode=`ls -i $pfile 2>/dev/null | awk '{print $1}'`
   if [ "x"$inode = "x" ] ; then
    exit 0
   fi
   line=`wc -l $pfile | awk '{print $1}'`
   echo " $inode $line" > $lfile
   sed -n '/'${keyword}'/p' $pfile >> $rfile  
fi

#upload result
#scp $rfile $dstpath >/dev/null 2>&1
${send_kafka} -h $kafka -t $topic -f $rfile