require 'csv'
require 'roo'

# Service for parsing CSV and Excel files
class FileParsingService
  class ParseError < StandardError; end

  attr_reader :headers, :rows, :detected_columns

  def initialize(file, source:)
    @file = file
    @source = source
    @headers = []
    @rows = []
    @detected_columns = {}
  end

  def parse
    extension = File.extname(@file.original_filename).downcase

    case extension
    when '.csv'
      parse_csv
    when '.xlsx'
      parse_xlsx
    when '.xls'
      parse_xls
    else
      raise ParseError, "Formato no soportado: #{extension}"
    end

    detect_columns
    build_records
  end

  private

  def parse_csv
    content = @file.read
    # Try to detect encoding
    content = content.force_encoding('UTF-8')
    content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')

    # Detect delimiter
    delimiter = detect_delimiter(content)

    parsed = CSV.parse(content, col_sep: delimiter, liberal_parsing: true)
    return if parsed.empty?

    @headers = parsed.first.map { |h| h.to_s.strip }
    @rows = parsed[1..] || []
  rescue CSV::MalformedCSVError => e
    raise ParseError, "Error al parsear CSV: #{e.message}"
  end

  def parse_xlsx
    spreadsheet = Roo::Excelx.new(@file.tempfile.path)
    parse_spreadsheet(spreadsheet)
  rescue StandardError => e
    raise ParseError, "Error al parsear XLSX: #{e.message}"
  end

  def parse_xls
    spreadsheet = Roo::Excel.new(@file.tempfile.path)
    parse_spreadsheet(spreadsheet)
  rescue StandardError => e
    raise ParseError, "Error al parsear XLS: #{e.message}"
  end

  def parse_spreadsheet(spreadsheet)
    sheet = spreadsheet.sheet(0)
    return if sheet.last_row.nil? || sheet.last_row < 1

    @headers = sheet.row(1).map { |h| h.to_s.strip }
    @rows = (2..sheet.last_row).map { |i| sheet.row(i) }
  end

  def detect_delimiter(content)
    first_lines = content.lines.first(5).join
    delimiters = [',', ';', "\t", '|']

    counts = delimiters.map do |d|
      [d, first_lines.count(d)]
    end.to_h

    counts.max_by { |_, v| v }.first
  end

  def detect_columns
    sample_rows = @rows.first(5)
    @detected_columns = ColumnDetectionService.detect_with_sample(@headers, sample_rows)
  end

  def build_records
    @rows.map do |row|
      TransactionRecord.new(
        date: extract_value(row, :date),
        amount: extract_value(row, :amount),
        reference: extract_value(row, :reference),
        description: extract_value(row, :description),
        source: @source,
        original_data: build_original_data(row)
      )
    end.reject { |r| r.amount.zero? && r.date.nil? }
  end

  def extract_value(row, column_type)
    column_info = @detected_columns[column_type]
    return nil unless column_info

    row[column_info[:index]]
  end

  def build_original_data(row)
    @headers.each_with_index.map { |h, i| [h, row[i]] }.to_h
  end

  def self.parse(file, source:)
    service = new(file, source: source)
    service.parse
  end
end
