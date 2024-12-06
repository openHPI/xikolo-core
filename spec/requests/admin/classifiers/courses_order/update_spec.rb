# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Classifier: CoursesOrder: Update', type: :request do
  let(:update_order) do
    post "/admin/clusters/#{classifier.cluster_id}/classifiers/#{classifier.id}/courses/order",
      params:,
      headers:
  end
  let(:headers) { {} }
  let(:params) { {} }
  let(:classifier) { create(:classifier) }
  let(:courses) { create_list(:course, 4) }
  let(:deleted_course) { create(:course, deleted: true) }

  context 'with permission' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[course.cluster.manage] }

    before { stub_user_request permissions: }

    context 'with no assigned courses' do
      let(:params) do
        {
          courses: [
            courses[2].id,
            courses[0].id,
            courses[1].id,
          ],
        }
      end

      it 'assigns the courses to the classifier in the given order' do
        expect { update_order }.to change(Course::ClassifierAssignment, :count).from(0).to(3)
        expect(classifier.courses.pluck(:id)).to eq [
          courses[2].id,
          courses[0].id,
          courses[1].id,
        ]
        expect(flash[:success].first).to eq 'The course order has been updated.'
        expect(update_order).to redirect_to "/admin/clusters/#{classifier.cluster_id}/classifiers/#{classifier.id}/courses/order"
      end
    end

    context 'with courses assigned to the classifier' do
      let(:params) do
        {
          courses: [
            courses[2].id,
            courses[0].id,
            courses[1].id,
          ],
        }
      end

      before do
        create(:classifier_assignment, classifier:, course: courses[0], position: 1)
        create(:classifier_assignment, classifier:, course: courses[1], position: 2)
        create(:classifier_assignment, classifier:, course: courses[2], position: 3)
      end

      it 'updates the course order for the classifier' do
        expect(classifier.courses.pluck(:id)).to eq [
          courses[0].id,
          courses[1].id,
          courses[2].id,
        ]
        expect { update_order }.not_to change(Course::ClassifierAssignment, :count).from(3)
        expect(classifier.courses.pluck(:id)).to eq [
          courses[2].id,
          courses[0].id,
          courses[1].id,
        ]
        expect(flash[:success].first).to eq 'The course order has been updated.'
        expect(update_order).to redirect_to "/admin/clusters/#{classifier.cluster_id}/classifiers/#{classifier.id}/courses/order"
      end

      it 'does not affect other classifier assignments' do
        another_classifier = create(:classifier, cluster: classifier.cluster)
        create(:classifier_assignment, classifier: another_classifier, course: courses[1], position: 1)

        expect { update_order }.not_to change(Course::ClassifierAssignment, :count).from(4)
        expect(classifier.courses.pluck(:id)).to eq [
          courses[2].id,
          courses[0].id,
          courses[1].id,
        ]
        expect(another_classifier.courses.pluck(:id)).to eq [courses[1].id]
      end

      it 'deletes classifier_assignments where soft-deleted courses are referenced' do
        create(:classifier_assignment, classifier:, course: deleted_course, position: 4)

        expect { update_order }.to change(Course::ClassifierAssignment, :count).from(4).to(3)
        expect(classifier.courses.pluck(:id)).to eq [
          courses[2].id,
          courses[0].id,
          courses[1].id,
        ]
      end

      context 'when removing courses from the classifier' do
        let(:params) do
          {
            courses: [
              courses[2].id,
              courses[0].id,
            ],
          }
        end

        it 'deletes the course assignment' do
          expect { update_order }.to change(Course::ClassifierAssignment, :count).from(3).to(2)
          expect(classifier.courses.pluck(:id)).to eq [
            courses[2].id,
            courses[0].id,
          ]
          expect(flash[:success].first).to eq 'The course order has been updated.'
          expect(update_order).to redirect_to "/admin/clusters/#{classifier.cluster_id}/classifiers/#{classifier.id}/courses/order"
        end
      end
    end
  end

  context 'without permission' do
    it 'redirects to the start page' do
      expect(update_order).to redirect_to root_url
    end
  end
end
