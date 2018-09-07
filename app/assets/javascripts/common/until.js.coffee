window.onPushState = (callback)->
  func = (pushState) ->
    history.pushState = ->
      pushState.apply(this, arguments)
      callback.apply(window, arguments)
  func(history.pushState)

window.QueryString = ->
  query_string = {}
  if arguments.length > 0
    query = arguments[0]
  else
    query = window.location.search.substring(1)
  vars = query.split('&')
  for pvar in vars
    pair = pvar.split('=')
    if pair[1] && pair[1].length > 0
      if(typeof query_string[pair[0]] == 'undefined')
        query_string[pair[0]] = pair[1]
      else if (typeof query_string[pair[0]] == 'string')
        arr =  [ query_string[pair[0]], pair[1] ]
        query_string[pair[0]] = arr
      else
        query_string[pair[0]].push(pair[1])
  return query_string
window.ResetParamter = (params) ->
  query = window.QueryString()
  for key, value of params
    query[key] = value
    unless value
      delete query[key]
  query
window.resetUrl = ->
  if arguments.length > 1
    base_url = arguments[0]
    params   = arguments[1]
  else
    params = arguments[0]
    base_url = window.location.href.split('?')[0] + '?'
  params = ResetParamter(params)
  search_url = ''
  for key, value of params
    search_url += '&' + key + '=' + value 
  base_url += search_url.substring(1)
  window.lastUrl = window.location.href
  window.history.pushState({}, base_url, base_url) 

Number.prototype.format = (n, x)->
  re = '\\d(?=(\\d{' + (x || 3) + '})+' + (if n > 0 then '\\.' else '$') + ')'
  this.toFixed(Math.max(0, ~~n)).replace(new RegExp(re, 'g'), '$&,')
