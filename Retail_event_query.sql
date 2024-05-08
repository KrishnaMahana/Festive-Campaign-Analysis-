create database sales;
use sales ;

select * from dim_campaings ;
select * from dim_products;
select * from dim_stores;
select * from fact_events;



select  distinct pro.product_name, base_price, promo_type from fact_events  evn
join dim_products pro on evn.product_code = pro.product_code
where base_price >500 and  promo_type = "bogof";


select stor.city, count( stor.store_id) total_store from dim_stores stor
group by city
order by total_store desc;

select campaign_name, concat((ROUND(sum( base_price*`quantity_sold(before_promo)`)/1000000,2))," M") as "Total_Revenue(Before_Promo)",
concat(round(sum(case when promo_type = "50% OFF" then base_price*0.5*`quantity_sold(after_promo)`
						when promo_type = "BOGOF" then base_price*0.5*2*(`quantity_sold(after_promo)`)
						when promo_type = "25% OFF"then base_price*0.75*`quantity_sold(after_promo)`
                        when promo_type = "33% OFF"then base_price*0.67*`quantity_sold(after_promo)`
						when promo_type = "500" then (base_price-500)* `quantity_sold(after_promo)`
                        end )/1000000,2)," M") as "total_revenue(after_promo)"
 from fact_events evn
join dim_campaings cam on evn.campaign_id = cam.campaign_id
group by campaign_name;

WITH total_sold as (
	select evn.product_code, cam.campaign_name as campaign_name  , `quantity_sold(before_promo)`,`quantity_sold(after_promo)`,
			if(promo_type ='bogof', `quantity_sold(after_promo)` * 2,`quantity_sold(after_promo)`) as total_sold 
	from dim_campaings cam
		join fact_events evn 
			on cam.campaign_id = evn.campaign_id
)
  select  campaign_name,category,
			(sum(total_sold)-sum(`quantity_sold(before_promo)` )) /sum(`quantity_sold(before_promo)`)*100 as ISU ,
			rank() over(order by(sum(total_sold)-sum(`quantity_sold(before_promo)` )) /sum(`quantity_sold(before_promo)`)*100 desc ) ISU_Rank
    from total_sold ts
	join dim_products pro on ts.product_code = pro.product_code
			where campaign_name = "diwali"
			group by campaign_name,category;
            

with t1 as (
select category,product_name,sum(base_price * `quantity_sold(before_promo)`) as total_rev_bp,
					sum(case when promo_type = "50% OFF" then base_price*0.5*`quantity_sold(after_promo)`
						when promo_type = "BOGOF" then base_price*0.5*2*(`quantity_sold(after_promo)`)
						when promo_type = "25% OFF"then base_price*0.75*`quantity_sold(after_promo)`
                        when promo_type = "33% OFF"then base_price*0.67*`quantity_sold(after_promo)`
						when promo_type = "500" then (base_price-500)* `quantity_sold(after_promo)`
                        end ) as total_promo_ap
from dim_products pro
  join fact_events evn on pro.product_code = evn.product_code
  group by product_name,category
  ) 
		select category, product_name, (total_promo_ap - total_rev_bp) IR ,
				round(((total_promo_ap - total_rev_bp)/total_rev_bp)*100,2)	IR_Par
		from t1
			order by IR_Par desc
			limit 5;
  
  

