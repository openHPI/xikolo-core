# Bridge APIs

The bridge API pattern is a design approach used to create an abstraction layer between different systems or services.
It enables interoperability by exposing a structured interface that third parties can use to interact with a system without needing direct access to its internal implementation.
This pattern is particularly useful for:

- **Decoupling components**: Allowing independent evolution of internal services and external integrations.
- **Standardized access**: Providing a well-defined contract for third-party applications.
- **Security and control**: Restricting access to specific functionalities while maintaining data integrity.
- **Scalability**: Simplifying the extension of functionalities without modifying core systems.

This principle therefore ensures seamless communication between internal and external systems.

## Development guidelines

The Bridge APIs are developed to provide access to a specific feature or set of features to a third party.
Developing a new bridge API includes mostly of the following tasks: documentation, development, and testing.

### Documentation

The documentation for our APIs follow the [OpenAPI 3.0 specification](https://swagger.io/specification/).
It defines the API contract and serves as a reference for third parties consuming the API.
The API documentation can be found in the [API documentation](../../index.md).

To publish new documentation, place the API documentation in `docs/bridges/project_name/reference/project_name.yml`.
The Stoplight editor should be used to create a valid and complete documentation.

### Development

Routes for actions within controllers should be defined under the `bridges/project_name` scope in the `routes.rb`.

!!! example

    ``` ruby
    scope 'bridges', module: :bridges, as: 'bridges' do
      scope 'project_name', module: :project_name, as: 'project_name' do
        # include your project routes here
      end
    end
    ```

The Bridge API controllers should be placed in `app/controllers/bridges/project_name`.

!!! tip

      Take the existing bridge APIs as an example for best practices regarding authorization and configuration.
      For example, the common `Abstract::BridgeAPIController` and `Xi::Controllers::RequireBearerToken` classes should be used for consistency.

A good practice is to create a base controller that inherits from `Abstract::BridgeAPIController`, created for applications that don't require all functionalities that a complete Rails controller provides - just the ones needed for API-only applications.

!!! example

    ``` ruby
    # frozen_string_literal: true

    module Bridges
      module ProjectName
        class BaseController < Abstract::BridgeAPIController
          # Your code goes here.
        end
      end
    end
    ```

!!! warning

    Since bridge APIs are used by external systems, versioning is an important topic to be considered and poses some additional requirememts, e.g. backward-compatibility of changes.

### Testing

Request specs are recommended to test the API interface.
Those tests should be placed in `spec/requests/bridges/project_name`.
Create one folder for each controller, and one file for each of the controller actions.
On each of those test files, we recommend that the API should be tested for all the edge cases for that given action (e.g., including missing parameters and authentication).
