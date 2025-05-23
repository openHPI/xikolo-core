# Operating a platform (Open Source)

This documentation outlines the fundamental requirements and steps to operate the Xikolo platform.
The Xikolo platform is modular and based on the following open-source repositories:

- [xikolo-core](https://github.com/openHPI/xikolo-core): core application with (micro)service-based domain applications.
- [xikolo-learnanalytics](https://github.com/openHPI/xikolo-learnanalytics): reporting and learning analytics capabilities.

The following information provides an overview to help evaluate whether the platform is suitable for your operational needs.

## Services

The platform consists of several services working together to provide its functionality.
These are divided into necessary and optional services:

### Necessary services

| Service                            | Function                                                                           |
|------------------------------------|------------------------------------------------------------------------------------|
| **account-api**                    | Enables user login and management.                                                 |
| **account-sidekiq**                | Background job processing with Sidekiq for the account service.                    |
| **course-api**                     | Lists all courses and allows managing them.                                        |
| **course-msgr**                    | Asynchronous messaging service for the course service.                             |
| **course-sidekiq**                 | Background job processing with Sidekiq for the course service.                     |
| **grouping-api**                   | Manages user groups (e.g., for A/B tests).                                         |
| **grouping-sidekiq**               | Background job processing with Sidekiq for the grouping service.                   |
| **lanalytics-api**                 | Provides detailed platform reports and statistics.                                 |
| **lanalytics-msgr**                | Asynchronous messaging service for the lanalytics service.                         |
| **lanalytics-sidekiq**             | Background job processing with Sidekiq for the lanalytics service.                 |
| **news-api**                       | Provides course and platform announcements.                                        |
| **news-msgr**                      | Asynchronous messaging service for the news service.                               |
| **news-sidekiq**                   | Background job processing with Sidekiq for the news service.                       |
| **notification-api**               | Sends all kind of emails to users.                                                 |
| **notification-msgr**              | Asynchronous messaging service for the notification service.                       |
| **notification-sidekiq**           | Background job processing with Sidekiq for the notification service.               |
| **web-api**                        | User interface and main domain application.                                        |
| **web-msgr**                       | Asynchronous messaging service for the web service.                                |
| **web-sidekiq**                    | Background job processing with Sidekiq for the web service.                        |
| **web-delayed**                    | Background job processing with Delayed for the web service.                        |
| ... (more application services)    | Service functionality provided for pinboard, quiz, and timeeffort. |
| **elasticsearch-master**           | Search engine and event store for lanalytics.                                      |
| **postgres-lanalytics**            | Database for the lanalytics service.                                               |
| **postgres-web**                   | Database for the core services.                                                    |
| **rabbitmq**                       | Asynchronous messaging.                                                            |
| **redis-cache**                    | Application caching.                                                               |
| **redis-sidekiq**                  | Background job processing with Sidekiq.                                            |
| **S3**                             | Storage backend for files.                                                         |
| ... (more infrastructure services) | ...                                                                                |

### Optional services

| Service                                                                   | Function                                            |
|---------------------------------------------------------------------------|-----------------------------------------------------|
| **etherpad-service**                                                      | Supports collaborative writing with Etherpad.       |
| **[h5p-lti-1p0-provider](https://github.com/kiron/h5p-lti-1p0-provider)** | Provides interactive exercises using H5P (via LTI). |
| **mongo**                                                                 | Database for H5P.                                   |
| **zammad-websocket**                                                      | Offers helpdesk functionality with Zammad.          |
| ...                                                                       | ...                                                 |

## Infrastructure

The platform can be operated using the provided `Dockerfile`s with common container technologies (e.g., using Nomad for orchestration).
An example setup for a platform, which is currently in production, uses the following resources.

!!! note
    Based on the actual platform traffic and size, fewer resources may be sufficient.

### Application resources

| Component                           | Count | Resources         |
|-------------------------------------| ----- | ----------------- |
| **Background jobs**                 | 2     | 4 vCPUs, 8 GB RAM |
| **Services (account, course, ...)** | 3     | 4 vCPUs, 8 GB RAM |
| **Web**                             | 3     | 4 vCPUs, 8 GB RAM |
| **Tasks (optional management VM)**  | 1     | 2 vCPUs, 4 GB RAM |

### Infrastructure resources

| Component               | Count | Resources               |
| ----------------------- | ----- | ----------------------- |
| **Consul**              | 3     | 2 vCPUs, 2 GB RAM       |
| **eLB (external LB)**   | 2     | 2 vCPUs, 2 GB RAM       |
| **iLB (internal LB)**   | 2     | 2 vCPUs, 2 GB RAM       |
| **RabbitMQ**            | 3     | 2 vCPUs, 2 GB RAM       |
| **Redis**               | 1     | 4 vCPUs, 8 GB RAM, Disk |
| **Postgres**            | 3     | 4 vCPUs, 8 GB RAM, Disk |
| **Lanalytics Postgres** | 1     | 4 vCPUs, 8 GB RAM, Disk |
| **Elasticsearch**       | 1     | 4 vCPUs, 8 GB RAM, Disk |

### Sample setup

The table below presents a sample setup for running the platform, offering a basis for resource planning and estimation.

| Category                               | Quantity | Unit       |
|----------------------------------------|----------|------------|
| ECS (Elastic Cloud Server)             | 12       | Units      |
| CPU                                    | 24       | Cores      |
| RAM                                    | 192      | GB         |
| Storage (High IO SAS)                  | 1200     | GB         |
| ECS - Backup Space                     | 500      | GB         |
| RDS HA - PostgreSQL (2 CPU, 16 GB RAM) | 2        | Instances  |
| RDS - Storage (Ultra High IO SSD)      | 100      | GB         |
| RDS - Backup Space                     | 1000     | GB         |
| ELB (Elastic Load Balancer) - Shared   | 1        | Unit       |
| Elastic IP (Public Internet Access)    | 1        | Unit       |
| Elastic Outgoing Traffic               | 100      | GB / month |

### Redundancy and distribution

To ensure stable operation, it is advisable to run services redundantly and distribute them across multiple availability zones.
This approach offers the following benefits:

- **Fault tolerance**: Services remain available in other zones if one zone fails.
- **Load distribution**: Redundancy ensures an even distribution of requests, optimizing performance.
- **Higher availability**: Redundant setups guarantee continuous access to the platform, even during maintenance or unexpected outages.

Infrastructure components (e.g., databases, RabbitMQ, Consul) should also be configured redundantly to ensure critical data and functionalities remain accessible.
A distribution across at least two to three availability zones is recommended.

## Prerequisites for operation

To successfully operate the platform, the following points should be considered:

1. **Hardware resources**: The instance types and specifications outlined above should be provisioned.
2. **Services**: Installation and configuration of Nomad, Consul, and other supporting infrastructure services, such as an email server.
3. **Configuration**: A valid application configuration is required (i.e., through the `xikolo.yml` file for the application).
   This also applies to supporting services like S3. Example configurations are available in the `/docker` directory.

    !!! tip

        Some application features and functionality as well as user permissions are managed via the database, e.g. via feature flippers.
        Knowledge of Ruby / Ruby on Rails is required.

4. **Backup & maintenance**: Regular backups of databases and stored files, as well as updates for the infrastructure services.

    !!! success

        Additionally, regular updates of the source code are required, including rebasing on the latest application code made available in the repositories mentioned above.

5. **Monitoring**: Effective monitoring is critical to ensure the platform's reliability and performance.

    !!! info

        The following (optional) services may be integrated for comprehensive monitoring.

        - **[Mnemosyne](https://github.com/mnemosyne-mon)**: Provides distributed tracing and performance analysis for applications.
        - **Grafana**: Delivers visualizations and dashboards for monitoring system and application metrics.
        - **InfluxDB**: Serves as a time-series database for storing performance metrics.
        - **Telegraf**: Acts as a metrics collection agent for system and application monitoring.
        - **Sentry**: Tracks and reports application errors, offering insights for debugging and stability.

        Ensure that these tools are configured properly and routinely monitored to detect and address potential issues proactively.

## Advantages of the platform

- **Modular design**: Services can be enabled or disabled as needed, allowing for tailored configurations to suit specific requirements.
- **Open source**: The platform's source code is openly available, enabling customizations and enhancements while adhering to the AGPLv3 license terms.
- **Scalable architecture**: The platform is designed to handle varying workloads efficiently, making it suitable for small-scale deployments as well as large-scale, high-traffic applications.
   Resources can be adjusted dynamically to match the demands of your operations.

## Further information

Detailed installation and configuration instructions can be also found in the `README` files of the repositories:

- [xikolo-core](https://github.com/openHPI/xikolo-core)
- [xikolo-learnanalytics](https://github.com/openHPI/xikolo-learnanalytics)
