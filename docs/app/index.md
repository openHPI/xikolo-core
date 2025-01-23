# Home

Welcome to the developer documentation for the Xikolo Platform.

Xikolo as the software system is used to power online learning platforms, including [openHPI](https://open.hpi.de), enabling seamless access to digital education for learners worldwide.
As the backbone for delivering interactive courses, comprehensive assessments, and educational resources, Xikolo is optimized for scalability.

This documentation provides everything you need to get started with Xikolo, whether you're integrating with its APIs, contributing to the platform, or customizing it for specific educational purposes.

## Overview

This documentation comprises the following areas:

- :material-keyboard-outline: [Development](development/index.md) for everything you need to get started and contribute to the codebase - setup tutorials, tips for troubleshooting and coding guidelines.
- :material-star-box-outline: [Features](features/index.md) for an introduction into product domain terminology and concepts.
- :material-package-variant: [Deployment](deployment/index.md) for all configuration and deployment details to use Xikolo in a production environment.

### Teaching team guidelines

While the :material-star-box-outline: [Features](features/index.md) section focuses on specific platform administration topics, this documentation emphasizes technical and implementation aspects.
For guidance on operational topics, such as course administration, please refer to the :material-file-document-multiple-outline: [Teaching team guidelines](https://teachingteamguidelines.readthedocs.io/), made available via Read the Docs [^1].

!!! info
    Please note that these guidelines are currently not actively maintained and may be outdated.

## API documentation

Explore the following APIs and access their documentation through the provided links.

[Portal and Bridge APIs](https://openhpi.stoplight.io/), documented via Stoplight:

- :material-layers-outline: The *Portal API* facilitates integration with external platform portals.
- :material-chat-outline: The *Chatbot API* integrates chatbot systems for enhanced user support.
- :material-format-list-text: The *MOOChub API* provides course information for MOOC aggregators.
- :material-cart-outline: The *Shop API* connects shop systems for selling vouchers.
- :material-subtitles-outline: The *TransPipe API* integrates with [TransPipe](https://github.com/openHPI/transpipe) for subtitle management.

:material-devices: [Xikolo API](https://apidocs.dev.xikolo.de/): Supports integration with mobile apps and is implemented based on `JSON:API`.
  *(Legacy: Limited support for this API may be provided.)*

!!! info
    All APIs are subject to change. Versioning is implemented via the `Accept` header for dedicated APIs.
    Refer to the corresponding documentation for details.

[^1]: The teaching team guidelines can be updated [via GitHub](https://github.com/openHPI/TeachingTeamGuidelines).
