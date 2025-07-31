# Application configuration

Typically, the `xikolo.yml` is the most relevant file for configuring the application. Each service has its own `xikolo.yml`, located in `[service]/app/xikolo.yml`.
To configure your local app for **development**, there are two different ways:

If, for example, you would like to adapt the footer for development for all devs, the changes go into `web/app/xikolo.yml` (version-controlled).

But if you want to change the footer only on your machine, the changes go into `~/.xikolo.development.yml` or `config/xikolo.development.yml` (not version-controlled).

For configuring the **production** application, see [the respective part in the deployment documentation](../../deployment/internal/configuration/index.md/#application-configuration).
