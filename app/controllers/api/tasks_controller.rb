module Api
  class TasksController < ApplicationController
    before_action :set_board_and_task_group
    before_action :set_task,
                  only: %i[show update destroy move_to_position]

    def_param_group :task_group_id do
      param :task_group_id, :number, desc: 'Task group ID', required: true
    end

    def_param_group :board_and_task_group do
      param :board_id, :number, desc: 'Board ID', required: true
      param_group :task_group_id
    end

    # GET /api/tasks.json
    api :GET, '/boards/:board_id/task_groups/:task_group_id/tasks',
        'Retrieve tasks for the task group.'
    param_group :board_and_task_group
    def index
      render json: @task_group.tasks
    end

    def_param_group :task_id do
      param :id, :number, desc: 'Task ID', required: true
    end

    # GET /api/tasks/1.json
    api :GET, '/boards/:board_id/task_groups/:task_group_id/tasks/:id',
        'Retrieve task.'
    param_group :board_and_task_group
    param_group :task_id
    def show
      render json: @task
    end

    def_param_group :task do
      param :task, Hash, desc: 'Task info', required: true do
        param_group :task_group_id
        param :title, String, desc: 'Task title', required: true
      end
    end

    # POST /api/tasks.json
    api :POST, '/boards/:board_id/task_groups/:task_group_id/tasks',
        'Create task.'
    param_group :board_and_task_group
    param_group :task
    def create
      task = Task.new(task_params)

      if task.save
        render json: task, status: :created
      else
        render json: { errors: task.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/tasks/1.json
    api :PATCH, '/boards/:board_id/task_groups/:task_group_id/tasks/:id',
        'Update task.'
    param_group :board_and_task_group
    param_group :task_id
    param_group :task
    def update
      if @task.update(task_params)
        render json: @task
      else
        render json: { errors: @task.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /api/tasks/1.json
    api :DELETE, '/boards/:board_id/task_groups/:task_group_id/tasks/:id',
        'Delete task.'
    param_group :board_and_task_group
    param_group :task_id
    def destroy
      if @task.destroy
        head :no_content
      else
        render json: { errors: @task.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH /api/tasks/1/move_to_position.json
    api :PATCH, '/boards/:board_id/task_groups/:task_group_id/tasks/:id' \
                '/move_to_position',
        'Move task to a different position in the same or another task group ' \
        'and board.'
    param_group :board_and_task_group
    param_group :task_id
    param :target_board_id, :number, desc: 'Target board ID', required: true
    param :target_task_group_id, :number,
          desc: 'Target task group ID', required: true
    param :position, :number, desc: 'New position', required: true
    def move_to_position
      if @task.move_to_position(params[:target_board_id].to_i,
                                params[:target_task_group_id].to_i,
                                params[:position].to_i)
        render json: @task
      else
        render json: { errors: @task.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_board_and_task_group
      @board = Board.find(params[:board_id])
      @task_group = TaskGroup.find(params[:task_group_id])
    end

    def set_task
      @task = Task.find(params[:id])
    end

    # Never trust parameters from the scary internet,
    # only allow the white list through.
    def task_params
      params.require(:task).permit(:board_id, :task_group_id, :id, :title)
    end
  end
end
