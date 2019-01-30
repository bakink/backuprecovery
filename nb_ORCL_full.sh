#!/bin/sh
# $Header$
#
#bcpyrght
#***************************************************************************
#* $Copyright: Copyright (c) 2016 Veritas Technologies LLC. All rights reserved VT25-0977-2658-84-51-3 $ *
#***************************************************************************
#ecpyrght
#
# Note:  Only make modifications to a copy of this file. Changes to this file
#        are lost when this example is overwritten during NetBackup upgrade.
#        Delete this comment from the copy.
#
# -----------------------------------------------------------------------------
#              hot_database_backup.sh
# -----------------------------------------------------------------------------
#  This script uses Recovery Manager to take a hot (inconsistent) database
#  backup. A hot backup is inconsistent because portions of the database are
#  being modified and written to the disk while the backup is progressing.
#  You must run your database in ARCHIVELOG mode to make hot backups. It is
#  assumed that this script will be executed by user root. In order for RMAN
#  to work properly we switch user (su -) to the oracle dba account before
#  execution. If this script runs under a user account that has Oracle dba
#  privilege, it will be executed using this user's account.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Log the start of this script to both the stdout/obk_stdout
# and stderr/obk_stderr.
# -----------------------------------------------------------------------------
echo "==== $0 started on `date` ==== stdout"
echo "==== $0 started on `date` ==== stderr" 1>&2

DEBUG=0

if [ "$DEBUG" -gt 0 ]; then
    set -x
fi

# ---------------------------------------------------------------------------
# Put output in <this file name>.out. Change as desired.
# Note: output directory requires write permission.
# ---------------------------------------------------------------------------
#RMAN_LOG_FILE=${0}.out
RMAN_LOG_FILE=${0%/*}/logs/${0##*/}_$(date +%d%m%Y)_$(date +%H%M%S).out

# -----------------------------------------------------------------------------
# Delete the log file before each execution so that it does not grow unbounded.
# Remove or comment these lines if all historical output must be retained or if
# the log file size is managed externally.
# -----------------------------------------------------------------------------

#if [ -f "$RMAN_LOG_FILE" ]; then
#    rm -f "$RMAN_LOG_FILE"
#fi

# -----------------------------------------------------------------------------
# Initialize the log file. By default it is readable by the DBA and other
# users. Restrict the permissions as needed.
# -----------------------------------------------------------------------------

echo >> $RMAN_LOG_FILE
chmod 644 $RMAN_LOG_FILE

# -----------------------------------------------------------------------------
# Redirect all stderr and stdout into the specified log file and also to
# stdout. No output will appear on stderr (or in the obk_stderr).
# -----------------------------------------------------------------------------

out=/tmp/`basename $0`.stdout.$$
trap "rm -f $out" EXIT SIGHUP SIGINT SIGQUIT SIGTRAP SIGKILL SIGUSR1 SIGUSR2 SIGPIPE SIGTERM SIGSTOP
mkfifo "$out"
tee -a $RMAN_LOG_FILE < "$out" &
exec 1>&- 2>&-
exec 1>"$out" 2>&1

# -----------------------------------------------------------------------------
# Log the start of this script to the log file and stdout.
# Log any additional arguments to the script.
# -----------------------------------------------------------------------------
echo "==== $0 started on `date` ===="
echo "==== $0 $*"
echo

# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
#
# NOTE: User modifications should be made only below this point.
#
# USER CUSTOMIZABLE VARIABLE SECTION
#
# ORACLE_HOME               - Oracle Home path
# ORACLE_SID                - Oracle Sid of the target database
# ORACLE_USER               - Oracle user with permissions to execute RMAN
# ORACLE_TARGET_CONNECT_STR - Connect string for the target database
#                             [user]/[password][@TNSalias]
# RMAN_EXECUTABLE           - Path to the rman executable
# RMAN_SBT_LIBRARY          - SBT library path;
#                             on AIX see technote TECH194511.
# RMAN_CATALOG              - Recovery catalog option and connect string
# BACKUP_SCHEDULE           - If overriding Default-Application-Backup schedule
# BACKUP_TAG                - User specified backup tag

ORACLE_HOME=/oracle/11.2.0/db_4

ORACLE_SID=TAYDER

ORACLE_USER=oracle

ORACLE_TARGET_CONNECT_STR=/

RMAN_EXECUTABLE=$ORACLE_HOME/bin/rman

RMAN_SBT_LIBRARY="/usr/openv/netbackup/bin/libobk.so64"

# Set the Recovery catalog to use. In This example we do not use a
# Recovery Catalog. If you choose to use one, replace the option 'nocatalog'
# with a "'catalog <userid>/<passwd>@<net service name>'" statement.

RMAN_CATALOG="catalog TAYDER/TAYDER@RCATDB"

BACKUP_SCHEDULE=""

# Note: This tag will be appended with the dected schedule type, see schedule
# section.
BACKUP_TAG="hot_db_bk"

export ORACLE_HOME ORACLE_SID

# Note: Additional tuning may be desired to RMAN_SEND and CMD_INPUT below.

# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

# -----------------------------------------------------------------------------
# Determine the user which is executing this script.
# -----------------------------------------------------------------------------

BACKUP_CUSER=`id |cut -d"(" -f2 | cut -d ")" -f1`

# -----------------------------------------------------------------------------
# This script assumes that the database is properly opened. If desired,
# this would be the place to verify that.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# If this script is executed from a NetBackup schedule, NetBackup
# sets NB_ORA environment variables based on the schedule type.
# These variables can then used to dynamically select the appropriate
# RMAN backup type.
# For example, when:
#     schedule type is                BACKUP_TYPE is
#     ----------------                --------------
# Automatic Full                     INCREMENTAL LEVEL=0
# Automatic Differential Incremental INCREMENTAL LEVEL=1
# Automatic Cumulative Incremental   INCREMENTAL LEVEL=1 CUMULATIVE
#
# For client initiated backups, BACKUP_TYPE defaults to incremental
# level 0 (full).  To change the default for a user initiated
# backup to incremental or incremental cumulative, uncomment
# one of the following two lines.
# BACKUP_TYPE="INCREMENTAL LEVEL=1"
# BACKUP_TYPE="INCREMENTAL LEVEL=1 CUMULATIVE"
#
# Note that we use incremental level 0 to specify full backups.
# That is because, although they are identical in content, only
# the incremental level 0 backup can have incremental backups of
# level > 0 applied to it.
# -----------------------------------------------------------------------------

if [ "$NB_ORA_FULL" = "1" ]; then
    echo "Full backup requested from Schedule"
    BACKUP_TYPE="INCREMENTAL LEVEL=0"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl0"

elif [ "$NB_ORA_INCR" = "1" ]; then
    echo "Differential incremental backup requested from Schedule"
    BACKUP_TYPE="INCREMENTAL LEVEL=1"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl1"

elif [ "$NB_ORA_CINC" = "1" ]; then
    echo "Cumulative incremental backup requested from Schedule"
    BACKUP_TYPE="INCREMENTAL LEVEL=1 CUMULATIVE"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl1_cinc"

elif [ "$BACKUP_TYPE" = "" ]; then
    echo "Manual execution - defaulting to Full backup"
    BACKUP_TYPE="INCREMENTAL LEVEL=0"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl0"
fi

echo

# -----------------------------------------------------------------------------
# Construct an RMAN SEND command when initiated from the master server.
# This ensures that the resulting application backup jobs utilize the same
# master server, client name, and policy name.
#
# If desired, initialize RMAN_SEND with additional NB_ORA_* variable=value
# pairs.
#
# NOTE WHEN USING NET SERVICE NAME: When connecting to a database
# using a net service name, you must use a send command or a parms operand to
# specify environment variables.  In other words, when accessing a database
# through a listener, any environment variable set in this script are not
# inherited by the Oracle channel processes because it is a child of the
# listener process and not of this script.  For more information on the
# environment variables, please refer to the NetBackup for Oracle Admin. Guide.
# -----------------------------------------------------------------------------

RMAN_SEND=""

if [ "$NB_ORA_SERV" != "" ]; then
    RMAN_SEND="NB_ORA_SERV=${NB_ORA_SERV}"
fi

if [ "$NB_ORA_CLIENT" != "" ]; then
    if [ "$RMAN_SEND" != "" ]; then
        RMAN_SEND="${RMAN_SEND},NB_ORA_CLIENT=${NB_ORA_CLIENT}"
    else
        RMAN_SEND="NB_ORA_CLIENT=${NB_ORA_CLIENT}"
    fi
fi

if [ "$NB_ORA_POLICY" != "" ]; then
    if [ "$RMAN_SEND" != "" ]; then
        RMAN_SEND="${RMAN_SEND},NB_ORA_POLICY=${NB_ORA_POLICY}"
    else
        RMAN_SEND="NB_ORA_POLICY=${NB_ORA_POLICY}"
    fi
fi

if [ "$BACKUP_SCHEDULE" != "" ]; then
    if [ "$RMAN_SEND" != "" ]; then
        RMAN_SEND="${RMAN_SEND},NB_ORA_SCHED=${BACKUP_SCHEDULE}"
    else
        RMAN_SEND="NB_ORA_SCHED=${BACKUP_SCHEDULE}"
    fi
fi

if [ "$RMAN_SEND" != "" ]; then
    RMAN_SEND="SEND '${RMAN_SEND}';"
fi

# ---------------------------------------------------------------------------
# Call Recovery Manager to initiate the backup.
#
# Note: Any environment variables needed at run time by RMAN
#       must be set and exported within the CMDS variable.
# ---------------------------------------------------------------------------
#  Backs up the whole database.  This backup is part of the incremental
#  strategy (this means it can have incremental backups of levels > 0
#  applied to it).
#
#  We do not need to explicitly request the control file to be included
#  in this backup, as it is automatically included each time file 1 of
#  the system tablespace is backed up (the inference: as it is a whole
#  database backup, file 1 of the system tablespace will be backed up,
#  hence the controlfile will also be included automatically).
#
#  Typically, a level 0 backup would be done at least once a week.
#
#  The scenario assumes:
#     o you are backing your database up to two tape drives
#     o you want each backup set to include a maximum of 5 files
#     o you wish to include offline datafiles, and read-only tablespaces,
#       in the backup
#     o you want the backup to continue if any files are inaccessible.
#     o This script explicitly backs up the control file.  If you specify or
#       default to nocatalog, the controlfile backup that occurs
#       automatically as the result of backing up the system file is
#       not sufficient; it will not contain records for the backup that
#       is currently in progress.
#     o you want to archive the current log, back up all the
#       archive logs using two channels, putting a maximum of 20 logs
#       in a backup set, and deleting them once the backup is complete.
#
#  Note that the format string is constructed to guarantee uniqueness and
#  to enhance NetBackup for Oracle backup and restore performance.
#
# -----------------------------------------------------------------------------

# When needed, commands to debug the environment present in the subshell where
# RMAN will be started.

if [ "$DEBUG" -gt 0 ]; then
    ENV_COMMANDS="
    echo ----- LIST OF DECLARED VARIABLES IN SUBSHELL -----
    echo
    set | sort
    echo
    echo ----- LANGUAGE AND LOCALE -----
    echo
    locale
    echo
    echo ----- PROCESS LIST -----
    echo
    ps -ef
    echo"
else
    ENV_COMMANDS=""
fi

# The RMAN commands to be executed.
# NOTE: If the default shell for the ORACLE_USER is the C shell, then update
# the export syntax as follows:
# setenv ORACLE_HOME "$ORACLE_HOME"
# setenv ORACLE_SID "$ORACLE_SID"

CMDS="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
echo
echo ----- SUBSHELL ENV VARIABLES -----
echo
env | sort | egrep '^ORACLE_|^NB_ORA_|^RMAN_|^BACKUP_|^TNS_'
echo
$ENV_COMMANDS
echo ----- STARTING RMAN EXECUTION -----
echo
$RMAN_EXECUTABLE target $ORACLE_TARGET_CONNECT_STR $RMAN_CATALOG"

# Building the PARMS option for the RMAN channels

if [ $RMAN_SBT_LIBRARY != "" ]; then
    RMAN_SBT_LIBRARY_PARMS="PARMS 'SBT_LIBRARY=$RMAN_SBT_LIBRARY'"
else
    RMAN_SBT_LIBRARY_PARMS=""
fi

# The RMAN statements that are needed to perform the desired backup.
# Add, delete, or modify the CMD_INPUT per the backup requirements for the
# instance.

CMD_INPUT="<< EOF
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE 'SBT_TAPE' TO 'cf_sp_%d_%I_%F';
SHOW ALL;
RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch01 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch02 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch03 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch04 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch05 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch06 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch07 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch08 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch09 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
$RMAN_SEND
BACKUP
    $BACKUP_TYPE
    SKIP INACCESSIBLE
    FILESPERSET 1
    # recommended format, must end with %t
    FORMAT 'bk_%d_%I_%s_%p_%t'
    DATABASE;
    sql 'alter system archive log current';
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
RELEASE CHANNEL ch02;
RELEASE CHANNEL ch03;
RELEASE CHANNEL ch04;
RELEASE CHANNEL ch05;
RELEASE CHANNEL ch06;
RELEASE CHANNEL ch07;
RELEASE CHANNEL ch08;
RELEASE CHANNEL ch09;
# backup all archive logs
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch01 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
$RMAN_SEND
BACKUP
    filesperset 20
    # recommended format, must end with %t
    FORMAT 'al_%d_%I_%s_%p_%t'
    NOT BACKED UP ARCHIVELOG ALL;
    delete force noprompt archivelog until time 'Sysdate-2';
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
#
# Note: During the process of backing up the database, RMAN also backs up the
# control file.  That backup of the control file does not contain the
# information about the archive log backup if "nocatalog" has been specified.
# To include the information about the current backup, the control file should
# be backed up as the last step.  This step may not be necessary if using
# a recovery catalog or AUTOBACKUP CONTROLFILE.
#
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
$RMAN_SEND
BACKUP
    # recommended format, must end with %t
    FORMAT 'cntrl_%d_%I_%s_%p_%t'
    CURRENT CONTROLFILE;
RELEASE CHANNEL ch00;
resync catalog;
}
EOF
"

# -----------------------------------------------------------------------------
# Print out the values of various variables matched by the following patterns.
# -----------------------------------------------------------------------------
if [ "$DEBUG" -gt 0 ]; then
    echo ----- LIST OF DECLARED VARIABLES IN SCRIPT -----
    echo
    set | sort
    echo
fi

echo
echo "----- SCRIPT VARIABLES -----"
echo
set | sort | egrep '^ORACLE_|^NB_ORA_|^RMAN_|^BACKUP_|^TNS_'
echo
echo "----- RMAN CMD -----"
echo
echo "$CMDS"
echo
echo "----- RMAN INPUT -----"
echo
echo "$CMD_INPUT"
echo

# Sanity check the environment.

if [ ! -x $RMAN_EXECUTABLE ]; then
    echo "ERR: $RMAN_EXECUTABLE: required executable not found!" 1>&2
    exit 1
fi

if [ ! -f  `echo $RMAN_SBT_LIBRARY | cut -d'(' -f1`  ]; then
    echo "ERR: $RMAN_SBT_LIBRARY: required library not found!" 1>&2
    exit 1
fi

echo "----- STARTING CMDS EXECUTION -----"
echo

if [ "$BACKUP_CUSER" = "root" ]; then
    su - $ORACLE_USER -c "$CMDS $CMD_INPUT"
    RSTAT=$?
else
    /bin/sh -c "$CMDS $CMD_INPUT"
    RSTAT=$?
fi

# ---------------------------------------------------------------------------
# Log the completion of this script to both stdout/obk_stdout
# and stderr/obk_stderr.
# ---------------------------------------------------------------------------

if [ "$RSTAT" = "0" ]; then
    LOGMSG="ended successfully"
else
    LOGMSG="ended in error"
fi

echo
echo "==== $0 $LOGMSG on `date` ==== stdout"
echo "==== $0 $LOGMSG on `date` ==== stderr" 1>&2
echo

exit $RSTAT
