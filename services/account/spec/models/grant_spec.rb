# frozen_string_literal: true

require 'spec_helper'

describe Grant, type: :model do
  let(:grant) { create(:grant) }

  describe '.for' do
    subject(:grants) { Grant.for(**kwargs) }

    let(:kwargs) { {} }

    context 'with principal not set and type not set' do
      before do
        create_list(:grant, 5)
      end

      it 'returns nothing' do
        expect(grants.size).to eq 0
      end
    end

    context 'with principal not set but type set' do
      let(:kwargs) { {type: Group} }

      let!(:matches) { create_list(:grant, 2, principal: create(:group)) }

      before do
        create_list(:grant, 2)
      end

      it 'contains only group grants' do
        expect(grants).to match_array matches
      end
    end

    context 'with principal set but type not' do
      let(:kwargs)    { {principal:} }
      let(:principal) { create(:user) }

      let!(:matches) { create_list(:grant, 2, principal:) }

      before do
        create(:grant, principal: create(:user))
        create(:grant, principal: create(:group))
      end

      it 'contains only matching user grants' do
        expect(grants).to match_array matches
      end
    end

    context 'with principal set and type set' do
      let(:kwargs)    { {principal: principal.id, type: User} }
      let(:principal) { create(:user) }

      let!(:matches) { create_list(:grant, 2, principal:) }

      before do
        create(:grant, principal: create(:user))
        create(:grant, principal: create(:group))
      end

      it 'contains only matching grants' do
        expect(grants).to match_array matches
      end
    end

    context 'with context' do
      let(:parent_context) { create(:context) }
      let(:other_context) { create(:context, parent: parent_context) }
      let(:context) { create(:context, parent: parent_context) }

      context 'with principal not set and type not set' do
        before do
          create(:grant)
          create(:grant, context:)
          create(:grant, context: other_context)
          create(:grant, context: parent_context)
        end

        it 'returns nothing' do
          expect(grants.size).to eq 0
        end
      end

      context 'with principal not set' do
        let(:kwargs) { {**super(), type:} }

        context 'and type set to USER' do
          let(:type) { User }
          let(:user) { create(:user) }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:grant, principal: user) }
          let!(:grant2) { create(:grant, principal: user, context:) }
          let!(:grant3) { create(:grant, principal: user, context: parent_context) }

          before do
            create(:grant, principal: user, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end

        context 'and type set to GROUP' do
          let(:type) { Group }
          let(:group) { create(:group) }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:grant, principal: group) }
          let!(:grant2) { create(:grant, principal: group, context:) }
          let!(:grant3) { create(:grant, principal: group, context: parent_context) }

          before do
            create(:grant, principal: group, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end
      end

      context 'with principal set' do
        let(:kwargs) { {**super(), principal:} }

        context 'and principal being a User' do
          let(:principal) { create(:user) }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:grant, principal:) }
          let!(:grant2) { create(:grant, principal:, context:) }
          let!(:grant3) { create(:grant, principal:, context: parent_context) }

          before do # create non matching elements
            create(:grant, principal: create(:user))
            create(:grant, principal: create(:user), context:)
            create(:grant, principal: create(:group), context:)

            create(:grant, principal:, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end

        context 'and principal being a Group' do
          let(:principal) { create(:group) }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:grant, principal:) }
          let!(:grant2) { create(:grant, principal:, context:) }
          let!(:grant3) { create(:grant, principal:, context: parent_context) }

          before do # create non matching elements
            create(:grant, principal: create(:user))
            create(:grant, principal: create(:user), context:)
            create(:grant, principal: create(:group), context:)

            create(:grant, principal:, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end
      end
    end
  end
end
