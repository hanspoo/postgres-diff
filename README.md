## Economic postgresql diff

Normal development flow requires continuous patching the database with local changes, normally made automatically by the orm software, all of them are more complex than this solution that just use standard Unix commands, and is good enough for us.

You will not seet database name or user name because we'll use the convention to use an operating system account owning the database in local and production and the databases are named as the user, all this with automatic ssh login in remote. 

### Rationale

The first aproach is to compare schemas, suppose you have your local dev version in localhost and the production version in other server called remote-server.

### 1.- Obtain backup of db structure in production server
```
ssh remote-server pg_dump -s -Ox  > remote1.sql
```

Note: We obtain only the schema (-s) without any permissions and grant sql comands (-Ox).
### 2.- Obtain backup of local database
```
pg_dump -s -Ox  > local.sql
```
### 3.- Compare the two schemas

This command compare the two files and filter the lines needed in remote to be like local using standard unix filters grep and sed .

```
diff remote2.sql local.sql  | grep '^>' | sed 's/^> //'  
```

### Difference in database versions

If the Postgres versions are different, chances are that will be a lot of differences not essential in nature, but in syntax, i.e, schema prefix usages.

To be bullet proof we’ll make this comparison using same version of postgres: you should reload the remote database locally.

```
createdb temp1
psql -f remote1.sql temp1
pg_dump -s -Ox temp1  > remote2.sql
```

### Compare again schemas same server version

```
diff remote2.sql local.sql  
```

Again to show the sql needed to patch remote to be like local use:
```
diff remote2.sql local.sql  | grep '^>' | sed 's/^> //'
```

The only catch is if there are only field differences the sql generated could be invalid, so check it out before proceed.

### Finally, this script makes all:

```
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

```



