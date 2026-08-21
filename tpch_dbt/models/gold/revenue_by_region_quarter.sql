{{ config(materialized='table') }}

with orders as (
    select * from {{ source('silver', 'orders') }}
),

lineitem as (
    select * from {{ source('silver', 'lineitem') }}
),

customer as (
    select * from {{ source('silver', 'customer') }}
),

nation as (
    select * from {{ source('silver', 'nation') }}
),

region as (
    select * from {{ source('silver', 'region') }}
)

select
    r.r_name                                            as region_name,
    date_trunc('quarter', o.o_orderdate)                as quarter,
    sum(l.l_extendedprice * (1 - l.l_discount))        as total_revenue,
    count(*)                                            as line_item_count
from lineitem l
join orders o      on l.l_orderkey    = o.o_orderkey
join customer c    on o.o_custkey     = c.c_custkey
join nation n      on c.c_nationkey   = n.n_nationkey
join region r      on n.n_regionkey   = r.r_regionkey
group by 1, 2
order by 1, 2