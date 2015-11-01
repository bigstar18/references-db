create or replace package date_view_param is
  function set_start(startdate varchar2) return varchar2;
  function get_start return varchar2;
  function set_end(enddate varchar2) return varchar2;
  function get_end return varchar2;
end date_view_param;
/

