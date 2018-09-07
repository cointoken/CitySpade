class SearchRecordWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  def perform(hash, no_turning)
    record = find_the_same_record(hash)
    # 是否翻页
    if record
      num = record.re_search_num + 1
      record.update_attributes!(re_search_num: num)
    else
      record = SearchRecord.create hash
    end
    record.update_attributes!(page_turning: true) if !no_turning && !record.page_turning
  end

  private
  def find_the_same_record(hash)
    record = hash.dup
    record[:beds], record[:baths] = record[:beds].to_yaml, record[:baths].to_yaml
    account_id = hash.delete :account_id
    by_session_id = SearchRecord.where(record).first
    return by_session_id if by_session_id
    record.merge!({account_id: account_id}).delete("session_id") if account_id
    by_account_id = SearchRecord.where(record).first
    by_session_id || by_account_id
  end
end
