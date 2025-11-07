# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'ostruct'
require 'xikolo/config'

template = <<~ERB
  BEGIN;

  -- 1. Clear all previous grants

  DELETE FROM grants
  WHERE principal_id IN (
    SELECT id
    FROM groups
    WHERE name LIKE 'course.%.%'
  ) AND principal_type = 'Group';

  -- 2. Ensure that all roles are created

  INSERT INTO roles (name, permissions, created_at, updated_at)
    SELECT
      name,
      ARRAY[]::varchar[] as permissions,
      now(),
      now()
    FROM unnest(ARRAY['<%= course_groups.map { |k, v| v['grants'] } \
                  .flatten.map { |g| g['role'] } \
                  .sort \
                  .uniq.join("', '") %>']) AS name
    LEFT JOIN roles USING(name)
    WHERE roles.name IS NULL
  RETURNING name as "created currently not existing roles";

  -- 3. Create grants

  <% course_groups.each do |name, group| %>
  <% group['grants'].each do |grant| %>
  <% if grant['context'] == 'root' %>
  INSERT INTO grants(context_id, role_id, principal_type, principal_id, created_at, updated_at)
    SELECT
      (SELECT id FROM contexts WHERE parent_id IS NULL),
      (SELECT id FROM roles WHERE name = '<%= grant['role'] %>'),
      'Group',
      (SELECT id FROM groups WHERE name = CONCAT('course.', course_code, '.<%= name %>')),
      now(),
      now()
    FROM courses;
  <% else %>
  INSERT INTO grants(context_id, role_id, principal_type, principal_id, created_at, updated_at)
    SELECT
      context_id,
      (SELECT id FROM roles WHERE name = '<%= grant['role'] %>'),
      'Group',
      (SELECT id FROM groups WHERE name = CONCAT('course.', course_code, '.<%= name %>')),
      now(),
      now()
    FROM courses
    WHERE context_id IS NOT NULL;
  <% end %>
  <% end %>
  <% end %>

  ROLLBACK;
ERB

puts ERB
  .new(template)
  .result(OpenStruct.new(Xikolo.config).instance_eval { binding }) # rubocop:disable Style/OpenStructUse
