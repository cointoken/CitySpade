json.array!(@blogs) do |blog|
  json.html render('show', blog: blog)
end
