require 'rails_helper'

describe Api::TasksController, 'index', type: :controller do
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group) { FactoryBot.create(:task_group, board: board) }
  let!(:task1) { FactoryBot.create(:task, task_group: task_group) }
  let!(:task2) { FactoryBot.create(:task, task_group: task_group) }
  let!(:task3) { FactoryBot.create(:task, task_group: task_group) }

  it 'should have tasks in the task group' do
    expect(task_group.tasks.count).not_to eql(0)
  end

  it 'should return all tasks belong to the task group' do
    get :index,
        params: { board_id: board.id, task_group_id: task_group.id },
        format: :json
    expect(response.body).to eql(task_group.tasks.to_json)
  end

  it 'should be successful' do
    get :index,
        params: { board_id: board.id, task_group_id: task_group.id },
        format: :json
    expect(response).to be_successful
  end
end

describe Api::TasksController, 'show', type: :controller do
  let(:task) { FactoryBot.create(:task) }
  let(:task_group) { task.task_group }
  let(:board) { task_group.board }

  it 'should return the task group' do
    get :show,
        params: {
          board_id: board.id, task_group_id: task_group.id, id: task.id
        },
        format: :json
    json = JSON.parse(response.body)
    expect(json['title']).to eql(task.title)
  end

  it 'should be successful' do
    get :show,
        params: {
          board_id: board.id, task_group_id: task_group.id, id: task.id
        },
        format: :json
    expect(response).to be_successful
  end
end

describe Api::TasksController, 'create', type: :controller do
  let!(:task_group) { FactoryBot.create(:task_group) }
  let!(:board) { task_group.board }
  let(:task_attributes) do
    FactoryBot.attributes_for(:task, task_group_id: task_group.id)
  end

  it 'should add a new task' do
    expect do
      post :create,
           params: { board_id: board.id, task_group_id: task_group.id,
                     task: task_attributes },
           format: :json
    end.to change { Task.count }.by(1)
  end

  it 'should return the created task in json' do
    post :create,
         params: { board_id: board.id, task_group_id: task_group.id,
                   task: task_attributes },
         format: :json
    json = JSON.parse(response.body)
    expect(json['id']).not_to be_nil
    expect(json['title']).to eql(task_attributes[:title])
  end

  it 'should return status :created' do
    post :create,
         params: { board_id: board.id, task_group_id: task_group.id,
                   task: task_attributes },
         format: :json
    expect(response).to have_http_status(:created)
  end

  describe 'when the task can\'t be created' do
    before(:each) do
      task_attributes[:title] = ''
    end

    it 'should not add a new task' do
      expect do
        post :create,
             params: { board_id: board.id, task_group_id: task_group.id,
                       task: task_attributes },
             format: :json
      end.not_to(change { Task.count })
    end

    it 'should return the errors in json' do
      post :create,
           params: { board_id: board.id, task_group_id: task_group.id,
                     task: task_attributes },
           format: :json
      json = JSON.parse(response.body)
      expect(json['id']).to be_nil
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      post :create,
           params: { board_id: board.id, task_group_id: task_group.id,
                     task: task_attributes },
           format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::TasksController, 'update', type: :controller do
  let(:task) { FactoryBot.create(:task) }
  let(:task_group) { task.task_group }
  let(:board) { task_group.board }
  let(:task_attributes) { task.attributes }

  before(:each) do
    task_attributes['title'] = task_attributes['title'] + ' updated'
  end

  it 'should not add a new task' do
    expect do
      patch :update,
            params: {
              board_id: board.id, task_group_id: task_group.id, id: task.id,
              task: task_attributes
            },
            format: :json
    end.not_to(change { Task.count })
  end

  it 'should return the updated task group in json' do
    patch :update,
          params: {
            board_id: board.id, task_group_id: task_group.id, id: task.id,
            task: task_attributes
          },
          format: :json
    json = JSON.parse(response.body)
    expect(json['id']).to eql(task.id)
    expect(json['title']).to eql(task_attributes['title'])
  end

  it 'should be successful' do
    patch :update,
          params: {
            board_id: board.id, task_group_id: task_group.id, id: task.id,
            task: task_attributes
          },
          format: :json
    expect(response).to be_successful
  end

  describe 'when the task can\'t be updated' do
    before(:each) do
      task_attributes['title'] = ''
    end

    it 'should return the errors in json' do
      patch :update,
            params: {
              board_id: board.id, task_group_id: task_group.id, id: task.id,
              task: task_attributes
            },
            format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      patch :update,
            params: {
              board_id: board.id, task_group_id: task_group.id, id: task.id,
              task: task_attributes
            },
            format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::TasksController, 'destroy', type: :controller do
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group) { FactoryBot.create(:task_group, board: board) }
  let!(:task) { FactoryBot.create(:task, task_group: task_group) }

  it 'should remove the task from database' do
    expect do
      delete :destroy,
             params: {
               board_id: board.id, task_group_id: task_group.id, id: task.id
             },
             format: :json
    end.to change { Task.count }.by(-1)
  end

  it 'should return nothing in json' do
    delete :destroy,
           params: {
             board_id: board.id, task_group_id: task_group.id, id: task.id
           },
           format: :json
    expect(response.body).to be_blank
  end

  it 'should be successful' do
    delete :destroy,
           params: {
             board_id: board.id, task_group_id: task_group.id, id: task.id
           },
           format: :json
    expect(response).to be_successful
  end

  describe 'when the task can\'t be destroyed' do
    # Have to use mock object because we don't really have validation in
    # before_destroy.
    let(:task) { FactoryBot.build_stubbed(:task, task_group: task_group) }

    before(:each) do
      allow(task).to receive(:destroy).and_return(false)
      allow(task.errors).to(
        receive(:full_messages).and_return(%w[foo bar])
      )
      allow(Task).to(
        receive(:find).with(task.id.to_s).and_return(task)
      )
    end

    it 'should return the errors in json' do
      delete :destroy,
             params: {
               board_id: board.id, task_group_id: task_group.id, id: task.id
             },
             format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      delete :destroy,
             params: {
               board_id: board.id, task_group_id: task_group.id, id: task.id
             },
             format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

describe Api::TasksController, 'move_to_position', type: :controller do
  # NOTE: We create 3 default task_groups for the board,
  # =>    but don't want to rely on them in these tests.
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group) { FactoryBot.create(:task_group, board: board) }
  let!(:task1) { FactoryBot.create(:task, task_group: task_group) }
  let!(:task2) { FactoryBot.create(:task, task_group: task_group) }
  let!(:task3) { FactoryBot.create(:task, task_group: task_group) }

  it 'should have a position in the task' do
    expect(task3.position).to be_a_kind_of(Integer)
    expect(task3.position).to be > 1
  end

  it 'should not change the task group count' do
    expect do
      patch :move_to_position,
            params: {
              board_id: board.id, task_group_id: task_group.id, id: task3.id,
              position: 1
            },
            format: :json
    end.not_to(change { Task.count })
  end

  it 'should change the position of the task' do
    patch :move_to_position,
          params: {
            board_id: board.id, task_group_id: task_group.id, id: task3.id,
            position: 1
          },
          format: :json
    task3.reload
    expect(task3.position).to eql(1)
  end

  it 'should have sorted the positions of tasks after moving' do
    patch :move_to_position,
          params: {
            board_id: board.id, task_group_id: task_group.id, id: task3.id,
            position: 1
          },
          format: :json
    task_group.reload
    expect(task_group.tasks.first).to eql(task3)
    task_group.tasks.each_with_index do |task, i|
      expect(task.position).to eql(i + 1)
    end
  end

  describe 'when there\'s an error moving the position' do
    let!(:task4) { FactoryBot.build_stubbed(:task, task_group: task_group) }

    before(:each) do
      allow(task4).to receive(:move_to_position).and_return(false)
      allow(task4.errors).to(
        receive(:full_messages).and_return(%w[foo bar])
      )
      allow(Task).to(
        receive(:find).with(task4.id.to_s).and_return(task4)
      )
    end

    it 'should return the errors in json' do
      patch :move_to_position,
            params: {
              board_id: board.id, task_group_id: task_group.id, id: task4.id,
              position: 1
            },
            format: :json
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_blank
    end

    it 'should return status :unprocessable_entity' do
      patch :move_to_position,
            params: {
              board_id: board.id, task_group_id: task_group.id, id: task4.id,
              position: 1
            },
            format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
