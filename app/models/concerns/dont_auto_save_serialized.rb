module DontAutoSaveSerialized
  def keys_for_partial_write
    changed
  end

  def should_record_timestamps?
    self.record_timestamps && (!partial_writes? || changed?)
  end
end
