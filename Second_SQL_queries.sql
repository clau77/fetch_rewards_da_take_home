#Language: Mysql


# 1 What are the top 5 brands by receipts scanned for most recent month?


select c.name, count(distinct b.barcode)*quantity

from receipts a inner join RewardsItem b
on a.rewardsItemBarcode = b.barcode
inner join brands c
on b.barcode = c.barcode

inner join 
(
select max(createdate) as 'recent_date', unix_timestamp(from_unixtime(createdate, '%Y%m%d')-interval 1 months, '%Y%m%d') as 'recent_1m'
from receipts
) c

on a.createdate >= c.recent_1m and a.createdate <= c.recent_date

group by 1, 2
order by 3 desc
limit 5


## Use the following clause to find interval of recent 1 month, in real business we can use now() function
select max(createdate) as 'recent_date', unix_timestamp(from_unixtime(createdate, '%Y%m%d')-interval 1 months, '%Y%m%d') as 'recent_date_1m'
from receipts



# 2 How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?

#ranking based on quantity sold

with cte as (
select brand_id, name, recent_1m_count,rank() over (order by recent_1m_count desc) as 'recent_1m_rank', recent_2m_count,
				rank() over (order by recent_2m_count desc) as 'recent_2m_rank'

from 
(

select b.brand_id, b.name, 

# recent_1m_count is the quantity of brand sold in most recent month, recent_2m_count is the quantity sold in the previous month for the same brand
	sum(case when c.createdate >= d.recent_1m and c.createdate <= d.recent_date then quantity else 0 end) as 'recent_1m_count',
	sum(case when c.createdate >= d.recent_2m and c.createdate <= d.recent_1m then quantity else 0 end) as 'recent_2m_count'

from RewardsItem a inner join brands b
on a.barcode = b.barcode
inner join receipts c
on c.rewardsItemBarcode = b.barcode

inner join 
(
select max(createdate) as 'recent_date', 
	unix_timestamp(from_unixtime(createdate, '%Y%m%d')-interval 1 months, '%Y%m%d') as 'recent_1m',
	unix_timestamp(from_unixtime(createdate, '%Y%m%d')-interval 2 months, '%Y%m%d') as 'recent_2m'
from receipts
) d

on c.createdate >= d.recent_2m and c.createdate <= d.recent_date
group by 1, 2

) temp
)

select * from cte
where recent_1m_rank <= 5 
order by recent_1m_rank, rencent_2m_rank




#3 When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?


select rewardsReceiptStatus, sum(totalspent)/count(receipt_id) as 'average_spent'
from receipts
where rewardsReceiptStatus in ('Accepted', 'Rejected')
group by 1


# 4 When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?



select rewardsReceiptStatus, sum(purchaseditemcount) as 'average_items_count'
from receipts
where rewardsReceiptStatus in ('Accepted', 'Rejected')
group by 1








# 5 Which brand has the most spend among users who were created within the past 6 months?




select d.name, sum(c.finalprice*c.quantity) as 'total_brand_spent'

from
(
select distinct user_id
from users

where from_unixtime(createddate) between now() - interval 6 month and now()
) a

inner join receipts b
on a.user_id = b.userId

inner join RewardsItem c
on b.barcode = c.barcode

inner join brands d
on b.barcode = d.barcode
group by 1
order by 2 desc
limit 1



#6 Which brand has the most transactions among users who were created within the past 6 months?
select c.name, count(distinct a.user_id) as 'transaction_count'

from
(
select distinct user_id
from users

where from_unixtime(createddate) between now() - interval 6 month and now()
) a

inner join receipts b
on a.user_id = b.userId

inner join brands c
on b.barcode = c.barcode
group by 1
order by 2 desc
limit 1