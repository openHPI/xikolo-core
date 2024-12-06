# Update PostgreSQL

## MacOS

Assumption: The latest version postgresql@16 is running, specifically PostgreSQL 16.4.
If that is not the case, you need to adjust some commands below.

```shell
brew install postgresql@17
brew services stop postgresql@16
$(brew --prefix)/Cellar/postgresql@17/17.0/bin/pg_upgrade -b $(brew --prefix)/Cellar/postgresql@16/16.4/bin -d $(brew --prefix)/var/postgresql@16 -D $(brew --prefix)/var/postgresql@17 --link
brew link postgresql@17
vacuumdb --all --analyze-in-stages  --jobs $(nproc)
gem pristine pg
brew services run postgresql@17

# Important: Before you continue, check everything is fine
# by performing some database action.
# You can simply check whether PostgreSQL starts correctly and data could be read.

# Now the old cluster will be permanently deleted,
# potentially causing data loss if the upgrade didn't went smooth.
./delete_old_cluster.sh
rm -rf ./delete_old_cluster.sh
brew remove --zap postgresql@16
```

It will keep local databases, so you are not expected to have any service disruption.
