--https://ahmadfattah.wordpress.com/2018/05/21/oracle-rman-database-full-hot-backup-script/

# ***********************************************************************
# $Header: abc_rman_full_hot_bkp.sh *
#************************************************************************
# * Author: Ahmed Abdel Fattah *
#************************************************************************
# * DESCRIPTION: Take rman full hot backup(incremental level 0 ) *
# * PLATFORM:	Linux/Solaris/HP-UX/AIX *
#***********************************************************************

#!/bin/bash

# Check the login user to be “oracle”
# ————————————
usr=`id |cut -d”(” -f2 | cut -d “)” -f1`

if [ $usr != “oracle” ]
then
echo “You should login as oracle user”
exit 1
fi

# Check that ORACLE_HOME was set
# ——————————
#oh=$ORACLE_HOME
#if [ -z $oh ]
#then
# echo “You should set the oracle environment”
# exit 1
#fi

# Check that the user passed one parameter
# —————————————-

if [ $# -lt 1 ] ; then #not given enough parameters to script
cat <> $lg
echo >> $lg
echo ========== started on `date` ========== >> $lg
echo “ORACLE_SID: $sid” >> $lg
echo “ORACLE_USER: $usr” >> $lg
echo “ORACLE_HOME: $oh” >> $lg
echo “RMAN Log File: $lg” >> $lg
echo ============================================================ >> $lg

rman msglog $lg append << EOF

connect target / set echo on;

configure controlfile autobackup on;

run

{

sql "alter session set nls_date_format=''dd-mm-yyyy hh24:mi:ss''";

allocate channel c1 device type disk ;

allocate channel c2 device type disk ;

allocate channel c3 device type disk ;

allocate channel c4 device type disk ;

backup as compressed backupset incremental level 0 database tag 'weekly_hot_backup' plus archivelog tag 'weekly_hot_backup';

release channel c1 ;

release channel c2 ;

release channel c3 ;

release channel c4 ;

}

exit

EOF

echo ========== Completed at `date` ========== >> $lg

 
