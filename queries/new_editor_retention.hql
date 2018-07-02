select 
    wiki as database_code,
    sum(cast(2nd_month_edits >= 1 as int)) / sum(cast(1st_month_edits >= 1 as int)) as new_editor_retention
from neilpquinn.new_editors
where 
    cohort >= "{start}" and
    cohort < "{end}"
group by wiki
limit 1000