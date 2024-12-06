# frozen_string_literal: true

# Roles that were once part of the codebase, but should no longer be present.
# Could theoretically be cleared again after it has been cleared from all production systems.
# Keeping entries in the list for a while does not hurt, though.
OBSOLETE_ROLES = %w[
  oauth.admin
  payment.admin
].freeze

namespace :permissions do
  desc 'Load groups, roles, and permissions into the database'
  task load: %i[environment] do
    ApplicationRecord.transaction do
      Rails.root.glob('lib/tasks/permissions/*.{yaml,yml}').sort.each do |file|
        puts "Loading #{file}..."

        data = File.open(file) {|fd| YAML.safe_load(fd) }

        data.fetch('groups', []).each do |group|
          puts "Syncing group #{group['name']}..."
          Group.find_or_initialize_by(name: group['name']).update!(group)
        end

        data.fetch('roles', {}).each do |name, permissions|
          puts "Syncing role #{name}..."
          Role.find_or_initialize_by(name:).update!(permissions:)
        end

        data.fetch('grants', []).each do |grant|
          puts "Syncing grant #{grant}..."

          role = Role.resolve(grant['role'])
          group = Group.resolve(grant['group'])
          context = Context.resolve(grant.fetch('context', 'root'))

          Grant.find_or_create_by!(role:, principal: group, context:)
        end
      end

      OBSOLETE_ROLES.each do |role|
        puts "Purge obsolete role #{role} with all grants..."

        Role.find_by(name: role)&.destroy
      end
    end
  end
end
