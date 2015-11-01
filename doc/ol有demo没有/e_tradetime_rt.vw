create or replace force view e_tradetime_rt as
select id, week restweekday, day holiday, modifytime from t_a_nottradeday;

