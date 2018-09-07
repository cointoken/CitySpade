class AgentUploader < BaseUploader
  process resize_to_fit: [300, 300]

  version :thumb do
    process resize_to_fill: [128, 128]
  end
end
