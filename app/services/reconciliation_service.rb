# Service for reconciling bank and sales transactions
# Uses 2-pass algorithm: exact match, then fuzzy match
class ReconciliationService
  # Configurable tolerances
  AMOUNT_TOLERANCE = 1.0      # ±$1
  DATE_TOLERANCE_DAYS = 3     # ±3 days

  def initialize(bank_records:, sales_records:, amount_tolerance: 1.0, date_tolerance_days: 3)
    @bank_records = bank_records
    @sales_records = sales_records
    @amount_tolerance = amount_tolerance
    @date_tolerance_days = date_tolerance_days
    @matched_pairs = []
    @matched_bank_ids = Set.new
    @matched_sales_ids = Set.new
  end

  def reconcile
    # Pass 1: Exact matches (reference + amount + date)
    exact_match_pass

    # Pass 2: Fuzzy matches (amount + date with tolerance)
    fuzzy_match_pass

    build_result
  end

  private

  def exact_match_pass
    unmatched_bank = @bank_records.reject { |r| @matched_bank_ids.include?(r.id) }
    unmatched_sales = @sales_records.reject { |r| @matched_sales_ids.include?(r.id) }

    unmatched_bank.each do |bank_record|
      next if @matched_bank_ids.include?(bank_record.id)
      next if bank_record.reference.blank?

      match = find_exact_match(bank_record, unmatched_sales)
      next unless match

      create_match(bank_record, match, :exact, 1.0)
    end
  end

  def fuzzy_match_pass
    unmatched_bank = @bank_records.reject { |r| @matched_bank_ids.include?(r.id) }
    unmatched_sales = @sales_records.reject { |r| @matched_sales_ids.include?(r.id) }

    unmatched_bank.each do |bank_record|
      next if @matched_bank_ids.include?(bank_record.id)

      match, confidence = find_fuzzy_match(bank_record, unmatched_sales)
      next unless match

      create_match(bank_record, match, :fuzzy, confidence)
    end
  end

  def find_exact_match(bank_record, candidates)
    candidates.find do |sales_record|
      next if @matched_sales_ids.include?(sales_record.id)
      next if sales_record.reference.blank?

      reference_matches?(bank_record.reference, sales_record.reference) &&
        amounts_equal?(bank_record.amount, sales_record.amount) &&
        dates_equal?(bank_record.date, sales_record.date)
    end
  end

  def find_fuzzy_match(bank_record, candidates)
    best_match = nil
    best_confidence = 0.0

    candidates.each do |sales_record|
      next if @matched_sales_ids.include?(sales_record.id)

      confidence = calculate_confidence(bank_record, sales_record)
      next if confidence < 0.6 # Minimum threshold

      if confidence > best_confidence
        best_confidence = confidence
        best_match = sales_record
      end
    end

    [best_match, best_confidence]
  end

  def calculate_confidence(bank, sales)
    score = 0.0
    weights = { amount: 0.5, date: 0.3, reference: 0.2 }

    # Amount similarity (within tolerance)
    if amounts_within_tolerance?(bank.amount, sales.amount)
      amount_diff = (bank.amount - sales.amount).abs
      amount_score = 1.0 - (amount_diff / @amount_tolerance)
      score += weights[:amount] * [amount_score, 0].max
    end

    # Date similarity (within tolerance)
    if bank.date && sales.date
      day_diff = (bank.date - sales.date).abs.to_i
      if day_diff <= @date_tolerance_days
        date_score = 1.0 - (day_diff.to_f / @date_tolerance_days)
        score += weights[:date] * date_score
      end
    end

    # Reference similarity (partial match)
    if bank.reference.present? && sales.reference.present?
      if reference_matches?(bank.reference, sales.reference)
        score += weights[:reference]
      elsif partial_reference_match?(bank.reference, sales.reference)
        score += weights[:reference] * 0.5
      end
    end

    score
  end

  def reference_matches?(ref1, ref2)
    ref1.to_s.strip.upcase == ref2.to_s.strip.upcase
  end

  def partial_reference_match?(ref1, ref2)
    r1 = ref1.to_s.strip.upcase
    r2 = ref2.to_s.strip.upcase
    r1.include?(r2) || r2.include?(r1)
  end

  def amounts_equal?(amount1, amount2)
    (amount1 - amount2).abs < 0.01
  end

  def amounts_within_tolerance?(amount1, amount2)
    (amount1 - amount2).abs <= @amount_tolerance
  end

  def dates_equal?(date1, date2)
    return false unless date1 && date2
    date1 == date2
  end

  def create_match(bank_record, sales_record, match_type, confidence)
    @matched_bank_ids.add(bank_record.id)
    @matched_sales_ids.add(sales_record.id)

    @matched_pairs << MatchedPair.new(
      bank_record: bank_record,
      sales_record: sales_record,
      match_type: match_type,
      confidence: confidence,
      amount_diff: (bank_record.amount - sales_record.amount).round(2),
      date_diff: bank_record.date && sales_record.date ? (bank_record.date - sales_record.date).to_i : 0,
      reference_match: reference_matches?(bank_record.reference, sales_record.reference)
    )
  end

  def build_result
    unmatched_bank = @bank_records.reject { |r| @matched_bank_ids.include?(r.id) }
    unmatched_sales = @sales_records.reject { |r| @matched_sales_ids.include?(r.id) }

    ReconciliationResult.new(
      matched_pairs: @matched_pairs,
      unmatched_bank: unmatched_bank,
      unmatched_sales: unmatched_sales,
      total_bank: @bank_records.size,
      total_sales: @sales_records.size,
      total_matched: @matched_pairs.size,
      exact_matches_count: @matched_pairs.count(&:exact?),
      fuzzy_matches_count: @matched_pairs.count { |p| !p.exact? },
      bank_total_amount: @bank_records.sum(&:amount).round(2),
      sales_total_amount: @sales_records.sum(&:amount).round(2),
      matched_amount: @matched_pairs.sum { |p| p.bank_record.amount }.round(2),
      unmatched_bank_amount: unmatched_bank.sum(&:amount).round(2),
      unmatched_sales_amount: unmatched_sales.sum(&:amount).round(2)
    )
  end

  def self.reconcile(bank_records:, sales_records:)
    new(bank_records: bank_records, sales_records: sales_records).reconcile
  end
end
