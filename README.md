# dbash
Robust key-value storage implemented on bash

This will be a database backend for Pak3

## Structure
DBash Database contains key-value pairs. Value can be accessed by key.
Each DB modification must belong to some transaction. A transaction is
a container for accumulating modifications without affecting the global database.
You can commit a transaction, applying its modifications to global database, or
roll it back, safely discarding all modifications.

## Reliability
Bash is not the language in which to develop reliable and robust applications.
That's why I chosen it :). When the database is being accessed, it is first locked,
so no other DBash instance can access it. Then, its contents are read into RAM.
All changes are done within RAM, so if anything goes wrong, the database file WON'T
be left in the invalid state. After all changes have been successfully applied,
the resulting database is written to file. And then - and only then - the database lock
is released. The lock is also released if something goes wrong - immediately before
exiting (without writing database to file), so changes are discarded without affecting
the database.

## Status
In development

Currently implemented features:

### Transactions
- [x] Creating new transaction
- [ ] Committing transaction
- [x] Rolling back transaction
- [ ] Printing transaction list
- [ ] Printing information about transaction

### Data
- [ ] Adding new key-value pair
- [ ] Getting value by key
- [ ] Removing key-value pair
- [ ] Modifying value

### Reliability
- [x] Panic function releases all locks
- [x] Panic function terminates the whole script even in case of subshells
- [ ] ERR trap calls panic
- [ ] Database is being checked before writing
- [ ] Database is being checked after reading
- [x] Transaction IDs are validated
- [ ] Key-value items are hash-verified

## License
DBash is distributed under conditions of GNU GPL license version 3 or later.
See LICENSE file for complete license text
