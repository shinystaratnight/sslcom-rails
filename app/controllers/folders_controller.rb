class FoldersController < ApplicationController
  before_filter :find_ssl_account, except: :index
  before_filter :set_ssl_slug, except: :index
  
  filter_access_to :all
  filter_access_to [
    :add_to_folder,
    :add_certificate_order,
    :add_certificate_orders,
    :destroy,
    :update
  ], attribute_check: true

  def index
    @folders = get_team_root_folders
  end

  def create
    new_params = params[:folder].merge(ssl_account_id: @ssl_account.id)
    new_params = new_params.merge(parent_id: nil) if parent_root?
    @folder = Folder.new(new_params)
    if @folder.save
      render json: { message: "Folder successfully created." }, status: :ok
    else
      render json: @folder.errors.messages, status: :unprocessable_entity
    end
  end
  
  def children
    @folders_and_cos = if params[:id] == '#'
      get_team_root_folders.order(name: :asc)
    else
      @ssl_account.folders.where(parent_id: params[:id]).order(name: :asc)
    end
    render partial: 'folder_children'
  end
  
  def update
    @node = find_node
    if @node
      case params[:update_type]
        when 'rename' then update_rename
        when 'default' then update_default
        when 'move' then update_move
      end
    else
      render json: { folder: ['Something went wrong, please try again.'] },
        status: :unprocessable_entity
    end
  end

  def destroy
    @node = find_node
    if @node && folder_node? && @node.can_destroy?
      @node.destroy
      render json: { message: "Folder successfully deleted." }, status: :ok
    else
      render json: { folder: ['This folder is archived or cannot be deleted.'] },
        status: :unprocessable_entity
    end
  end
  
  private

  def co_id?
    params[:folder] && params[:folder][:id].include?('_cert')
  end

  def find_node
    f = params[:folder]
    if f
      if co_id?
        CertificateOrder.find_by(ref: f[:id].split('_').first)
      else  
        Folder.find(f[:id])
      end
    end
  end

  def folder_node?
    @node.is_a? Folder
  end

  def co_node?
    @node.is_a? CertificateOrder
  end

  def update_rename
    if @node.update(name: params[:folder][:name])
      render json: { message: "Folder successfully renamed." }, status: :ok
    else
      render json: @node.errors.messages, status: :unprocessable_entity
    end
  end

  def update_default
    if @node.archive?
      render json: { archive: ['Archive folder cannot be set as default.'] },
        status: :unprocessable_entity
    else  
      if @node.update(default: true)
        render json: { message: "Folder successfully set as default." }, status: :ok
      else
        render json: @node.errors.messages, status: :unprocessable_entity
      end
    end
  end
  
  def update_move
    @node = find_node
    new_value = parent_root? ? nil : params[:folder][:parent_id].split('_').first
    updated = folder_node? ? @node.update(parent_id: new_value) : @node.update(folder_id: new_value)
    
    if updated
      render json: { message: "Folder successfully moved." }, status: :ok
    else
      render json: @node.errors.messages, status: :unprocessable_entity
    end
  end

  def parent_root?
    params[:parent_id] == '#' || params[:folder][:parent_id] == '#'
  end

  def get_team_root_folders
    @ssl_account.folders.roots
  end
    
  def set_ssl_slug(target_user=nil)
    if current_user && @ssl_account
      @ssl_slug ||= (@ssl_account.ssl_slug || @ssl_account.acct_number)
    end
  end
end
