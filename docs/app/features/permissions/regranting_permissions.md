# Regranting permissions

When modifying or dropping permissions, roles, or groups _for course special groups_ (see
[custom regranting](#custom-regranting)), the regrant script must be run, mainly because otherwise already
existing grants that should actually be modified or deleted will remain in place. The script generates a sequence of SQL
commands that

- (1) dump all grants in xi-account and
- (2) ensure that all necessary roles are created and their grants are re-created.

The regrant script is part of `xi-course` and can be found at `db/regrant.rb`.

## Regrant script

1. Login to a `tasks` VM:

   ```shell title="localhost:~#"
   ssh root@tasks.production.[brand].xi.xopic.de
   ```

2. Create the regranting SQL code:

   ```shell title="tasks:~#"
   xikolo-course rails r /usr/lib/xikolo-course/db/regrant.rb > ~/regrant.sql
   ```

3. Copy the SQL script to your local machine:

   ```shell title="localhost:~%"
   scp root@tasks.production.[brand].xi.xopic.de:~/regrant.sql .
   ```

4. Remove the safety belt (the `ROLLBACK;` in the last line of the SQL script):

   ```shell
   sed -i '$ d' ~/regrant.sql # Linux
   sed -i '' -e '$ d' ~/regrant.sql # Mac
   ```

5. Copy the SQL script to the database server:

   ```shell title="localhost:~#"
   scp regrant.sql root@db.production.[brand].xi.xopic.de:/tmp
   ```

6. Login to the `db` VM:

   ```shell title="localhost:~#"
   ssh root@db.production.[brand].xi.xopic.de
   ```

7. Execute the SQL script in the `xi-account` database:

   ```shell title="db:~#"
   sudo -u postgres psql web
   ```

8. Load the script in the psql console:

   ```shell title="web=#"
   \i /tmp/regrant.sql
   ```

9. If the script runs without errors, apply the changes:

   ```shell title="account=#"
   COMMIT;
   ```

10. Delete the regrant script from the database VM.
11. You're done (or can continue with the next instance if applicable).
12. Don't forget to remove the regrant script(s) from your local machine as soon as you're done completely.

!!! note

    If you need to regrant all platform instances, keep in mind that you need to execute the steps 1 - 4 only once for
    all instances without overwrites for permissions for the `course_special_groups` in the `xikolo.yml`. You can reuse
    the regrant SQL script generated for the first instance. Instances with overwritten permissions need their own
    regrant SQL script.

## Custom regranting

If you modify global permission groups, you might need to also modify the existing grants manually on console. In
particular, if you remove grants for roles from a group, these grants have to be deleted by hand after deployment.

For example, when extracting the roles for handling personal information from the existing `xikolo.admins` group to the
new, dedicated `xikolo.gdpr_admins`, the new group including its granted permissions were created with the
`permissions:load` rake task on deployment. The corresponding grants still had to be removed from the admin group (partial "regrant").

```ruby title="Remove all grants for xikolo.gdpr_admins from xikolo.admins"
Group.find_by(name: 'xikolo.admins')
  .grants
  .where(
    role: Group.find_by(name: 'xikolo.gdpr_admins').grants.map {|g| g.role }
  ).destroy_all
```

There are further use cases where manual regranting must be applied, e.g. when completely dropping a global
permission group.

!!! note

    You don't need to apply any custom regranting for global permission groups if your changes are purely additive,
    e.g. adding a new group or adding permissions to existing groups.
