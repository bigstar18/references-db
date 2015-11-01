create or replace package body date_view_param is
  startValue varchar2(16);
  endValue varchar2(16);
  function set_start(startdate varchar2) return varchar2 is
    begin
      startValue:=startdate;
      return startValue;
    end;
  function get_start return varchar2 is
    begin
      return nvl(startValue,'1900-01-01');
    end;
  function set_end(enddate varchar2) return varchar2 is
    begin
      endValue:=enddate;
      return endValue;
    end;
  function get_end return varchar2 is
    begin
      return nvl(endValue,'9900-01-01');
    end;
  end date_view_param;
/

