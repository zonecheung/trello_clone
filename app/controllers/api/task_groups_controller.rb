module Api
  class TaskGroupsController < ApplicationController
    before_action :set_board
    before_action :set_task_group,
                  only: %i[show update destroy move_to_position]

    # GET /api/task_groups.json
    def index
      render json: @board.task_groups
    end

    # GET /api/task_groups/1.json
    def show
      render json: @task_group
    end

    # POST /api/task_groups.json
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
    def update
      if @task_group.update(task_group_params)
        render json: @task_group
      else
        render json: { errors: @task_group.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /api/task_groups/1.json
    def destroy
      if @task_group.destroy
        head :no_content
      else
        render json: { errors: @task_group.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH /api/task_groups/1/move_to_position.json
    def move_to_position
      if @task_group.move_to_position(params[:board_id].to_i,
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
