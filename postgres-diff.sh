#!/bin/bash

# Compare a remote database with its local counterpart

if [ $# -ne 1 ]
then
	echo Please give remote server arg
	echo Usage: postgres-diff remote-server-addr
	exit -1
fi	

SERVER=$1
TEMPDB="tempdb-$RANDOM"

REMOTE1="/tmp/r1-$RANDOM"
REMOTE2="/tmp/r2-$RANDOM"
LOCAL="/tmp/loc-$RANDOM"

# 1.- Obtain backup of db structure in production server
echo Geeting schema from remote server
ssh $SERVER pg_dump -s -Ox  > $REMOTE1.sql

#Note: We obtain only the schema (-s) without any permissions and grant sql comands (-Ox).
#2.- Obtain backup of $LOCAL database
echo Geeting schema from local server
pg_dump -s -Ox  > $LOCAL.sql

echo Restoring remote in local
createdb $TEMPDB
psql -f $REMOTE1.sql $TEMPDB > /dev/null

echo Getting diffs, this SQL could be invalid
pg_dump -s -Ox $TEMPDB  > $REMOTE2.sql

#Compare the two schemas, only the lines needed in remote to be like $LOCAL.
#diff $REMOTE2.sql $LOCAL.sql  
#To show the sql needed to patch remote to be like $LOCAL use:

diff $REMOTE2.sql $LOCAL.sql  | grep '^>' | sed 's/^> //'

#The only catch is if there only field differences the sql generated could be invalid, so check it out before proceed.

dropdb $TEMPDB
