require 'rails_helper'

describe Api::BoardsController, 'index', type: :controller do
  let!(:board1) { FactoryBot.create(:board) }
  let!(:board2) { FactoryBot.create(:board) }
  let!(:board3) { FactoryBot.create(:board) }

  it 'should return all boards' do
    get :index, format: :json
    expect(response.body).to eql([board1, board2, board3].to_json)
  end

  it 'should be successful' do
    get :index, format: :json
    expect(response).to be_successful
  end
end

describe Api::BoardsController, 'show' do
  let!(:board) { FactoryBot.create(:board) }

  it 'should return the board with the task groups' do
    get :show, params: { id: board.id }, format: :json
    json = JSON.parse(response.body)
    expect(json['title']).to eql(board.title)
    expect(json['task_groups']).not_to be_blank
    expect(json['task_groups'][0]['tasks']).to be_a_kind_of(Array)
  end

  it 'should be successful' do
    get :show, params: { id: board.id }, format: :json
    expect(response).to be_successful
  end

  describe 'when params[:no_task_groups] is set to true' do
    it 'should return only the board' do
      get :show, params: { id: board.id, no_task_groups: true }, format: :json
      json = JSON.parse(response.body)
      expect(json['title']).to eql(board.title)
      expect(json['task_groups']).to be_blank
    end
  end
end

describe Api::BoardsController, 'create' do
  let(:board_attributes) { FactoryBot.attributes_for(:board) }

  it 'should add a new board' do
    expect { post :create, params: { board: board_attributes }, format: :json }
      .to change { Board.count }.by(1)
  end

  it 'should return the created board in json' do
    post :create, params: { board: board_attributes }, format: :json
    json = JSON.parse(response.body)
    expect(json['id']).not_to be_nil
    expect(json['title']).to eql(board_attributes[:title])
  end

  it 'should return status :created' do
    post :create, params: { board: board_attributes }, format: :json
    expect(response).to have_http_status(:created)
  end

  describe 'when the board can\'t be created' do
    before(:each) do
      board_attributes[:title] = ''
    end

    it 'should not add a new board' do
      expect do
        post :create, params: { board: board_attributes }, format: :json
      end.not_to(change { Board.count })
    end

    it 'should return the errors in json' do
      post :create, params: { board: board_attributes }, format: :json
      json = JSON.parse(response.body)
      expect(json['id']).to be_nil
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      post :create, params: { board: board_attributes }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::BoardsController, 'update' do
  let(:board) { FactoryBot.create(:board) }
  let(:board_attributes) { board.attributes }

  before(:each) do
    board_attributes['title'] = board_attributes['title'] + ' updated'
  end

  it 'should not add a new board' do
    expect do
      patch :update, params: { id: board.id, board: board_attributes },
                     format: :json
    end.not_to(change { Board.count })
  end

  it 'should return the updated board in json' do
    patch :update, params: { id: board.id, board: board_attributes },
                   format: :json
    json = JSON.parse(response.body)
    expect(json['id']).to eql(board.id)
    expect(json['title']).to eql(board_attributes['title'])
  end

  it 'should be successful' do
    patch :update, params: { id: board.id, board: board_attributes },
                   format: :json
    expect(response).to be_successful
  end

  describe 'when the board can\'t be updated' do
    before(:each) do
      board_attributes['title'] = ''
    end

    it 'should return the errors in json' do
      patch :update, params: { id: board.id, board: board_attributes },
                     format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      patch :update, params: { id: board.id, board: board_attributes },
                     format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::BoardsController, 'destroy' do
  let!(:board) { FactoryBot.create(:board) }

  it 'should remove the board from database' do
    expect { delete :destroy, params: { id: board.id }, format: :json }
      .to change { Board.count }.by(-1)
  end

  it 'should return nothing in json' do
    delete :destroy, params: { id: board.id }, format: :json
    expect(response.body).to be_blank
  end

  it 'should be successful' do
    delete :destroy, params: { id: board.id }, format: :json
    expect(response).to be_successful
  end

  describe 'when the board can\'t be destroyed' do
    # Have to use mock object because we don't really have validation in
    # before_destroy.
    let(:board) { FactoryBot.build_stubbed(:board) }

    before(:each) do
      allow(board).to receive(:destroy).and_return(false)
      allow(board.errors).to receive(:full_messages).and_return(%w[foo bar])
      allow(Board).to receive(:find).with(board.id.to_s).and_return(board)
    end

    it 'should return the errors in json' do
      delete :destroy, params: { id: board.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      delete :destroy, params: { id: board.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
