# Mac: Known issues

## Obligation::TimeoutError

Migrating permissions fails due to `Obligation::TimeoutError`.

!!! success "Solution"

    The problem seems to be ::1 (localhost) in the `/etc/hosts` file, remove it for now.

## Segmentation fault

Since Ruby 2.6, the following error is occurring for multiple services (e.g. account, course, ...):

```text
[Mnemosyne] Connect to amqp://guest@localhost...
/Users/user/.rvm/rubies/ruby-2.6.xyz/lib/ruby/2.6.0/socket.rb:227: [BUG] Segmentation fault at 0x0000000111625a3a
```

!!! success "Solution"

    This error can be fixed by adding the following environment variable to your `.bashrc` or `.zshrc`:

    ```bash
    export XIKOLO_RABBITMQ_URL="amqp://0.0.0.0"
    ```

    1. Add the environment variable
    2. Restart the terminal
    3. You have to restart RubyMine if you're using RubyMine to start your services

    To check whether the variable is set correctly, execute

    in the shell:

    ```console
    $ echo $XIKOLO_RABBITMQ_URL
    amqp://0.0.0.0
    ```

    If it is empty, try to add it to `.bash_profile` instead and restart your terminal.

    in IRB:

    ```ruby
    puts ENV["XIKOLO_RABBITMQ_URL"]
    => amqp://0.0.0.0
    ```

    If this works but RubyMine still crashes, restart RubyMine.

## Too many open files

Error similar to

```text
Errno::EMFILE: Too many open files
```

when executing commands, such as migrating all databases or starting the services.

!!! success "Solution"

    1. Increase the global limit for maxfiles

        ```console
        sudo launchctl limit maxfiles 64000 524288
        ```

    2. Increase the ulimit, e.g.

        ```console
        ulimit -n 65000
        ```

    You might want to add the new limit to your `.bashrc`, `.bash_profile`, or `.zshrc` depending on your terminal setup.

## Overmind in progress

Error similar to

```text
overmind may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug
```

when trying to run overmind.

!!! success "Solution"

    This error can be fixed by adding the following environment variable to your `.bashrc` or `.zshrc`:

    ```sh
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=yes
    ```

## yarn install prints a warning about an optional dependency

Yarn must succeed successfully in order to build assets. When using a Mac with Apple Silicon without Rosetta, it might print a warning and subsequent commands might fail (even if the warning is not fatal or mentions an _optional_ dependency). In case you experience any issues, use one of the following solutions depending on the warning.

!!! info "Notice"

    If you have *Rosetta* installed, the following solutions **will not work**. `yarn install` will run without errors, but also not be successful. The only solution known at this point is removing Rosetta and follow the steps below.

### mozjpeg

When running `yarn install` you might see a warning similar to

```text
warning Error running install script for optional dependency: "web/node_modules/mozjpeg: Command failed.
```

!!! success "Solution"

    ```console
    sudo ln -s /opt/homebrew/opt/libpng/lib/libpng16.a /usr/local/lib/libpng16.a
    ```

    Remove the `node_modules` filter and reinstall dependencies:

    ```console
    rm -rf node_modules
    yarn install
    ```

### optipng-bin

When running `yarn install` you might see a warning similar to

```text
warning Error running install script for optional dependency: "web/node_modules/optipng-bin: Command failed.
```

!!! success "Solution"

    Remove the `node_modules` folders and reinstall dependencies with a compile flag specified:

    ```console
    rm -rf node_modules
    CPPFLAGS="-DPNG_ARM_NEON_OPT=0" yarn install
    ```
