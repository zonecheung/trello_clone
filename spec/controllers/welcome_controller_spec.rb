require 'rails_helper'

describe WelcomeController, 'index', type: :controller do
  render_views false

  let!(:board1) { FactoryBot.create(:board) }
  let!(:board2) { FactoryBot.create(:board) }
  let!(:board3) { FactoryBot.create(:board) }

  before(:each) do
    board3.update_attributes!(updated_at: 3.hours.ago)
    board1.update_attributes!(updated_at: 4.hours.ago)
  end

  describe 'without params[:board_id]' do
    it 'should redirect to root_url with latest board_id param' do
      get :index
      expect(response).to redirect_to(root_url(board_id: board2.id))
    end

    describe 'when session[:board_id] is specified' do
      before(:each) do
        session[:board_id] = 3
      end

      after(:each) do
        session[:board_id] = nil
      end

      it 'should not get latest board' do
        get :index
        expect(Board).not_to receive(:recently_updated)
      end

      it 'should be successful' do
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe 'with params[:board_id]' do
    after(:each) do
      session[:board_id] = nil
    end

    it 'should not get latest board' do
      get :index, params: { board_id: board3.id }
      expect(Board).not_to receive(:recently_updated)
    end

    it 'should be successful' do
      get :index, params: { board_id: board3.id }
      expect(response).to be_successful
    end

    it 'should set the session[:board_id]' do
      get :index, params: { board_id: board3.id }
      expect(session[:board_id].to_i).to eql(board3.id)
    end
  end
end
