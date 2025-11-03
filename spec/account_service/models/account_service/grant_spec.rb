# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Grant, type: :model do
  let(:grant) { create(:'account_service/grant') }

  describe '.for' do
    subject(:grants) { described_class.for(**kwargs) }

    let(:kwargs) { {} }

    context 'with principal not set and type not set' do
      before do
        create_list(:'account_service/grant', 5)
      end

      it 'returns nothing' do
        expect(grants.size).to eq 0
      end
    end

    context 'with principal not set but type set' do
      let(:kwargs) { {type: AccountService::Group} }

      let!(:matches) { create_list(:'account_service/grant', 2, principal: create(:'account_service/group')) }

      before do
        create_list(:'account_service/grant', 2)
      end

      it 'contains only group grants' do
        expect(grants).to match_array matches
      end
    end

    context 'with principal set but type not' do
      let(:kwargs)    { {principal:} }
      let(:principal) { create(:'account_service/user') }

      let!(:matches) { create_list(:'account_service/grant', 2, principal:) }

      before do
        create(:'account_service/grant', principal: create(:'account_service/user'))
        create(:'account_service/grant', principal: create(:'account_service/group'))
      end

      it 'contains only matching user grants' do
        expect(grants).to match_array matches
      end
    end

    context 'with principal set and type set' do
      let(:kwargs)    { {principal: principal.id, type: AccountService::User} }
      let(:principal) { create(:'account_service/user') }

      let!(:matches) { create_list(:'account_service/grant', 2, principal:) }

      before do
        create(:'account_service/grant', principal: create(:'account_service/user'))
        create(:'account_service/grant', principal: create(:'account_service/group'))
      end

      it 'contains only matching grants' do
        expect(grants).to match_array matches
      end
    end

    context 'with context' do
      let(:parent_context) { create(:'account_service/context') }
      let(:other_context) { create(:'account_service/context', parent: parent_context) }
      let(:context) { create(:'account_service/context', parent: parent_context) }

      context 'with principal not set and type not set' do
        before do
          create(:'account_service/grant')
          create(:'account_service/grant', context:)
          create(:'account_service/grant', context: other_context)
          create(:'account_service/grant', context: parent_context)
        end

        it 'returns nothing' do
          expect(grants.size).to eq 0
        end
      end

      context 'with principal not set' do
        let(:kwargs) { {**super(), type:} }

        context 'and type set to USER' do
          let(:type) { AccountService::User }
          let(:user) { create(:'account_service/user') }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:'account_service/grant', principal: user) }
          let!(:grant2) { create(:'account_service/grant', principal: user, context:) }
          let!(:grant3) { create(:'account_service/grant', principal: user, context: parent_context) }

          before do
            create(:'account_service/grant', principal: user, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end

        context 'and type set to GROUP' do
          let(:type) { AccountService::Group }
          let(:group) { create(:'account_service/group') }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:'account_service/grant', principal: group) }
          let!(:grant2) { create(:'account_service/grant', principal: group, context:) }
          let!(:grant3) { create(:'account_service/grant', principal: group, context: parent_context) }

          before do
            create(:'account_service/grant', principal: group, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end
      end

      context 'with principal set' do
        let(:kwargs) { {**super(), principal:} }

        context 'and principal being a User' do
          let(:principal) { create(:'account_service/user') }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:'account_service/grant', principal:) }
          let!(:grant2) { create(:'account_service/grant', principal:, context:) }
          let!(:grant3) { create(:'account_service/grant', principal:, context: parent_context) }

          before do # create non matching elements
            create(:'account_service/grant', principal: create(:'account_service/user'))
            create(:'account_service/grant', principal: create(:'account_service/user'), context:)
            create(:'account_service/grant', principal: create(:'account_service/group'), context:)

            create(:'account_service/grant', principal:, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end

        context 'and principal being a Group' do
          let(:principal) { create(:'account_service/group') }
          let(:kwargs) { {**super(), context:} }

          let!(:grant1) { create(:'account_service/grant', principal:) }
          let!(:grant2) { create(:'account_service/grant', principal:, context:) }
          let!(:grant3) { create(:'account_service/grant', principal:, context: parent_context) }

          before do # create non matching elements
            create(:'account_service/grant', principal: create(:'account_service/user'))
            create(:'account_service/grant', principal: create(:'account_service/user'), context:)
            create(:'account_service/grant', principal: create(:'account_service/group'), context:)

            create(:'account_service/grant', principal:, context: other_context)
          end

          it 'returns matches' do
            expect(grants).to contain_exactly(grant1, grant2, grant3)
          end
        end
      end
    end
  end
end
