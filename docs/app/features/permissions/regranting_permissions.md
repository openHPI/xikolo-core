# Regranting permissions

When modifying or dropping permissions, roles, or groups _for course special groups_ (see
[custom regranting](#custom-regranting)), the regrant script must be run, mainly because otherwise already
existing grants that should actually be modified or deleted will remain in place. The script generates a sequence of SQL
commands that

- (1) dump all grants in xi-account and
- (2) ensure that all necessary roles are created and their grants are re-created.

## Regrant script

1. Copy the regranting script from [web/services/course/db/regrant.rb](https://gitlab.hpi.de/openhpi/xikolo/web/-/blob/main/services/course/db/regrant.rb) to your clip-board

2. Using Nomads web UI, connect to `xi-course`:
    - <https://nomad.adm.production.openhpi.xi.xopic.de/ui/exec/xikolo/course-api/server?namespace=default>
    - Don't forget to press Enter here!

3. Create a temporary script:

    ```shell title="xi-course:/app$"
    cat > tmp/regrant.rb
    ```

    - Paste the script's content from your clip-board
    - Press CTRL-D

4. Create the regranting SQL code:

    ```shell title="xi-course:/app$"
    rails r tmp/regrant.rb > tmp/regrant.sql
    ```

5. Copy the SQL script to your local machine:
    - You can directly pipe it to your clipboard (Linux: `cat tmp/regrant.sql | xclip`) or print and then manually select and copy it:

    ```shell title="xi-course:/app$"
    cat tmp/regrant.sql
    ```

6. Remove the safety belt (the `ROLLBACK;` in the last line of the SQL script):

    ```shell title="localhost:~#"
    sed -i '$ d' [path-to-file]/regrant.sql # Linux
    sed -i '' -e '$ d' [path-to-file]/regrant.sql # Mac
    ```

7. Copy the SQL script to the database server:

    ```shell title="localhost:~#"
    scp [path-to-file]/regrant.sql root@db.production.openhpi.xi.xopic.de:/tmp
    ```

8. Login to the `db` VM:

    ```shell title="localhost:~#"
    ssh root@db.production.openhpi.xi.xopic.de
    ```

9. Execute the SQL script in the database:

    ```shell title="db:~#"
    sudo -u postgres psql web
    ```

10. Load the script in the psql console:

    ```shell title="web=#"
    \i /tmp/regrant.sql
    ```

11. If the script runs without errors, apply the changes:

    ```shell title="web=#"
    COMMIT;
    ```

12. Delete the regrant script from the database VM.

13. You're done (or can continue with the next instance if applicable).

14. Don't forget to remove the regrant script(s) from your local machine and `xi-course` as soon as you're done completely.

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
