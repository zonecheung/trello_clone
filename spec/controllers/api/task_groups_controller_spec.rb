require 'rails_helper'

describe Api::TaskGroupsController, 'index', type: :controller do
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group) { FactoryBot.create(:task_group, board: board) }

  it 'should have task groups in the board' do
    expect(board.task_groups.count).not_to eql(0)
  end

  it 'should return all task groups belong to the board' do
    get :index, params: { board_id: board.id }, format: :json
    expect(response.body).to eql(board.task_groups.to_json)
  end

  it 'should be successful' do
    get :index, params: { board_id: board.id }, format: :json
    expect(response).to be_successful
  end
end

describe Api::TaskGroupsController, 'show', type: :controller do
  let(:task_group) { FactoryBot.create(:task_group) }
  let(:board) { task_group.board }

  it 'should return the task group' do
    get :show, params: { board_id: board.id, id: task_group.id }, format: :json
    json = JSON.parse(response.body)
    expect(json['title']).to eql(task_group.title)
  end

  it 'should be successful' do
    get :show, params: { board_id: board.id, id: task_group.id }, format: :json
    expect(response).to be_successful
  end
end

describe Api::TaskGroupsController, 'create', type: :controller do
  let!(:board) { FactoryBot.create(:board) }
  let(:task_group_attributes) do
    FactoryBot.attributes_for(:task_group, board_id: board.id)
  end

  it 'should add a new task group' do
    expect do
      post :create,
           params: { board_id: board.id, task_group: task_group_attributes },
           format: :json
    end.to change { TaskGroup.count }.by(1)
  end

  it 'should return the created task group in json' do
    post :create,
         params: { board_id: board.id, task_group: task_group_attributes },
         format: :json
    json = JSON.parse(response.body)
    expect(json['id']).not_to be_nil
    expect(json['title']).to eql(task_group_attributes[:title])
  end

  it 'should return status :created' do
    post :create,
         params: { board_id: board.id, task_group: task_group_attributes },
         format: :json
    expect(response).to have_http_status(:created)
  end

  describe 'when the task group can\'t be created' do
    before(:each) do
      task_group_attributes[:title] = ''
    end

    it 'should not add a new task group' do
      expect do
        post :create,
             params: { board_id: board.id, task_group: task_group_attributes },
             format: :json
      end.not_to(change { TaskGroup.count })
    end

    it 'should return the errors in json' do
      post :create,
           params: { board_id: board.id, task_group: task_group_attributes },
           format: :json
      json = JSON.parse(response.body)
      expect(json['id']).to be_nil
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      post :create,
           params: { board_id: board.id, task_group: task_group_attributes },
           format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::TaskGroupsController, 'update', type: :controller do
  let(:board) { FactoryBot.create(:board) }
  let(:task_group) { FactoryBot.create(:task_group, board: board) }
  let(:task_group_attributes) { task_group.attributes }

  before(:each) do
    task_group_attributes['title'] = task_group_attributes['title'] + ' updated'
  end

  it 'should not add a new task group' do
    expect do
      patch :update,
            params: {
              board_id: board.id, id: task_group.id,
              task_group: task_group_attributes
            },
            format: :json
    end.not_to(change { TaskGroup.count })
  end

  it 'should return the updated task group in json' do
    patch :update,
          params: {
            board_id: board.id, id: task_group.id,
            task_group: task_group_attributes
          },
          format: :json
    json = JSON.parse(response.body)
    expect(json['id']).to eql(task_group.id)
    expect(json['title']).to eql(task_group_attributes['title'])
  end

  it 'should be successful' do
    patch :update,
          params: {
            board_id: board.id, id: task_group.id,
            task_group: task_group_attributes
          },
          format: :json
    expect(response).to be_successful
  end

  describe 'when the task group can\'t be updated' do
    before(:each) do
      task_group_attributes['title'] = ''
    end

    it 'should return the errors in json' do
      patch :update,
            params: {
              board_id: board.id, id: task_group.id,
              task_group: task_group_attributes
            },
            format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      patch :update,
            params: {
              board_id: board.id, id: task_group.id,
              task_group: task_group_attributes
            },
            format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::TaskGroupsController, 'destroy', type: :controller do
  let(:board) { FactoryBot.create(:board) }
  let!(:task_group) { FactoryBot.create(:task_group, board: board) }

  it 'should remove the task group from database' do
    expect do
      delete :destroy,
             params: { board_id: board.id, id: task_group.id }, format: :json
    end.to change { TaskGroup.count }.by(-1)
  end

  it 'should return nothing in json' do
    delete :destroy,
           params: { board_id: board.id, id: task_group.id }, format: :json
    expect(response.body).to be_blank
  end

  it 'should be successful' do
    delete :destroy,
           params: { board_id: board.id, id: task_group.id }, format: :json
    expect(response).to be_successful
  end

  describe 'when the task group can\'t be destroyed' do
    # Have to use mock object because we don't really have validation in
    # before_destroy.
    let(:task_group) { FactoryBot.build_stubbed(:task_group, board: board) }

    before(:each) do
      allow(task_group).to receive(:destroy).and_return(false)
      allow(task_group.errors).to(
        receive(:full_messages).and_return(%w[foo bar])
      )
      allow(TaskGroup).to(
        receive(:find).with(task_group.id.to_s).and_return(task_group)
      )
    end

    it 'should return the errors in json' do
      delete :destroy,
             params: { board_id: board.id, id: task_group.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      delete :destroy,
             params: { board_id: board.id, id: task_group.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::TaskGroupsController, 'move_to_position', type: :controller do
  # NOTE: We create 3 default task_groups for the board,
  # =>    but don't want to rely on them in these tests.
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group1) { FactoryBot.create(:task_group, board: board) }
  let!(:task_group2) { FactoryBot.create(:task_group, board: board) }
  let!(:task_group3) { FactoryBot.create(:task_group, board: board) }

  it 'should have a position in the task group' do
    expect(task_group3.position).to be_a_kind_of(Integer)
    expect(task_group3.position).to be > 1
  end

  it 'should not change the task group count' do
    expect do
      patch :move_to_position,
            params: { board_id: board.id, id: task_group3.id,
                      target_board_id: board.id, position: 1 },
            format: :json
    end.not_to(change { TaskGroup.count })
  end

  it 'should change the position of the task group' do
    patch :move_to_position,
          params: { board_id: board.id, id: task_group3.id,
                    target_board_id: board.id, position: 1 },
          format: :json
    task_group3.reload
    expect(task_group3.position).to eql(1)
  end

  it 'should have sorted the positions of task groups after moving' do
    patch :move_to_position,
          params: { board_id: board.id, id: task_group3.id,
                    target_board_id: board.id, position: 1 },
          format: :json
    board.reload
    expect(board.task_groups.first).to eql(task_group3)
    board.task_groups.each_with_index do |task_group, i|
      expect(task_group.position).to eql(i + 1)
    end
  end

  describe 'when there\'s an error moving the position' do
    let!(:task_group4) { FactoryBot.build_stubbed(:task_group, board: board) }

    before(:each) do
      allow(task_group4).to receive(:move_to_position).and_return(false)
      allow(task_group4.errors).to(
        receive(:full_messages).and_return(%w[foo bar])
      )
      allow(TaskGroup).to(
        receive(:find).with(task_group4.id.to_s).and_return(task_group4)
      )
    end

    it 'should return the errors in json' do
      patch :move_to_position,
            params: { board_id: board.id, id: task_group4.id,
                      target_board_id: board.id, position: 1 },
            format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      patch :move_to_position,
            params: { board_id: board.id, id: task_group4.id,
                      target_board_id: board.id, position: 1 },
            format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
