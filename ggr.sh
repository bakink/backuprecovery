udfs/scripts/ION/ION_full_backup.sh

You have new mail in /var/spool/mail/oracle
[oracle@horus ~]$ cat /cloudfs/scripts/SIDE/SIDE_full_backup.sh
################################################
#                                              #
#          METOD IT ACADEMY - 2016/02          #
#                                              #
################################################

##### ENVIRONMENT

. /home/oracle/.bash_profile                                         # DO NOT CHANGE THIS LINE
. /home/oracle/.side                                                 # CHANGE OR REMOVE
export NLS_DATE_FORMAT='DD-MM-YYYY HH24:MI:SS'                       # DO NOT CHANGE THIS LINE


##### GLOBAL VARIABLES

DATE=`date +%Y%m%d`                                                  # DO NOT CHANGE THIS LINE
DATE2=`date --date="yesterday" +%Y%m%d`                              # DO NOT CHANGE THIS LINE
LOG_DIRECTORY="/cloudfs/logs"                                        # SPECIFY PARENT DIRECTORY FOR LOG FILES ($LOG_DIRECTORY/backup will be used for backup log files)
SCRIPT_DIRECTORY="/cloudfs/scripts"                                  # SPECIFY PARENT DIRECTORY FOR SCRIPT FILES ($SCRIPT_DIRECTORY/$DB_NAME will be used)
R_BACKUP_DIRECTORY="/cloudfs/backup"                                 # RMAN PARENT DIRECTORY FOR BACKUP FILES ($BACKUP_DIRECTORY/$DB_NAME/rman will be used)
E_BACKUP_DIRECTORY="/cloudfs/backup"                                 # EXPORT PARENT DIRECTORY FOR BACKUP FILES ($BACKUP_DIRECTORY/$DB_NAME/export will be used)

##### DB SPECIFIC VARIABLES

DB_NAME="SIDE"                                                       # db unique name - prefer uppercase
EXPORT_DIR="EXPORT"                                                  # export directory alias from database
LOG_DIR="MTDDIR_LOG_BCK"                                             # export log directory alias from database


##### BACKUP

RMAN_STATUS="ENABLED"                                                # IF ENABLED then RMAN will run else skip rman
EXPORT_STATUS="ENABLED"                                              # IF ENABLED then DATA PUMP will run else skip export
EXPORT_PARALLELISM=6                                                 # DATA PUMP PARALLELISM: 1=NOPARALLEL


DB_LOG_DIRECTORY="${LOG_DIRECTORY}/${DB_NAME}/backup"                # DO NOT CHANGE THIS LINE - backup logs directory
DB_SCRIPT_DIRECTORY="${SCRIPT_DIRECTORY}/${DB_NAME}"                 # DO NOT CHANGE THIS LINE - backup scripts directory
RMAN_BACKUP_DIRECTORY="${R_BACKUP_DIRECTORY}/${DB_NAME}/rman"        # DO NOT CHANGE THIS LINE - rman backup directory
EXPORT_BACKUP_DIRECTORY="${E_BACKUP_DIRECTORY}/${DB_NAME}/export"    # DO NOT CHANGE THIS LINE - data pump backup directory
BACKUP_LOG_NAME=${DB_LOG_DIRECTORY}/${DB_NAME}_backup_${DATE}.log    # DO NOT CHANGE THIS LINE - log for backup script
RMAN_LOG_NAME=${DB_LOG_DIRECTORY}/${DB_NAME}_rman_${DATE}.log        # DO NOT CHANGE THIS LINE - log for rman backup
EXPORT_LOG_NAME=${DB_LOG_DIRECTORY}/${DB_NAME}_expdp_${DATE}.log     # DO NOT CHANGE THIS LINE - log for export


##### Compression - TAR/ZIP

EXPORT_COMPRESSION="ENABLED"                                         # IF ENABLED dump files will be compressed with OS compression tools
RMAN_COMPRESSION="DISABLED"                                          # IF ENABLED rman backup files will be compressed with OS compression tools


##### Cleanup (Cleanup will run BEFORE new backups!)

EXPORT_RETENTION_STATUS="ENABLED"                                    # IF ENABLED files will be deleted with OS commands according to the retention defined
EXPORT_RETENTION=0                                                   # 0 = DELETE ALL                        - 1 DUMP FILE WILL BE AVAILABLE AT THE END OF THE SCRIPT
                                                                     # 1 = KEEP ONLY LAST DAY'S BACKUP       - 2 DUMP FILES WILL BE AVAILABLE AT THE END OF THE SCRIPT
                                                                     # 2 = KEEP LAST 2 DAY'S BACKUPS         - 3 DUMP FILES WILL BE AVAILABLE AT THE END OF THE SCRIPT
                                                                     # etc. etc.
RMAN_RETENTION_STATUS="DISABLED"                                     # IF ENABLED files will be deleted with OS commands according to the retention defined
                                                                     # RMAN utility retention policy will still be applied if defined within RMAN
RMAN_RETENTION=1                                                     # 0 = DELETE ALL
                                                                     # 1 = KEEP ONLY LAST DAY'S BACKUP
                                                                     # 2 = KEEP LAST 2 DAY'S BACKUPS
                                                                     # etc. etc.



##### DO NOT MODIFY BELOW UNLESS OTHERWISE STATED #####


# START
        echo "Backup Script Start                         : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}

# RMAN BACKUP CLEANUP

if [[ "${RMAN_RETENTION_STATUS}" = "ENABLED" ]]; then
        echo "Rman Backup Cleanup Status                  : ${RMAN_RETENTION_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Cleanup Start                   : $(date)" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Cleanup Apply Retention         : ${RMAN_RETENTION}" >> ${BACKUP_LOG_NAME}
        if [[ ${RMAN_RETENTION} = 0 ]]; then
                rm ${RMAN_BACKUP_DIRECTORY}/*
        echo "Rman Backup Cleanup End                     : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
        elif [[ ${RMAN_RETENTION} > 0 ]]; then
                find ${RMAN_BACKUP_DIRECTORY} -mtime +$((${RMAN_RETENTION}-1)) -exec rm {} \;
        echo "Rman Backup Cleanup End                     : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
        fi
else
        echo "Rman Backup Cleanup Status                  : ${RMAN_RETENTION_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Cleanup Skipped                  : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
fi


# DATA PUMP BACKUP CLEANUP

if [[ "${EXPORT_RETENTION_STATUS}" = "ENABLED" ]]; then
        echo "Data Pump Backup Cleanup Status             : ${EXPORT_RETENTION_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Cleanup Start              : $(date)" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Cleanup Apply Retention    : ${EXPORT_RETENTION}" >> ${BACKUP_LOG_NAME}
        if [[ ${EXPORT_RETENTION} = 0 ]]; then
                rm ${EXPORT_BACKUP_DIRECTORY}/*
        echo "Data Pump Backup Cleanup End                : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
        elif [[ ${EXPORT_RETENTION} > 0 ]]; then
                find ${EXPORT_BACKUP_DIRECTORY} -mtime +$((${EXPORT_RETENTION}-1)) -exec rm {} \;
        echo "Data Pump Backup Cleanup End                : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
        fi
else
        echo "Data Pump Backup Cleanup Status             : ${EXPORT_RETENTION_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Cleanup Skipped            : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
fi


# RMAN BACKUP

if [[ "${RMAN_STATUS}" = "ENABLED" ]]; then
        echo "Rman Backup Status                          : ${RMAN_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Start                           : $(date)" >> ${BACKUP_LOG_NAME}
#
#
#
rman target / log=${RMAN_LOG_NAME} <<EOFRMAN
run {
ALLOCATE CHANNEL CH1 DEVICE TYPE DISK MAXPIECESIZE 31G;
ALLOCATE CHANNEL CH2 DEVICE TYPE DISK MAXPIECESIZE 31G;
ALLOCATE CHANNEL CH3 DEVICE TYPE DISK MAXPIECESIZE 31G;
ALLOCATE CHANNEL CH4 DEVICE TYPE DISK MAXPIECESIZE 31G;
crosscheck archivelog all;
crosscheck backup;
crosscheck copy;
delete noprompt expired archivelog all;
delete noprompt expired backup;
delete noprompt expired copy;
delete noprompt obsolete;
backup as compressed backupset database format '${RMAN_BACKUP_DIRECTORY}/${DB_NAME}_dbfull_%T_%U.rman' tag DBFULL${DATE} plus archivelog format '${RMAN_BACKUP_DIRECTORY}/${DB_NAME}_arc_%T_%U.rmana' tag ARCFULL${DATE} delete all input;
backup spfile format '${RMAN_BACKUP_DIRECTORY}/${DB_NAME}_spfile_%T_%U.rman' tag SPFILE${DATE};
backup current controlfile format '${RMAN_BACKUP_DIRECTORY}/${DB_NAME}_controlfile_%T_%U.rman' tag CFILE${DATE};
delete noprompt backup tag DBFULL${DATE2};
delete noprompt backup tag ARCFULL${DATE2};
delete noprompt backup tag SPFILE${DATE2};
delete noprompt backup tag CFILE${DATE2};
}
exit
EOFRMAN
#
#
#
        echo "Rman Backup End                             : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
else
        echo "Rman Backup Status                          : ${RMAN_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Skipped                         : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
fi


# DATA PUMP BACKUP

if [[ "${EXPORT_STATUS}" = "ENABLED" ]]; then
        echo "Data Pump Backup Status                     : ${EXPORT_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Start                      : $(date)" >> ${BACKUP_LOG_NAME}
#
#
#
expdp "'/ as sysdba'" directory=${EXPORT_DIR} dumpfile=${DB_NAME}_expdp_${DATE}_%U.expdp logfile=${LOG_DIR}:${DB_NAME}_expdp_${DATE}.log parallel=4 full=Y
#
#
#
        echo "Data Pump Backup End                        : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
else
        echo "Data Pump Backup Status                     : ${EXPORT_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Skipped                    : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
fi


# RMAN BACKUP COMPRESSION

if [[ "${RMAN_COMPRESSION}" = "ENABLED" ]]; then
        echo "Rman Backup Compression Status              : ${EXPORT_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Compression Start               : $(date)" >> ${BACKUP_LOG_NAME}
        tar -cvzf ${RMAN_BACKUP_DIRECTORY}/${DB_NAME}_rman_${DATE}.tgz  ${RMAN_BACKUP_DIRECTORY}/*.rman ${RMAN_LOG_NAME}
        rm ${RMAN_BACKUP_DIRECTORY}/*${DATE}*.rman
        echo "Rman Backup Compression End                 : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
else
        echo "Rman Backup Compression Status              : ${EXPORT_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Rman Backup Compression Skipped             : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
fi


# DATA PUMP COMPRESSION

if [[ "${EXPORT_COMPRESSION}" = "ENABLED" ]]; then
        echo "Data Pump Backup Compression Status         : ${EXPORT_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Compression Start          : $(date)" >> ${BACKUP_LOG_NAME}
        tar -cvzf ${EXPORT_BACKUP_DIRECTORY}/${DB_NAME}_expdp_$DATE.tgz  ${EXPORT_BACKUP_DIRECTORY}/*.expdp ${EXPORT_LOG_NAME}
        rm ${EXPORT_BACKUP_DIRECTORY}/*${DATE}*.expdp
        echo "Data Pump Backup Compression End            : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
else
        echo "Data Pump Backup Compression Status         : ${EXPORT_STATUS}" >> ${BACKUP_LOG_NAME}
        echo "Data Pump Backup Compression Skipped        : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
fi


# END
        echo "Backup Script End                           : $(date)" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
        echo "----------------------------------------------------------------------------------------------" >> ${BACKUP_LOG_NAME}
        echo >> ${BACKUP_LOG_NAME}
