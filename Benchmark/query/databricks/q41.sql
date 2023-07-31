USE CATALOG o9o9uccatalog;
--q41.sql--

SELECT /*TOP 100*/ *
FROM
(SELECT distinct(i_product_name)
FROM TPCDS.item i1
WHERE i_manufact_id BETWEEN 738 AND 738+40
  AND
    (SELECT count(*) AS item_cnt
     FROM TPCDS.item
     WHERE (i_manufact = i1.i_manufact
            AND ((trim(i_category) = 'Women'
                  AND (trim(i_color) = 'powder'
                       OR trim(i_color) = 'khaki')
                  AND (trim(i_units) = 'Ounce'
                       OR trim(i_units) = 'Oz')
                  AND (trim(i_size) = 'medium'
                       OR trim(i_size) = 'extra large'))
                 OR (trim(i_category) = 'Women'
                     AND (trim(i_color) = 'brown'
                          OR trim(i_color) = 'honeydew')
                     AND (trim(i_units) = 'Bunch'
                          OR trim(i_units) = 'Ton')
                     AND (trim(i_size) = 'N/A'
                          OR trim(i_size) = 'small'))
                 OR (trim(i_category) = 'Men'
                     AND (trim(i_color) = 'floral'
                          OR trim(i_color) = 'deep')
                     AND (trim(i_units) = 'N/A'
                          OR trim(i_units) = 'Dozen')
                     AND (trim(i_size) = 'petite'
                          OR trim(i_size) = 'large'))
                 OR (trim(i_category) = 'Men'
                     AND (trim(i_color) = 'light'
                          OR trim(i_color) = 'cornflower')
                     AND (trim(i_units) = 'Box'
                          OR trim(i_units) = 'Pound')
                     AND (trim(i_size) = 'medium'
                          OR trim(i_size) = 'extra large'))))
       OR (i_manufact = i1.i_manufact
           AND ((trim(i_category) = 'Women'
                 AND (trim(i_color) = 'midnight'
                      OR trim(i_color) = 'snow')
                 AND (trim(i_units) = 'Pallet'
                      OR trim(i_units) = 'Gross')
                 AND (trim(i_size) = 'medium'
                      OR trim(i_size) = 'extra large'))
                OR (trim(i_category) = 'Women'
                    AND (trim(i_color) = 'cyan'
                         OR trim(i_color) = 'papaya')
                    AND (trim(i_units) = 'Cup'
                         OR trim(i_units) = 'Dram')
                    AND (trim(i_size) = 'N/A'
                         OR trim(i_size) = 'small'))
                OR (trim(i_category) = 'Men'
                    AND (trim(i_color) = 'orange'
                         OR trim(i_color) = 'frosted')
                    AND (trim(i_units) = 'Each'
                         OR trim(i_units) = 'Tbl')
                    AND (trim(i_size) = 'petite'
                         OR trim(i_size) = 'large'))
                OR (trim(i_category) = 'Men'
                    AND (trim(i_color) = 'forest'
                         OR trim(i_color) = 'ghost')
                    AND (i_units = 'Lb'
                         OR i_units = 'Bundle')
                    AND (trim(i_size) = 'medium'
                         OR trim(i_size) = 'extra large'))))) > 0
) AS a
ORDER BY i_product_name
LIMIT 100
-- OPTION (LABEL = 'q41')
