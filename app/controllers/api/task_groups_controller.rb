module Api
  class TaskGroupsController < ApplicationController
    before_action :set_board
    before_action :set_task_group,
                  only: %i[show update destroy move_to_position]

    def_param_group :board_id do
      param :board_id, :number, desc: 'Board ID', required: true
    end

    # GET /api/task_groups.json
    api :GET, '/boards/:board_id/task_groups',
        'Retrieve task groups for the board.'
    param_group :board_id
    def index
      render json: @board.task_groups
    end

    def_param_group :task_group_id do
      param :id, :number, desc: 'Task group ID', required: true
    end

    # GET /api/task_groups/1.json
    api :GET, '/boards/:board_id/task_groups/:id', 'Retrieve task group.'
    param_group :board_id
    param_group :task_group_id
    def show
      render json: @task_group
    end

    def_param_group :task_group do
      param :task_group, Hash, desc: 'Task group info', required: true do
        param_group :board_id
        param :title, String, desc: 'Task group title', required: true
      end
    end

    # POST /api/task_groups.json
    api :POST, '/boards/:board_id/task_groups', 'Create task group.'
    param_group :board_id
    param_group :task_group
    def create
      task_group = TaskGroup.new(task_group_params)

      if task_group.save
        render json: task_group, status: :created
      else
        render json: { errors: task_group.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/task_groups/1.json
    api :PATCH, '/boards/:board_id/task_groups/:id', 'Update task group.'
    param_group :board_id
    param_group :task_group_id
    param_group :task_group
    def update
      if @task_group.update(task_group_params)
        render json: @task_group
      else
        render json: { errors: @task_group.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /api/task_groups/1.json
    api :DELETE, '/boards/:board_id/task_groups/:id', 'Delete task group.'
    param_group :board_id
    param_group :task_group_id
    def destroy
      if @task_group.destroy
        head :no_content
      else
        render json: { errors: @task_group.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH /api/task_groups/1/move_to_position.json
    api :PATCH, '/boards/:board_id/task_groups/:id/move_to_position',
        'Move task group to a different position in the same or another board.'
    param_group :board_id
    param_group :task_group_id
    param :target_board_id, :number, desc: 'Target board ID', required: true
    param :position, :number, desc: 'New position', required: true
    def move_to_position
      if @task_group.move_to_position(params[:target_board_id].to_i,
                                      params[:position].to_i)
        render json: @task_group
      else
        render json: { errors: @task_group.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_board
      @board = Board.find(params[:board_id])
    end

    def set_task_group
      @task_group = TaskGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet,
    # only allow the white list through.
    def task_group_params
      params.require(:task_group).permit(:board_id, :id, :title)
    end
  end
end
