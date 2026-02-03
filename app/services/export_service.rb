require 'csv'

# Service for exporting reconciliation results to CSV
class ExportService
  def initialize(result, export_type:)
    @result = result
    @export_type = export_type.to_sym
  end

  def generate
    case @export_type
    when :matched
      generate_matched_csv
    when :unmatched_bank
      generate_unmatched_bank_csv
    when :unmatched_sales
      generate_unmatched_sales_csv
    when :all
      generate_full_report_csv
    else
      raise ArgumentError, "Tipo de exportación no válido: #{@export_type}"
    end
  end

  def filename
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    case @export_type
    when :matched
      "conciliados_#{timestamp}.csv"
    when :unmatched_bank
      "no_conciliados_banco_#{timestamp}.csv"
    when :unmatched_sales
      "no_conciliados_ventas_#{timestamp}.csv"
    when :all
      "reporte_completo_#{timestamp}.csv"
    end
  end

  private

  def generate_matched_csv
    CSV.generate(headers: true) do |csv|
      csv << [
        'ID Match', 'Tipo Match', 'Confianza',
        'Banco - Fecha', 'Banco - Monto', 'Banco - Referencia', 'Banco - Descripción',
        'Ventas - Fecha', 'Ventas - Monto', 'Ventas - Referencia', 'Ventas - Descripción',
        'Diferencia Monto', 'Diferencia Días'
      ]

      @result.matched_pairs.each do |pair|
        csv << [
          pair.id,
          pair.match_type_label,
          "#{pair.confidence_percentage}%",
          pair.bank_record.date,
          format_currency(pair.bank_record.amount),
          pair.bank_record.reference,
          pair.bank_record.description,
          pair.sales_record.date,
          format_currency(pair.sales_record.amount),
          pair.sales_record.reference,
          pair.sales_record.description,
          format_currency(pair.amount_diff),
          pair.date_diff
        ]
      end
    end
  end

  def generate_unmatched_bank_csv
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Fecha', 'Monto', 'Referencia', 'Descripción']

      @result.unmatched_bank.each do |record|
        csv << [
          record.id,
          record.date,
          format_currency(record.amount),
          record.reference,
          record.description
        ]
      end
    end
  end

  def generate_unmatched_sales_csv
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Fecha', 'Monto', 'Referencia', 'Descripción']

      @result.unmatched_sales.each do |record|
        csv << [
          record.id,
          record.date,
          format_currency(record.amount),
          record.reference,
          record.description
        ]
      end
    end
  end

  def generate_full_report_csv
    CSV.generate(headers: true) do |csv|
      # Summary section
      csv << ['=== RESUMEN DE CONCILIACIÓN ===']
      csv << ['Fecha del reporte', Time.current.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['Total registros banco', @result.total_bank]
      csv << ['Total registros ventas', @result.total_sales]
      csv << ['Total conciliados', @result.total_matched]
      csv << ['Tasa de conciliación', "#{@result.match_rate}%"]
      csv << ['Matches exactos', @result.exact_matches_count]
      csv << ['Matches aproximados', @result.fuzzy_matches_count]
      csv << ['Monto total banco', format_currency(@result.bank_total_amount)]
      csv << ['Monto total ventas', format_currency(@result.sales_total_amount)]
      csv << ['Diferencia', format_currency(@result.difference)]
      csv << []

      # Matched section
      csv << ['=== TRANSACCIONES CONCILIADAS ===']
      csv << [
        'Tipo Match', 'Confianza',
        'Banco Fecha', 'Banco Monto', 'Banco Ref',
        'Ventas Fecha', 'Ventas Monto', 'Ventas Ref',
        'Dif Monto'
      ]
      @result.matched_pairs.each do |pair|
        csv << [
          pair.match_type_label,
          "#{pair.confidence_percentage}%",
          pair.bank_record.date,
          format_currency(pair.bank_record.amount),
          pair.bank_record.reference,
          pair.sales_record.date,
          format_currency(pair.sales_record.amount),
          pair.sales_record.reference,
          format_currency(pair.amount_diff)
        ]
      end
      csv << []

      # Unmatched bank
      csv << ['=== NO CONCILIADOS - BANCO ===']
      csv << ['Fecha', 'Monto', 'Referencia', 'Descripción']
      @result.unmatched_bank.each do |record|
        csv << [record.date, format_currency(record.amount), record.reference, record.description]
      end
      csv << []

      # Unmatched sales
      csv << ['=== NO CONCILIADOS - VENTAS ===']
      csv << ['Fecha', 'Monto', 'Referencia', 'Descripción']
      @result.unmatched_sales.each do |record|
        csv << [record.date, format_currency(record.amount), record.reference, record.description]
      end
    end
  end

  def format_currency(amount)
    "$#{format('%.2f', amount)}"
  end

  def self.generate(result, export_type:)
    service = new(result, export_type: export_type)
    [service.generate, service.filename]
  end
end
