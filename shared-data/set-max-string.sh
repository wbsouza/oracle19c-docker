#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Syntax:"
  echo "   $0 <sys_password>"
  exit 1
fi


ORIGINAL_DIR=$(pwd)
ORACLE_PWD=$1

echo ""
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo ">>> Altering the parameter MAX_STRING_SIZE and restarting in UPGRADE mode ..."
sqlplus / as sysdba << EOF
    ALTER SESSION SET CONTAINER=CDB\$ROOT;
    ALTER SYSTEM SET max_string_size=extended SCOPE=SPFILE;
    SHUTDOWN IMMEDIATE;
    STARTUP UPGRADE;
    quit
EOF


echo ""
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo ">>> Applying the patch to allow long strings (UPGRADE mode) ..."
cd $ORACLE_HOME/rdbms/admin
echo $ORACLE_PWD | $ORACLE_HOME/perl/bin/perl ./catcon.pl -u SYS --force_pdb_mode 'UPGRADE' -d ./ -b utl32k_cdb_pdbs_output utl32k.sql


echo ""
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo ">>> Restarting the database in NORMAL mode ..."
sqlplus / as sysdba << EOF
    SHUTDOWN IMMEDIATE;
    STARTUP;
    quit
EOF

echo ""
echo "---------------------------------------------------------------------------------------------------------------------------------"
echo ">>> Applying the patch in (NORMAL mode) ..." 
cd $ORACLE_HOME/rdbms/admin
echo $ORACLE_PWD | $ORACLE_HOME/perl/bin/perl ./catcon.pl -u SYS --force_pdb_mode 'READ WRITE' -d ./ -b utlrp_cdb_pdbs_output utlrp.sql

echo ""
echo ">>> Finished !"

cd $ORIGINAL_DIR


