require_dependency "herd/application_controller"

module Herd
  class AssetsController < ApplicationController
    respond_to :json
    before_action :set_asset, only: [:show, :edit, :update, :destroy]

    def transform
      set_asset
      transforms = params[:options].split(';')
      child = @asset
      transforms.each { |t| child = child.t t }
       
      respond_to do |format|
        format.json { render json: [child], each_serializer: AssetSerializer  }
        format.any { redirect_to child.file_url }
      end
    end

    # GET /assets
    def index
      if params[:ids]
        @assets = Asset.where(id:params[:ids])
      else
        @assets = Asset.all
      end
      respond_to do |format|
        format.json { render json: @assets,  each_serializer: AssetSerializer  }
        format.html
      end
    end

    # GET /assets/1
    def show
      respond_with(@asset, serializer: AssetSerializer)
    end

    # POST /assets
    def create
      # if asset_params[:file]
        @asset = Asset.new(asset_params)
      # elsif asset_params.keys.sort == %s{transform_id parent_id}.sort
        # binding.pry
      # end

      if @asset.save
        render json: [@asset], each_serializer: AssetSerializer
      else
        render json: @asset.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /assets/1
    def update
      if @asset.update(asset_params)
        respond_with(@asset, serializer: AssetSerializer)
      else
        render :edit
      end
    end

    # DELETE /assets/1
    def destroy
      @asset.destroy
      render nothing: true, status: 204
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_asset
        @asset = Asset.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def asset_params
        params.require(:asset).permit(:file, :file_name, :parent_asset_id, :transform_id)
      end
  end
end
