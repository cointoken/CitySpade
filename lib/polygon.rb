class Polygon
  PI = 2 * Math.acos(0)
  MIN_POINT =  0.1e-7
  
  def initialize(polygon)
    @polygon = polygon
    while Polygon.similar_dot?(@polygon.first, @polygon.last)
      @polygon.delete_at -1
    end
  end

  def to_sql(opt = {x: 'listings.lat', y: 'listings.lng'})
    Polygon.to_sql(@polygon, opt)
  end

  def inside?(dot)
    Polygon.inside?(dot, @polygon)
  end

  class << self
    ## usage
    ## Polygon.inside?([2,2],[[0, 1], [-2, 9], [4, 10], [4, -1]]) => true
    ## Polygon.inside?([2,2],[[0, 1], [-2, 2], [4, 0], [4, -1]]) => nil
    def inside?(dot, arrs)
      if arrs.size < 3
        return false
      end
      points = 0
      arrs.each_with_index do |arr, index|
        return false if similar_dot?(dot, arr, 100)
        if index < arrs.size - 1
          i = index + 1
        else
          i = 0
        end
        points += dot_point(dot, [arr, arrs[i]])
      end
      points = points.abs
      if (2 * PI - points).abs < MIN_POINT 
        return true
      end
    end

    def similar_dot?(arr1,arr2, div = 1)
      return true if (arr1.first - arr2.first).abs + (arr1.last - arr2.last).abs < MIN_POINT / div
    end

    def dot_point(dot, arr)
      dot1 = [arr.first.first - dot.first, arr.first.last - dot.last]
      dot2 = [arr.last.first - dot.first, arr.last.last - dot.last]
      get_point(dot1, dot2)
    end

    def get_point(dot1, dot2)
      dot1_len = Math.sqrt(dot1.first ** 2 + dot1.last ** 2)
      dot2_len = Math.sqrt(dot2.first ** 2 + dot2.last ** 2)
      dot1_cos = dot1.first / dot1_len
      dot2_cos = dot2.first / dot2_len
      dot1_point = get_real_point(dot1_cos, dot1)
      dot2_point = get_real_point(dot2_cos, dot2)
      point = dot1_point - dot2_point
      if point.abs > PI 
        if point < 0
          2 * PI + point
        else
          point - 2 * PI 
        end
      else
         point
      end
    end

    def get_real_point(cos, dot)
      acos = Math.acos(cos)
      if dot.last > 0
        acos
      else
        2 * PI - acos
      end
    end

    def to_sql(arrs, opt={x: 'listings.lat', y: 'listings.lng'})
      sql = []
      arrs.each_with_index do |arr, index|
        if index < arrs.size - 1
          i = index + 1
        else
          i = 0
        end
        sql << "real_point_angle(#{opt[:x]}, #{opt[:y]}, #{arrs[index].first}, #{arrs[index].last}, #{arrs[i].first}, #{arrs[i].last})"
      end
      "(2 * PI() - abs(#{sql.join('+')})) < #{MIN_POINT}"
    end
  end
end
