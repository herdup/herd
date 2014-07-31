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
        format.json { render json: child, serializer: AssetSerializer  }
        format.any { redirect_to child.file_url }
      end
    end

    # GET /assets
    def index
      @assets = scoped_assets

      respond_to do |format|
        format.json { render json: @assets,  each_serializer: AssetSerializer  }
        format.html
      end
    end

    # GET /assets/1
    def show
      respond_to do |format|
        format.json {render json: @asset, serializer: AssetSerializer}
        format.html
      end

    end

    # POST /assets
    def create

      if transform_params.present?
        parent = Asset.find params[:asset][:parent_asset_id]
        @transform = parent.class.default_transform.where_t(transform_params).first_or_create
        params[:asset][:transform_id] = @transform.id
      end
      # if asset_params[:file]
        @asset = Asset.new(asset_params)
      # elsif asset_params.keys.sort == %s{transform_id parent_id}.sort
        # binding.pry
      # end

      if @asset.save
        render json: @asset, serializer: AssetSerializer
      else
        render json: @asset.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /assets/1
    def update
      if @asset.update(asset_params)
        if metadata_params.present?
          @asset.meta = metadata_params
          @asset.save if @asset.meta_changed?
        end
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

    def scoped_assets
      assets = Asset.order(:position)
      if params[:assetable_type].present?
        assets = assets.where(params.slice(:assetable_type,:assetable_id))
      elsif params[:parent_id].present?
        assets = assets.where(parent_asset_id:params[:parent_id])
      elsif params[:ids].present?
        assets = assets.where(id:params[:id])
      end
      assets
    end

    private


      # Use callbacks to share common setup or constraints between actions.
      def set_asset
        @asset = Asset.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def asset_params
        params.require(:asset).permit(:file, :file_name, :parent_asset_id, :transform_id, :assetable_type, :assetable_id, :position)
      end
      def metadata_params
        params.require(:asset).require(:metadata).permit!.symbolize_keys
      end
      def transform_params
        params.require(:asset).require(:transform).permit(:type, :options, :format) if params[:asset][:transform].present?
      end
  end
end
