class FoldersController < ApplicationController
  before_filter :find_ssl_account, except: :index
  before_filter :set_ssl_slug, except: :index
  before_filter :find_folder, only: [
    :update,
    :destroy,
    :add_certificate_order,
    :add_certificate_orders
  ]

  filter_access_to :all
  filter_access_to [
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
      render json: { folder_id: @folder.id }, status: :ok
    else
      render json: @folder.errors.messages, status: :unprocessable_entity
    end
  end
  
  def children
    @folders = if params[:id] == '#'
      get_team_root_folders.order(name: :asc)
    else
      @ssl_account.folders.where(parent_id: params[:id]).order(name: :asc)
    end
    @tree_type = params[:tree_type]
    render partial: 'folder_children'
  end

  def reset_to_system
    Folder.reset_to_system_folders(@ssl_account)
    redirect_to folders_path(@ssl_slug), 
      notice: "Certificates have been reset to system folders."
  end
  
  def update
    if @folder
      case params[:update_type]
        when 'rename' then update_rename
        when 'default' then update_default
        when 'move' then update_move
      end
    else
      render_try_again_error
    end
  end

  def destroy
    if @folder && @folder.can_destroy?
      if @folder.destroy
        render json: { message: "Folder successfully deleted." }, status: :ok
      else
        render_try_again_error
      end
    else
      render json: { folder: ['System folders cannot be deleted.'] },
        status: :unprocessable_entity
    end
  end

  def add_certificate_order
    if @folder
      co = CertificateOrder.find_by(ref: params[:folder][:certificate_order_id])
    end

    if @folder && co
      CertificateOrder.record_timestamps = false
      if co.update(folder_id: @folder.id)
        CertificateOrder.record_timestamps = true
        render json: { message: "Certificate has been successfully moved." }, status: :ok
      else
        render_try_again_error
      end
    else
      render_try_again_error
    end 
  end

  def add_certificate_orders
    co_refs = params[:folder][:folder_certificate_order_ids].split(',')
    if @folder && co_refs.any?
      certificate_orders = CertificateOrder.where(ref: co_refs)
    end
    if @folder && certificate_orders && certificate_orders.any?
      certificate_orders.update_all(folder_id: @folder.id)
      if certificate_orders.map(&:folder_id).uniq == [@folder.id]
        flash[:notice] = "Certifiate Orders #{certificate_orders.map(&:ref).uniq.join(', ')} were successfully moved to folder #{@folder.name}"
      else
        flash[:error] = "Something went wrong, please try again."
      end
    else
      flash[:error] = "Please select at least one certificate order to place in folder."
    end
    redirect_to certificate_orders_path(@ssl_slug, folders: true)
  end

  private

  def render_try_again_error
    render json: { folder: ['Something went wrong, please try again.'] },
      status: :unprocessable_entity
  end

  def find_folder
    @folder = Folder.find(params[:id])
  end

  def update_rename
    if @folder && @folder.can_destroy?
      if @folder.update(name: params[:folder][:name])
        render json: { message: "Folder successfully renamed." }, status: :ok
      else
        render json: @folder.errors.messages, status: :unprocessable_entity
      end
    else
      render json: { folder: ['System folders cannot be renamed.'] },
        status: :unprocessable_entity
    end
  end

  def update_default
    if @folder && @folder.can_destroy?
      if @folder.update(default: true)
        @folder.ssl_account.update(default_folder_id: @folder.id)
        render json: { message: "Folder successfully set as default." }, status: :ok
      else
        render json: @folder.errors.messages, status: :unprocessable_entity
      end
    else  
      render json: { default: ['System folders cannot be set as default folder'] },
        status: :unprocessable_entity
    end
  end
  
  def update_move
    new_value = parent_root? ? nil : params[:folder][:parent_id]
    if @folder.update(parent_id: new_value)
      render json: { message: "Folder successfully moved." }, status: :ok
    else
      render json: @folder.errors.messages, status: :unprocessable_entity
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
