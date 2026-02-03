# Service for auto-detecting column types in uploaded files
class ColumnDetectionService
  AMOUNT_PATTERNS = %w[
    monto valor pago importe total amount value payment
    debito credito cargo abono deposito retiro
  ].freeze

  DATE_PATTERNS = %w[
    fecha date dia day fec
  ].freeze

  REFERENCE_PATTERNS = %w[
    ref referencia reference doc documento document
    num numero number obs observacion nota note
    transaccion operacion comprobante voucher factura invoice
  ].freeze

  DESCRIPTION_PATTERNS = %w[
    descripcion description concepto detalle detail desc
    movimiento glosa comercio nombre name
  ].freeze

  def initialize(headers)
    @headers = headers.map { |h| h.to_s.strip.downcase }
    @original_headers = headers
  end

  def detect
    {
      amount: detect_column(AMOUNT_PATTERNS),
      date: detect_column(DATE_PATTERNS),
      reference: detect_column(REFERENCE_PATTERNS),
      description: detect_column(DESCRIPTION_PATTERNS)
    }
  end

  def detect_column(patterns)
    @headers.each_with_index do |header, index|
      patterns.each do |pattern|
        if header.include?(pattern)
          return {
            index: index,
            name: @original_headers[index]
          }
        end
      end
    end
    nil
  end

  def self.detect(headers)
    new(headers).detect
  end

  # Detect best columns from sample data
  def self.detect_with_sample(headers, sample_rows)
    detected = new(headers).detect

    # If amount not detected by name, try to find numeric column
    if detected[:amount].nil? && sample_rows.any?
      headers.each_with_index do |_header, index|
        values = sample_rows.map { |row| row[index] }
        if values.all? { |v| numeric?(v) }
          detected[:amount] = { index: index, name: headers[index] }
          break
        end
      end
    end

    # If date not detected by name, try to find date column
    if detected[:date].nil? && sample_rows.any?
      headers.each_with_index do |_header, index|
        values = sample_rows.map { |row| row[index] }
        if values.all? { |v| date_like?(v) }
          detected[:date] = { index: index, name: headers[index] }
          break
        end
      end
    end

    detected
  end

  def self.numeric?(value)
    return false if value.nil?
    cleaned = value.to_s.gsub(/[^0-9.,\-]/, '')
    Float(cleaned.gsub(',', '.'))
    true
  rescue ArgumentError, TypeError
    false
  end

  def self.date_like?(value)
    return false if value.nil?
    str = value.to_s
    # Check common date patterns
    str.match?(%r{\d{1,4}[-/]\d{1,2}[-/]\d{1,4}})
  end
end
