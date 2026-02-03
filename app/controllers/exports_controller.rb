class ExportsController < ApplicationController
  def create
    result = load_result

    unless result
      redirect_to new_reconciliation_path, alert: 'No hay resultados para exportar'
      return
    end

    export_type = params[:type] || 'all'
    csv_content, filename = ExportService.generate(result, export_type: export_type)

    send_data csv_content,
              filename: filename,
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end
end
