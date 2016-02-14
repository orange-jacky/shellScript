send_mail="/data/lxm/scripts/send_mail"

function protect() {
  stamp=`date "+%Y-%m-%d %H:%M:%S"`
  label="$1"
  path=$2
  command=$3

  num=`ps -ef |grep "$label"|grep -v grep|wc -l`
  if [ $num -ne 0 ]; then
    echo "$stamp find $label"
  else
    echo "$stamp not find $label, to start"  
    cd "$path"
    $command &
    $send_mail -c "${label} down"
  fi
}

i=0
while :
do
  temp=`expr $i \% 30`
  if [ $temp -eq 0 ]; then
    protect "cf_index conf/cf.ini" "/data/lxm/cf_index" "sh start.sh"
  fi

  temp=`expr $i \% 30`
  if [ $temp -eq 0 ]; then
    protect "cf_index_update conf/cf.ini" "/data/lxm/cf_index_update" "sh start.sh"
  fi

  sleep 1
  ((i=i+1))
done
