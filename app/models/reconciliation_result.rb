# Plain Old Ruby Object for reconciliation results
class ReconciliationResult
  attr_accessor :id, :matched_pairs, :unmatched_bank, :unmatched_sales,
                :total_bank, :total_sales, :total_matched,
                :exact_matches_count, :fuzzy_matches_count,
                :bank_total_amount, :sales_total_amount,
                :matched_amount, :unmatched_bank_amount, :unmatched_sales_amount,
                :created_at

  def initialize(attrs = {})
    @id = attrs[:id] || SecureRandom.uuid
    @matched_pairs = attrs[:matched_pairs] || []
    @unmatched_bank = attrs[:unmatched_bank] || []
    @unmatched_sales = attrs[:unmatched_sales] || []
    @total_bank = attrs[:total_bank] || 0
    @total_sales = attrs[:total_sales] || 0
    @total_matched = attrs[:total_matched] || 0
    @exact_matches_count = attrs[:exact_matches_count] || 0
    @fuzzy_matches_count = attrs[:fuzzy_matches_count] || 0
    @bank_total_amount = attrs[:bank_total_amount] || 0.0
    @sales_total_amount = attrs[:sales_total_amount] || 0.0
    @matched_amount = attrs[:matched_amount] || 0.0
    @unmatched_bank_amount = attrs[:unmatched_bank_amount] || 0.0
    @unmatched_sales_amount = attrs[:unmatched_sales_amount] || 0.0
    @created_at = attrs[:created_at] || Time.current
  end

  def match_rate
    return 0.0 if total_bank.zero? && total_sales.zero?
    total_records = [total_bank, total_sales].max
    (total_matched.to_f / total_records * 100).round(1)
  end

  def unmatched_bank_count
    unmatched_bank.size
  end

  def unmatched_sales_count
    unmatched_sales.size
  end

  def difference
    bank_total_amount - sales_total_amount
  end

  def to_h
    {
      id: id,
      matched_pairs: matched_pairs.map(&:to_h),
      unmatched_bank: unmatched_bank.map(&:to_h),
      unmatched_sales: unmatched_sales.map(&:to_h),
      total_bank: total_bank,
      total_sales: total_sales,
      total_matched: total_matched,
      exact_matches_count: exact_matches_count,
      fuzzy_matches_count: fuzzy_matches_count,
      bank_total_amount: bank_total_amount,
      sales_total_amount: sales_total_amount,
      matched_amount: matched_amount,
      unmatched_bank_amount: unmatched_bank_amount,
      unmatched_sales_amount: unmatched_sales_amount,
      created_at: created_at.iso8601
    }
  end

  def self.from_h(hash)
    return nil unless hash
    hash = hash.transform_keys(&:to_sym)
    new(
      id: hash[:id],
      matched_pairs: (hash[:matched_pairs] || []).map { |p| MatchedPair.from_h(p) },
      unmatched_bank: (hash[:unmatched_bank] || []).map { |r| TransactionRecord.from_h(r) },
      unmatched_sales: (hash[:unmatched_sales] || []).map { |r| TransactionRecord.from_h(r) },
      total_bank: hash[:total_bank],
      total_sales: hash[:total_sales],
      total_matched: hash[:total_matched],
      exact_matches_count: hash[:exact_matches_count],
      fuzzy_matches_count: hash[:fuzzy_matches_count],
      bank_total_amount: hash[:bank_total_amount],
      sales_total_amount: hash[:sales_total_amount],
      matched_amount: hash[:matched_amount],
      unmatched_bank_amount: hash[:unmatched_bank_amount],
      unmatched_sales_amount: hash[:unmatched_sales_amount],
      created_at: hash[:created_at] ? Time.parse(hash[:created_at]) : Time.current
    )
  end
end
