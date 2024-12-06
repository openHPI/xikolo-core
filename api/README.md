# Xikolo API

The Xikolo API serves as the primary data access point for the mobile apps.
As such, it fetches data from the backend services, according to the requests made and the user's permissions.
The data is then decorated and transformed to a special JSON representation.
In addition, the API allows for writing certain data (such as user events, enrollments and quiz submissions) back to the services.

## Serialization / JSON-API

The API conforms to the [JSON-API standard](http://jsonapi.org/), a generic solution for certain problems that APIs face.

From the specification:

> JSON API is a specification for how a client should request that resources be fetched or modified, and how a server should respond to those requests.
> JSON API is designed to minimize both the number of requests and the amount of data transmitted between clients and servers.
> This efficiency is achieved without compromising readability, flexibility, or discoverability.

Among other things, JSON-API describes how to

- serialize resources and links,
- describe relationships, and
- embed (sideload) related resources.

## REST

REST (short for _Representational State Transfer_) describes the architectural style of the web.
Because the HTTP protocol and the web's infrastructure are designed with REST in mind, this API tries to conform as much as possible to the ideas and constraints laid out in Roy Fielding's thesis, where he introduced REST.

Central aspects of REST are _resources_, _representations_ and the _uniform interface_, which will be described shortly in the following:

- **Resource:** Every concept of a RESTful web app that has meaning to the user is exposed as a resource.
  This can be anything, such as a course, the current time, or the state of an order, that can be identified by an URI.
  Most importantly, these resources are always nouns.
  In contrast to ideas like _Remote Procedure Call_ (RPC), in REST land, clients do not call "functions" on the server (such as `/save-this-post?id=123`).
  Instead, clients manipulate resources through a narrow set of possible interactions with well-defined meanings (the HTTP methods).
- **Representation:** To hide the concrete implementation of a resource on the server, clients only deal with their representations.
  On classic webpages, this is typically a HTML representation for humans to consume (i.e. mapping a list of blog posts to a number of rows in a table).
  In the API, these representations are JSON objects with a number of attributes.
  The JSON-API specification defines some further rules for how relationships, meta information and embedded resources should be nested.
  Write requests (such as PUT or POST) include representations of new (or updated) resources.
- **Uniform interface:** The HTTP protocol specifies certain semantics that allow all actors (client, server, intermediaries) to understand messages without further information about the context from which they were sent.
- **Hypermedia:** Just like web pages targeting humans, RESTful APIs should be discoverable through links.
  Therefore, representations should contain the URLs of related resources.
  This makes it possible for API clients to start out at (optimally) one root endpoint, and navigate the entire API using hyperlinks.
  This alleviates the need to e.g. construct URLs on the client side (which also allows changing those without breaking clients).

## Architecture

The API's design was guided by the idea to make the implementation of RESTful endpoints (resources) as simple as possible, all the while keeping the central concepts of REST in mind.
The central element of its architecture is therefore that of an _endpoint_.

Each endpoint describes:

- the structure (and meaning) of its representation, including links and relationships,
- the meaning of all fields, from which we automatically generate documentation,
- whether (and how) attributes can be written (e.g. by POST or PATCH requests),
- how to load and store (single or multiple) resources,
- which HTTP methods are supported,
- authorization requirements, and
- possible filters, their meanings as well as their mapping to parameters in service calls.

These different aspects are implemented in a declarative manner, therefore taking the burden of things like JSON-API (de)serialization, relationships (including embedding them) etc. off the shoulders of the developer.

## Implementing Endpoints

We differentiate between _collection_ and _member_ resources.
The former represent groups of things, e.g. the list of courses or all pinboard threads by a certain author.
A member resource is a single thing, such as an article or a subscription to a pinboard thread.

To implement a new endpoint, create a class extending from `Xikolo::Endpoint::CollectionEndpoint`:

```rb
class Users < Xikolo::Endpoint::CollectionEndpoint

  entity do
    type 'users'

    # Describe attributes, relationships and links
  end

  filters do
    # Declare supported filters for this endpoint
  end

  collection do
    # Implement service calls for requests to the collection endpoint (/users)
  end

  member do
    # Implement service calls for requests to the member endpoint (/users/123)
  end

end
```

### Loading or storing data

...

### Defining supported endpoints

Member, collection, filters

### Defining the representation

The `representation` block describes which attributes, relationships and links should make up the resource's representation.
It also defines any renaming or transformation operations that should be executed on objects to convert them to or from a representation that is understood by the corresponding backend service.

#### Attributes

Attributes can be defined like this:

```rb
attribute('name') {
  description 'The user\'s full name'
  alias_for 'full_name'
  reading { |user| "#{user['first_name']} #{user['last_name']}" }
}
```

The `description` method receives a string containing a short text about the meaning of the attribute, for use in the automatically generated API documentation.

The optional `alias_for` method can supply the name of the attribute in the corresponding service's representation, if that differs from the name that should be used when serializing the JSON-API response.
It is also used in the opposite direction: in the above example, the `name` in a PATCH request to a user's endpoint would be passed to the service in the `full_name` attribute.

There are several options to further transform the data returned by a service to the representation in the JSON-API response (and vice-versa).
Because these transformations are often not automatically reversible, they typically have to be implemented both for reading and writing a resource (if writing is allowed for the attribute).

The block passed to `reading` receives the resource as represented by the backend service, and should return a value that will be used in the JSON-API representation.
The `writing` method receives the attribute value as sent to the JSON-API.
It can return...

- either a hash that will be merged into the hash that is sent to the service,
- or any other value that will be added to the hash with the attribute's name (or defined alias) as key.

There is also a shortcut for the rather common `map` operation.
This method receives a hash that can be used for mapping values from the service to values in the JSON-API representation.
If the given map is reversible (i.e. they are no duplicate values), it will also be used for writing (if allowed).

```rb
map(
  'Xikolo::Quiz::MultipleAnswerQuestion' => 'multiple_answer',
  'Xikolo::Quiz::MultipleChoiceQuestion' => 'multiple_choice',
  'Xikolo::Quiz::FreeTextQuestion' => 'free_text'
)
```

Note that this can not use Ruby's `{}` syntax for hashes, as this would be interpreted as a block instead.

##### Making attributes writable

The API also supports write requests (POST to a collection or PATCH to a singular resource).
Attributes have to be explicitly declared as writable.
This is done so that no attributes can be writable by accident.

To mark an attribute as writable, simply precede its definition by a call to the `writable` method:

```rb
writable attribute('friends') {
  description 'The number of friends the user has'
  # ...
}
```

#### Relationships

There are three types of relationships that are currently supported:

- has-many relationships: pointing to a collection of related resources
- has-one relationships: pointing to a singular resource
- polymorphic has-one relationships (morph-one): pointing to a singular resource that can have one of multiple types

##### Relationship types

###### Has-many relationships

```rb
has_many('friends', Users) {
  filter_by 'friend_of'
}
```

The example defines a "friends" relationship for each user.
The second parameter passed to `has_many` defines the class that implements the endpoint for the related resource.
In this case, this is the same class that implements the relationship.
Finally, the block passed to `has_many` is the place where additional configuration of the relationship takes place.

In order to create an endpoint for the relationship (or automatically embed related objects if requested), the relationship needs to know how to filter the related collection.
The required `filter_by` method should receive the name of the collection filter as defined on the related endpoint.

When serialized in the JSON-API format, the relationship object will contain the URL of an automatically-generated endpoint for the related collection.
For the above example, this would point to `users/123/friends`.

###### Has-one relationships

```rb
has_one('group', Groups) {
  foreign_key 'group_id'
}
```

This example describes the relationship to a group (which is defined in the `Groups` class).
The `foreign_key` method should receive the field in the service response that identifies the related object.
This is used to declare the related object (a "resource object" in JSON-API jargon) as well as generate an URL (`groups/456`).

##### Sideloading relationships

...

### Pagination

...
