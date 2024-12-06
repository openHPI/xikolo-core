# frozen_string_literal: true

module Steps
  module Course
    module Permissions
      When 'I remove the first teacher' do
        teacher = context.fetch(:teacher_group_members).first
        within '#group-teachers' do
          teacher = find('td', text: teacher['full_name'])
          teacher_row = teacher.ancestor('tr')

          within teacher_row do
            click_on('Remove')
          end
        end
      end

      When 'I add the additional user to the teacher group' do
        user = context.fetch :additional_user
        tom_select user.email[0..10], search: true, css: '#group-teachers'
        within '#group-teachers' do
          click_on 'Add user'
        end
      end

      Then 'I see the members of the teacher group' do
        context.with :teacher_group_members do |teachers|
          within '#group-teachers' do
            teachers.each do |teacher|
              expect(page).to have_content(teacher['full_name'])
              expect(page).to have_content(teacher['email'])
            end
          end
        end
      end

      Then 'I see the granted roles for the teacher group' do
        within '#group-teachers' do
          expect(page).to have_content('Pinboard moderation')
        end
      end

      Then 'I see a link to the enrollment list' do
        within '#group-students' do
          expect(page).to have_links('enrollment list')
        end
      end

      Then 'I see the granted roles for the student group' do
        within '#group-students' do
          expect(page).to have_content('Student: basic permissions')
        end
      end

      Then 'the user should not be teacher' do
        context.with :teacher_group_members do |teachers|
          within '#group-teachers' do
            expect(page).to_not have_content(teachers.first['full_name'])
            expect(page).to_not have_content(teachers.first['email'])
          end
        end
      end

      Then 'the user should be teacher' do
        context.with :additional_user do |user|
          within '#group-teachers' do
            expect(page).to have_content(user['full_name'])
            expect(page).to have_content(user['email'])
          end
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Course::Permissions }
