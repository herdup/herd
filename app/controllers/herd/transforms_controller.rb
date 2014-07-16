require_dependency "herd/application_controller"

module Herd
  class TransformsController < ApplicationController
    respond_to :json
    before_action :set_transform, only: [:show, :update, :destroy]

    # GET /transform
    def index
      @transforms = Transform.all
      respond_with(@transforms, each_serializer: TransformSerializer)
    end

    # GET /transform/1
    def show
      respond_with(@transform, serializer: TransformSerializer)
    end

    # POST /transform
    def create
      @transform = Transform.new(transform_params)

      if @transform.save
        render json: @transform, serializer: TransformSerializer
      else
        render json: {error:@transform.errors}, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /transform/1
    def update
      if @transform.update(transform_params)
        render json: @transform, serializer: TransformSerializer
      else
        render json: {error:@transform.errors}, status: :unprocessable_entity
      end
    end

    # DELETE /transform/1
    def destroy
      @transform.destroy
      render nothing: true, status: 204
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_transform
        @transform = Transform.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def transform_params
        parms = params.require(:transform).permit(:options, :format, :type)
      end

  end
end
