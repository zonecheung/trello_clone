module Api
  class BoardsController < ApplicationController
    before_action :set_board, only: %i[update destroy]

    # GET /api/boards.json
    def index
      render json: Board.all
    end

    # GET /api/boards/1.json
    def show
      @board = Board.includes(task_groups: :tasks).where(id: params[:id]).first
      @no_task_groups = params[:no_task_groups] == 'true'
    end

    # POST /api/boards.json
    def create
      board = Board.new(board_params)

      if board.save
        render json: board, status: :created
      else
        render json: { errors: board.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/boards/1.json
    def update
      if @board.update(board_params)
        render json: @board
      else
        render json: { errors: @board.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /api/boards/1.json
    def destroy
      if @board.destroy
        head :no_content
      else
        render json: { errors: @board.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_board
      @board = Board.find(params[:id])
    end

    # Never trust parameters from the scary internet,
    # only allow the white list through.
    def board_params
      params.require(:board).permit(:id, :title)
    end
  end
end
