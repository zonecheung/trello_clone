class WelcomeController < ApplicationController
  before_action :reload_if_no_param, only: %i[index]

  def index; end

  private

  def reload_if_no_param
    return unless params[:board_id].blank?

    board = Board.recently_updated.first
    redirect_to root_url(board_id: board.id)
  end
end
