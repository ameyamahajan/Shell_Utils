schema_name=$1
table=$2
arch_table=$3


for partition_name  in  `mysql --user=user_name --password=user_password -h host_name -D $schema_name -e "select PARTITION_NAME from information_schema.partitions where TABLE_NAME = '$table' and TABLE_SCHEMA='$schema_name' ORDER BY PARTITION_NAME ASC LIMIT 10" | grep -e '.*p[0-9]*' |grep -v "p0"`
do
# Creating partition and adding data to _archive table 
if [[ $arch_table != '' ]]
then
partition_date=`echo $partition_name |cut -d'p' -f2`
time_id=`date +"%Y-%m-%d"  -d"$partition_date+1 days"`
next_time_id=`date +"%Y-%m-%d"  -d"$time_id+1 days"`
echo "ALTER TABLE $schema_name.$arch_table ADD PARTITION (PARTITION $partition_name VALUES LESS THAN ('$time_id'));"  
echo "INSERT INTO $schema_name.$arch_table SELECT * FROM $schema_name.$arch_table WHERE time_id >='$time_id' AND time_id < '$next_time_id';"
fi


# Dropping partition
echo "ALTER TABLE $schema_name.$table DROP PARTITION  $partition_name" 
done


#Creating new partition 
begining_partition=p20151020
end_partition=p20151101
while [[ "$begining_partition" != "$end_partition" ]]
do
partition_date=`echo $begining_partition |cut -d'p' -f2`
time_id=`date +"%Y-%m-%d"  -d"$partition_date+1 days"`
next_time_id=`date +"%Y-%m-%d"  -d"$time_id+1 days"`
echo "ALTER TABLE $schema_name.$table ADD PARTITION (PARTITION $begining_partition VALUES LESS THAN ('$time_id'));"  
begining_partition=`date +"p%Y%m%d" -d"$time_id"`
done

