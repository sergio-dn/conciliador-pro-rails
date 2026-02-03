# Plain Old Ruby Object for transaction records
class TransactionRecord
  attr_accessor :id, :date, :amount, :reference, :description, :source, :original_data

  def initialize(attrs = {})
    @id = attrs[:id] || SecureRandom.uuid
    @date = parse_date(attrs[:date])
    @amount = parse_amount(attrs[:amount])
    @reference = normalize_reference(attrs[:reference])
    @description = attrs[:description].to_s.strip
    @source = attrs[:source] # :bank or :sales
    @original_data = attrs[:original_data] || {}
  end

  def to_h
    {
      id: id,
      date: date&.iso8601,
      amount: amount,
      reference: reference,
      description: description,
      source: source,
      original_data: original_data
    }
  end

  def self.from_h(hash)
    hash = hash.transform_keys(&:to_sym)
    new(
      id: hash[:id],
      date: hash[:date],
      amount: hash[:amount],
      reference: hash[:reference],
      description: hash[:description],
      source: hash[:source]&.to_sym,
      original_data: hash[:original_data]
    )
  end

  private

  def parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)

    # Try various date formats
    formats = ['%Y-%m-%d', '%d/%m/%Y', '%m/%d/%Y', '%d-%m-%Y', '%Y/%m/%d']
    formats.each do |fmt|
      return Date.strptime(value.to_s, fmt)
    rescue ArgumentError
      next
    end

    # Try chronic parsing
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_amount(value)
    return 0.0 if value.blank?
    return value.to_f if value.is_a?(Numeric)

    # Remove currency symbols and normalize
    cleaned = value.to_s
                   .gsub(/[^0-9.,\-]/, '')
                   .gsub(/\.(?=.*\.)/, '')  # Remove all dots except last
                   .gsub(',', '.')           # Convert comma to dot

    cleaned.to_f.abs
  rescue
    0.0
  end

  def normalize_reference(value)
    return '' if value.blank?
    value.to_s.strip.upcase.gsub(/\s+/, ' ')
  end
end
