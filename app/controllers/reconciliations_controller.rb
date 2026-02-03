class ReconciliationsController < ApplicationController
  before_action :load_data, only: [:new, :create, :show, :tab]

  def new
    @result = load_result
  end

  def upload_bank
    if params[:file].blank?
      render_upload_error('bank', 'Por favor selecciona un archivo')
      return
    end

    begin
      records = FileParsingService.parse(params[:file], source: :bank)
      store_bank_records(records)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('bank_upload', partial: 'upload_success',
              locals: { type: 'bank', count: records.size, filename: params[:file].original_filename }),
            turbo_stream.replace('reconcile_button', partial: 'reconcile_button',
              locals: { bank_count: records.size, sales_count: load_sales_records.size })
          ]
        end
        format.html { redirect_to new_reconciliation_path, notice: "#{records.size} registros de banco cargados" }
      end
    rescue FileParsingService::ParseError => e
      render_upload_error('bank', e.message)
    rescue StandardError => e
      render_upload_error('bank', "Error inesperado: #{e.message}")
    end
  end

  def upload_sales
    if params[:file].blank?
      render_upload_error('sales', 'Por favor selecciona un archivo')
      return
    end

    begin
      records = FileParsingService.parse(params[:file], source: :sales)
      store_sales_records(records)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('sales_upload', partial: 'upload_success',
              locals: { type: 'sales', count: records.size, filename: params[:file].original_filename }),
            turbo_stream.replace('reconcile_button', partial: 'reconcile_button',
              locals: { bank_count: load_bank_records.size, sales_count: records.size })
          ]
        end
        format.html { redirect_to new_reconciliation_path, notice: "#{records.size} registros de ventas cargados" }
      end
    rescue FileParsingService::ParseError => e
      render_upload_error('sales', e.message)
    rescue StandardError => e
      render_upload_error('sales', "Error inesperado: #{e.message}")
    end
  end

  def create
    bank_records = load_bank_records
    sales_records = load_sales_records

    if bank_records.empty? || sales_records.empty?
      redirect_to new_reconciliation_path, alert: 'Debes cargar ambos archivos antes de conciliar'
      return
    end

    result = ReconciliationService.reconcile(
      bank_records: bank_records,
      sales_records: sales_records
    )

    store_result(result)
    redirect_to reconciliation_path(result.id)
  end

  def show
    @result = load_result
    unless @result
      redirect_to new_reconciliation_path, alert: 'No hay resultados de conciliación'
      return
    end

    @current_tab = params[:tab] || 'matched'
  end

  def tab
    @result = load_result
    @current_tab = params[:tab] || 'matched'

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('results_table', partial: 'results_table',
          locals: { result: @result, current_tab: @current_tab })
      end
      format.html { redirect_to reconciliation_path(@result&.id, tab: @current_tab) }
    end
  end

  def reset
    clear_session_data

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('main_content', partial: 'upload_form')
      end
      format.html { redirect_to new_reconciliation_path, notice: 'Datos limpiados' }
    end
  end

  private

  def load_data
    @bank_records = load_bank_records
    @sales_records = load_sales_records
  end

  def render_upload_error(type, message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("#{type}_upload", partial: 'upload_error',
          locals: { type: type, message: message })
      end
      format.html { redirect_to new_reconciliation_path, alert: message }
    end
  end
end
