class WelcomeController < ApplicationController
  before_action :reload_if_no_param, only: %i[index]

  def index
    session[:board_id] = params[:board_id] unless params[:board_id].blank?
    @board_id = session[:board_id]
  end

  private

  def reload_if_no_param
    return unless params[:board_id].blank? && session[:board_id].blank?

    # NOTE: This is just the quick way to return the last updated board.
    board = Board.recently_updated.first
    redirect_to root_url(board_id: board.try(:id) || 0)
  end
end
