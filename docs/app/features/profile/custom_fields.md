# Custom Fields

With custom profile fields, platforms can customize what data they want to collect from registered users. This data can be used in reports / learning analytics, e.g. to measure metrics such as learner success or community engagement against demographic dimensions like age or occupation.

Once registered in the database, these custom fields will show up on users' profile pages, where they can edit them.

Currently, we support the following types of fields:

- **Text**: a free-text field where users can enter any text
- **Select**: an auto-complete / dropdown field which lets users choose one value from a predefined list of values
- **Multi-select**: like select fields, but users can select more than one value

## Mandatory fields

Fields can be marked as **required**, meaning users will have to fill them out before they can access the learning content on the platform.

Configuring already-existing, optional fields as mandatory at a later time will also prevent previously-registered users from accessing most of the site content (by means of an "interrupt" page), until they have provided a value for these fields.

## Setup

Configuring custom fields is currently only possible from the `xi-account` Rails console. Creating a field this way will also automatically schedule the "interrupts" for existing users who will need to fill out these fields before proceeding.

### Text fields

```ruby
CustomTextField.create!(
  name: 'affiliation',
  title: 'Affiliation',
  context: 'user',
  required: false # true for mandatory fields, false for optional ones
)
```

### Select fields

```ruby
CustomSelectField.create!(
  name: 'occupation',
  title: 'Occupation',
  context: 'user',
  values: %w[not_set scientist cab_driver],
  default_values: ['not_set'],
  required: false # true for mandatory fields, false for optional ones
)
```

### Multi-select fields

```ruby
CustomMultiSelectField.create!(
  name: 'languages',
  title: 'Languages spoken',
  context: 'user',
  values: %w[not_set ar de en es fr pt ru zh],
  default_values: ['not_set'],
  required: false # true for mandatory fields, false for optional ones
)
```

## Update

In rare cases, custom fields may be updated, e.g. when adding further options to a multi-select field.

!!! warning

    Please be careful with such operations and only update profile field if required.
    Always consider the implications thoroughly, especially when renaming / removing values from select fields. If possible, only add new values to select fields.

### Scenario: Add new profile field options

1. Add the corresponding locale key with translations in `config/locales/*.yml`, e.g. `profiles.settings.field_name.new_value`, and deploy the new locales so they are available before adding a new option.
2. Connect to the Rails console for `xi-account` to edit the respective profile field.
3. Update the profile field options as follows:

    ```ruby
    # Make sure to edit the correct field.
    field = CustomField.find_by(name: 'field_name')
    # Make sure to include *all* existing options as well.
    field.update!(values: [
      'value_1',
      'value_2',
      'new_value',
    ])
    ```
