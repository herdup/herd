require_dependency "herd/application_controller"

module Herd
  class PagesController < ApplicationController
    respond_to :json
    before_action :set_page, only: [:show, :edit, :update, :destroy]

    def index
      @pages = Page.where(params.slice(:path))

      respond_to do |format|
        format.json { render json: @pages,  each_serializer: PageSerializer  }
        format.html
      end
    end

    def create
      @page = Page.new(pages_params)
      if @page.save
        render json: @page, serializer: PageSerializer
      else
        render json: @page.errors, status: :unprocessable_entity
      end
    end

    def pages_params
      params.require(:page).permit(:path)
    end
    def set_page
      @page = Page.find params[:id]
    end
  end
end
