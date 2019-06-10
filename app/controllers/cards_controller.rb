class CardsController < ApplicationController
  expose :card

  def show
    render json: card
  end

  def create
    if card.save
      render json: card
    else
      head 400
    end
  end

  private

  def cards_params
    params.require(:card).permit(:name, :width, :height, :background_url, 
                                 images_attributes: [:name, :mediafile_url, :width, :height, :x, :y],
                                 textboxes_attributes: [:name, :width, :height, :x, :y])
  end
end