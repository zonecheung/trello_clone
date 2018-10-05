module Api
  class TasksController < ApplicationController
    before_action :set_board_and_task_group
    before_action :set_task,
                  only: %i[show update destroy move_to_position]

    # GET /api/tasks.json
    def index
      render json: @task_group.tasks
    end

    # GET /api/tasks/1.json
    def show
      render json: @task
    end

    # POST /api/tasks.json
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
    def update
      if @task.update(task_params)
        render json: @task
      else
        render json: { errors: @task.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /api/tasks/1.json
    def destroy
      if @task.destroy
        head :no_content
      else
        render json: { errors: @task.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH /api/tasks/1/move_to_position.json
    def move_to_position
      if @task.move_to_position(params[:board_id].to_i,
                                params[:task_group_id].to_i,
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
