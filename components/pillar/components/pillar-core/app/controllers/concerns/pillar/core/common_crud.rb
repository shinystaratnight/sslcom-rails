module Pillar
  module Core
    module CommonCrud
      include Pagy::Backend
      extend ActiveSupport::Concern

      included do
        helper_method :resource_name, :collection_path, :resource_path
        before_action :set_resources, only: [:index]
        before_action :set_resource, only: [:show, :edit, :update, :destroy]
      end

      def index
        respond_with(@resources)
      end

      def show
        respond_with(@resource)
      end

      def edit
        respond_with(@resource)
      end

      def new
        @resource = resource_class.new
        yield @resource if block_given?
        respond_with @resource
      end

      def create
        @resource = resource_scope.new(permitted_attributes)
        yield @resource if block_given?

        if @resource.save
          flash[:success] = "The #{resource_name} has been created."
        else
          flash[:error] = "The #{resource_name} could not be created."
        end

        respond_with @resource, location: collection_path
      end

      def update
        yield @resource if block_given?

        if @resource.update(permitted_attributes)
          flash[:success] = "The #{resource_name} has been updated."
        else
          flash[:error] = "The #{resource_name} could not be updated."
        end

        respond_with @resource, location: collection_path
      end

      def destroy
        if @resource.destroy
          flash[:success] = "The #{resource_name} has been removed."
        else
          flash[:error] = "The #{resource_name} could not be removed."
        end

        respond_with @resource, location: collection_path
      end

      private

      ## OVERIDE REQUIRED
      def resource_class
        raise NotImplementedError
      end

      def set_resource
        @query = resource_class
        yield @query if block_given?
        @resource = @query.find(params[:id])
      end

      def set_resources
        @query = resource_scope
        yield @query if block_given?
        @q = @query.ransack(params[:q])
        @pagy, @resources = pagy(@q.result(distinct: true))
      end

      def resource_scope
        resource_class
      end

      def permitted_attributes
        raise NotImplementedError
      end

      ## OVERRIDE WHEN NECCESSARY

      def namespace
        []
      end

      def resource_name
        resource_class.name.demodulize.underscore.humanize.downcase
      end

      def collection_path
        namespace << resource_class.model_name.route_key.to_sym
      end

      def resource_path
        namespace << resource_class.model_name.singular_route_key.to_sym
      end
    end
  end
end
