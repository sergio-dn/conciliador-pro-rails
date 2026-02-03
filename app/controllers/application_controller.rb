class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def store_bank_records(records)
    session[:bank_records] = records.map(&:to_h)
  end

  def store_sales_records(records)
    session[:sales_records] = records.map(&:to_h)
  end

  def store_result(result)
    session[:reconciliation_result] = result.to_h
  end

  def load_bank_records
    return [] unless session[:bank_records]
    session[:bank_records].map { |h| TransactionRecord.from_h(h) }
  end

  def load_sales_records
    return [] unless session[:sales_records]
    session[:sales_records].map { |h| TransactionRecord.from_h(h) }
  end

  def load_result
    return nil unless session[:reconciliation_result]
    ReconciliationResult.from_h(session[:reconciliation_result])
  end

  def clear_session_data
    session.delete(:bank_records)
    session.delete(:sales_records)
    session.delete(:reconciliation_result)
  end
end
