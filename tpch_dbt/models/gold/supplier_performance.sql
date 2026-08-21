{{ config(materialized='table') }}

with supplier as (
    select * from {{ source('silver', 'supplier') }}
),

lineitem as (
    select * from {{ source('silver', 'lineitem') }}
),

nation as (
    select * from {{ source('silver', 'nation') }}
)

select
    s.s_suppkey                                         as supplier_key,
    s.s_name                                            as supplier_name,
    n.n_name                                            as nation_name,
    sum(l.l_extendedprice * (1 - l.l_discount))        as total_revenue,
    count(*)                                            as order_line_count
from lineitem l
join supplier s    on l.l_suppkey     = s.s_suppkey
join nation n      on s.s_nationkey   = n.n_nationkey
group by 1, 2, 3
order by 4 desc