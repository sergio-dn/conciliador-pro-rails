# Plain Old Ruby Object for matched transaction pairs
class MatchedPair
  attr_accessor :id, :bank_record, :sales_record, :match_type, :confidence,
                :amount_diff, :date_diff, :reference_match

  MATCH_TYPES = {
    exact: 'Exacto',
    fuzzy: 'Aproximado'
  }.freeze

  def initialize(attrs = {})
    @id = attrs[:id] || SecureRandom.uuid
    @bank_record = attrs[:bank_record]
    @sales_record = attrs[:sales_record]
    @match_type = attrs[:match_type] || :fuzzy
    @confidence = attrs[:confidence] || 0.0
    @amount_diff = attrs[:amount_diff] || 0.0
    @date_diff = attrs[:date_diff] || 0
    @reference_match = attrs[:reference_match] || false
  end

  def match_type_label
    MATCH_TYPES[@match_type.to_sym] || 'Desconocido'
  end

  def confidence_percentage
    (confidence * 100).round(1)
  end

  def exact?
    match_type.to_sym == :exact
  end

  def to_h
    {
      id: id,
      bank_record: bank_record&.to_h,
      sales_record: sales_record&.to_h,
      match_type: match_type,
      confidence: confidence,
      amount_diff: amount_diff,
      date_diff: date_diff,
      reference_match: reference_match
    }
  end

  def self.from_h(hash)
    hash = hash.transform_keys(&:to_sym)
    new(
      id: hash[:id],
      bank_record: hash[:bank_record] ? TransactionRecord.from_h(hash[:bank_record]) : nil,
      sales_record: hash[:sales_record] ? TransactionRecord.from_h(hash[:sales_record]) : nil,
      match_type: hash[:match_type]&.to_sym,
      confidence: hash[:confidence],
      amount_diff: hash[:amount_diff],
      date_diff: hash[:date_diff],
      reference_match: hash[:reference_match]
    )
  end
end
