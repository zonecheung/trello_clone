module Api
  class BoardsController < ApplicationController
    before_action :set_board, only: %i[update destroy]
    before_action :set_no_task_groups, only: %i[index show latest]

    # GET /api/boards.json
    api :GET, '/boards', 'Retrieve recently updated boards.'
    def index
      @boards = Board.includes(task_groups: :tasks).recently_updated
    end

    def_param_group :board_id do
      param :id, :number, desc: 'Board ID', required: true
    end

    # GET /api/boards/1.json
    api :GET, '/boards/:id', 'Retrieve a board based on ID.'
    param_group :board_id
    def show
      @board = Board.includes(task_groups: :tasks).where(id: params[:id]).first
    end

    def_param_group :board do
      param :board, Hash, desc: 'Board info', required: true do
        param :title, String, desc: 'Board title', required: true
      end
    end

    # POST /api/boards.json
    api :POST, '/boards', 'Create board.'
    param_group :board
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
    api :PATCH, '/boards/:id', 'Update board.'
    param_group :board_id
    param_group :board
    def update
      if @board.update(board_params)
        render json: @board
      else
        render json: { errors: @board.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /api/boards/1.json
    api :DELETE, '/boards/:id', 'Delete board.'
    param_group :board_id
    def destroy
      if @board.destroy
        head :no_content
      else
        render json: { errors: @board.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # GET /api/boards/latest.json
    api :GET, '/boards/latest', 'Retrieve latest board.'
    def latest
      @board = Board.includes(task_groups: :tasks).recently_updated.first
      render 'show'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_board
      @board = Board.find(params[:id])
    end

    def set_no_task_groups
      @no_task_groups = params[:no_task_groups] == 'true'
    end

    # Never trust parameters from the scary internet,
    # only allow the white list through.
    def board_params
      params.require(:board).permit(:id, :title)
    end
  end
end
