class OrdersController < ApplicationController
  def create
    order = Order.new(order_params)
    if order.save
      head 200
    else
      head 400
    end
  end

  private

    def order_params
      params.require(:order).permit(:name, :phone_number, :message)
    end
end