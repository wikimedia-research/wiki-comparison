SELECT 
    wiki AS database_code,
    SUM(CAST(2nd_month_edits >= 1 AS INT))
        / SUM(CAST(1st_month_edits >= 1 AS INT)) AS second_month_new_editor_retention
FROM wmf_product.new_editors
WHERE 
    cohort >= "{ym_start}" and
    cohort < "{ym_end}"
GROUP BY wiki