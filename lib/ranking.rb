module Ranking
  def epoch
    Time.mktime(2014, 3, 25)
  end
  def epoch_seconds(date)
    date - epoch
  end
  def score(ups, downs)
    ups - downs
  end
  def cal_hot(ups, downs, date)
    s = score(ups, downs)
    order = Math.log([s.abs, 1].max, 10)
    sign = s > 0 ? 1 : (s < 0 ? -1 : 0)
    seconds = epoch_seconds(date)
    (order + sign * seconds / 45000).round(7) 
  end
  def confidence(ups, downs)
    if ups + downs == 0
      return 0
    else
      z = 1.0
      phat = ups.to_f / n
      return Math.sqrt(phat+z*z/(2*n)-z*((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)
    end
  end
end
