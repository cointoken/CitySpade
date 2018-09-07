class AddPolygonFunctionToMysql < ActiveRecord::Migration
  def change
    execute %q{
create function real_point_angle(x0 double,y0 double,x1 double, y1 double, x2 double, y2 double)
  returns double
begin
  declare a1 double;
  declare b1 double;
  declare a2 double;
  declare b2 double;
  declare acos1 double;
  declare acos2 double;
  declare angle double;
  set a1 = x1 - x0;
  set b1 = y1 - y0;
  set a2 = x2 - x0;
  set b2 = y2 - y0;
  if b1 > 0 THEN
    set acos1 = acos(a1 / sqrt(a1 * a1 + b1 * b1));
  else
    set acos1 = 2 * PI() - acos(a1 / sqrt(a1 * a1 + b1 * b1));
  end if;
  if b2 > 0 THEN
    set acos2 = acos(a2 / sqrt(a2 * a2 + b2 * b2));
  else
    set acos2 = 2 * PI() - acos(a2 / sqrt(a2 * a2 + b2 * b2));
  end if;
  set angle = acos1 - acos2;
  if(abs(angle) > PI())THEN
    if(angle < 0) THEN
      return(2 * PI() + angle);
    else
      return(angle - 2 * PI());
    end if;
  else
    return(angle);
  end if;
  end
    }
  end
end
