[oracle@owkkdb03 CARDLIVE]$ cat  CARDLIVE_full.sh   
#!/bin/ksh
# we have 4 shares, 2 shares per controller and will open 2 channels per share`
# we have 3 instances
# Instance 1 will backup to controler B (opczfs02) 192.168.40.212 and 14
# Instance 2 will backup to controler A (opczfs01) 192.168.40.211 and 13
# Instance 3 will backup to controler B (opczfs02) 192.168.40.212 and 14
# Instance 4 will backup to controler A (opczfs02) 192.168.40.211 and 13
# 192.168.20.211:/export/OWCR/backup1 /zfssa/OWCR/backup1
# 192.168.20.212:/export/OWCR/backup2 /zfssa/OWCR/backup2
# 192.168.20.213:/export/OWCR/backup3 /zfssa/OWCR/backup3
# 192.168.20.214:/export/OWCR/backup4 /zfssa/OWCR/backup4

#export ORACLE_SID=CARDLIVE3
#export DB_HOME='/u01/app/oracle/product/11.2.0.4/dbhome_1'
#export ORACLE_HOME=${DB_HOME}
#export BASE_PATH=/usr/local/bin:/bin:/usr/bin
#export PATH=${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch:${BASE_PATH}

. ~/.CARD11204.env

echo
echo ORACLE_SID : $ORACLE_SID
echo ORACLE_HOME: $ORACLE_HOME
echo PATH       : $PATH
echo

date

hostname

#rman target rmanzfs/rmanzfs123@CARDLIVEbk3 catalog CARD11204/card_zfs1204@CATMAN log='/home/oracle/zfsscripts/logs/CARDLIVE_full2ZF0S.log' <<EOF
rman target / catalog CARD11204/card_zfs1204@CATMAN log='/home/oracle/zfsscripts/logs/CARDLIVE_full2ZF0S.log' <<EOF
run
{
allocate channel ch001 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk1' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch002 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk2' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch003 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk3' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch004 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk4' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch005 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk1' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch006 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk2' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch007 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk3' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch008 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk4' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch009 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk1' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch010 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk2' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch011 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk3' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch012 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk4' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch013 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk1' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch014 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk2' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch015 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk3' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
allocate channel ch016 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk4' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
backup as backupset incremental level 0 section size 32g database tag 'ZFSCARDLIVE_FULL_L0';
delete noprompt force backup completed before 'sysdate-5';
}
EOF
date
/bin/cp /home/oracle/zfsscripts/logs/CARDLIVE_full2ZF0S.log /home/oracle/zfsscripts/logs/CARDLIVE_full2ZF0S_$(date +%Y%m%d_%H_%M_%S).log
/bin/mailx -s "BACKUP_BILGILENDIRME_MAIL - CARDLIVE DB FULL Backup" VeriDepolamaveYedeklemeSistemleriYonetimi@yapikredi.com.tr < /home/oracle/zfsscripts/logs/CARDLIVE_full2ZF0S_$(date +%Y%m%d_%H_%M_%S).log
grep -e  RMAN- -e  ORA- /home/oracle/zfsscripts/logs/CARDLIVE_full2ZF0S.log
if [ $? -eq 0 ]; then
exit 3
fi


-----------------------------------------



[oracle@owkkdb03 CARDLIVE]$ cat  CARDLIVE_archivelog.sh
#export ORACLE_SID=CARDLIVE3
#export DB_HOME='/u01/app/oracle/product/11.2.0.4/dbhome_1'
#export ORACLE_HOME=${DB_HOME}
#export BASE_PATH=/usr/local/bin:/bin:/usr/bin
#export PATH=${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch:${BASE_PATH}


. ~/.CARD11204.env

echo
echo ORACLE_SID : $ORACLE_SID
echo ORACLE_HOME: $ORACLE_HOME
echo PATH       : $PATH
echo

date

rman target rmanzfs/rmanzfs123@CARDLIVEbk3 catalog CARD11204/card_zfs1204@CATMAN log='/home/oracle/zfsscripts/logs/CARDLIVE_ARCH2ZF0S.log' <<EOF
run
{
allocate channel ch001 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk1' format '/zfssa/OWKK/backup1/CARDLIVE/%U';
allocate channel ch003 device type disk connect 'rmanzfs/rmanzfs123@OWKK_CARDLIVEbk3' format '/zfssa/OWKK/backup2/CARDLIVE/%U';
#BACKUP ARCHIVELOG ALL
#filesperset 4
#DELETE ALL INPUT;
#Delete noprompt  BACKUP OF ARCHIVELOG all COMPLETED before 'sysdate-2';
###backup archivelog like '+RECO_OWA%'  filesperset 4 delete all input;

BACKUP
   filesperset 1
   ARCHIVELOG like '+RECO_OWA%' not backed up 1 times ;  

delete noprompt archivelog like '+RECO_OWA%'  backed up 1 times to 'DISK' completed before 'sysdate-6/24';

#Delete noprompt  BACKUP OF ARCHIVELOG like  '+RECO_OWA%' COMPLETED before 'sysdate-2'  ;
Delete noprompt  BACKUP OF ARCHIVELOG all COMPLETED before 'sysdate-7';
}
EOF

date

/bin/cp /home/oracle/zfsscripts/logs/CARDLIVE_ARCH2ZF0S.log  /home/oracle/zfsscripts/logs/CARDLIVE_ARC2ZF0S_$(date +%Y%m%d_%H_%M_%S).log

#/usr/bin/mutt -s "BACKUP_BILGILENDIRME_MAIL CARDLIVE Archivelog Backup" BTIsletimPlanlamaveDestek@yapikredi.com.tr,VeriDepolamaveYedeklemeSistemleriYonetimi@yapikredi.com.tr, TemelBankacilikBTOperasyon@yapikredi.com.tr  < /home/oracle/AV/CARDLIVE/CARDLIVE_ARCH2ZF0S.log


[oracle@owkkdb03 CARDLIVE]$ 
