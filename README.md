# Where Exactly Is This E-Commerce Store Bleeding Money?

I picked up this dataset expecting the usual story: checkout is confusing, users bounce, redesign the page. That's not what I found. The real problem was hiding in the payment method data, and it took me by surprise.

## What this project is about

An online marketplace in Brazil processes thousands of orders every month. A meaningful percentage of those orders never actually get delivered. The product team believed the checkout experience was the issue. I wanted to see if the data agreed with that theory before anyone committed engineering hours to fixing it.

It didn't.

## The dataset

I worked with the Olist Brazilian e-commerce public dataset. 8,500 orders placed by 6,200 customers between January 2017 and August 2018. Three tables: orders (with status, timestamps, and customer location), order items (with product categories and pricing), and order payments (with payment method, instalments, and transaction value).

The data is messy in the way real transactional data tends to be. Missing delivery dates for cancelled orders, inconsistent timestamp formats, and review scores that only exist for delivered orders. I cleaned everything in Python before running any analysis.

## What tools did I use and why

I used **Python** (pandas, matplotlib, seaborn) for the bulk of the analysis because I needed to merge three tables, handle missing values, and create calculated fields like delivery latency and order completion flags. I wrote **SQL** queries first to explore the data quickly and test hypotheses before committing to the full Python pipeline. The final dashboard export is formatted for **Power BI**, and I did initial data profiling in **Excel** to get a feel for distributions before writing any code.

## What I expected to find

My working hypothesis was that the checkout flow was the primary bottleneck. I assumed drop-offs would be spread fairly evenly across the funnel, with maybe a spike at the shipping cost reveal or at the final confirmation step. That's the standard e-commerce narrative.

## What I actually found

### The checkout flow isn't the problem. One payment method is.

When I broke down order completion rates by payment type, the pattern was immediately obvious:

| Payment Method | Orders | Completion Rate | Cancellation Rate |
|---------------|--------|:--------------:|:-----------------:|
| Voucher | 704 | 96.6% | 3.4% |
| Credit Card | 4,431 | 95.4% | 2.9% |
| Debit Card | 958 | 89.9% | 6.1% |
| Boleto (bank slip) | 2,407 | 70.8% | 18.4% |

Boleto is a Brazilian payment method where the customer receives a bank slip after placing an order and then has to go pay it separately, usually within 3 to 5 days. If they don't pay in time, the order dies.

The completion rate for boleto is 25 percentage points lower than credit card. Boleto makes up 28% of all orders but accounts for roughly 58% of all failures. That's not a checkout problem. That's a payment method problem.

![Payment method completion rates](visualisations/01_payment_completion_rates.png)

### This is costing R$380,000 in lost revenue

703 boleto orders failed during the analysis period. Total lost revenue: R$380,422. The average failed boleto order was worth R$541, so these aren't trivial transactions being abandoned.

A conservative 30% recovery rate would bring back R$114,127. To put that in context, recovering existing failed orders is almost certainly cheaper than acquiring equivalent revenue through new customer acquisition.

### The funnel tells a clear story when you look at it properly

![Order funnel](visualisations/02_order_funnel.png)

The biggest single drop happens at the cancellation stage, where 7.7% of all orders are lost. When I filtered by payment type, boleto orders accounted for the overwhelming majority of those cancellations. The rest of the funnel (product availability, processing) loses a relatively small percentage.

### Late deliveries are quietly damaging customer retention

This wasn't part of my original question, but it jumped out of the data. For orders that do complete successfully:

| Delivery Status | Average Review Score |
|----------------|:-------------------:|
| On time | 4.29 out of 5 |
| Late | 3.05 out of 5 |

That's a 1.24 star drop. And roughly half of all deliveries are arriving late. This won't cause cancellations today, but customers who receive late orders and leave poor reviews are far less likely to come back. It's a slow leak.

![Delivery impact on reviews](visualisations/04_delivery_vs_reviews.png)

## What I looked at beyond the headlines

I didn't stop at the top-level numbers. I also checked:

**Geography.** The boleto failure rate varies by state, but the credit card vs boleto gap is consistent everywhere. In Paraná, the gap is 33.8 percentage points. In Rio Grande do Sul, it's 17.2. The problem is universal, not regional.

**Time of day and day of week.** Boleto failure rates are slightly higher for orders placed on weekends (30.5% vs 27.1% on Wednesdays). My interpretation: weekend impulse purchases are more likely to cool off before the customer gets around to paying the bank slip.

**Order value.** Failed and completed boleto orders have similar value distributions. High-value orders don't fail at notably different rates than low value ones. The payment friction affects everyone equally.

![Boleto deep dive](visualisations/03_boleto_deep_dive.png)

## My recommendations

If I were presenting this to the product team, I'd make three specific proposals:

**Don't redesign checkout.** The data doesn't support it. The failure pattern is payment method specific, not checkout flow wide. A full checkout redesign would consume significant engineering time and wouldn't address the actual problem. I'd push back on this if it were already planned.

**Implement boleto payment reminders.** An automated SMS and email reminder 24 hours before the boleto expires is the lowest effort, highest impact intervention. Based on similar implementations in Brazilian fintech, I'd estimate a 15 to 20% recovery rate on failed boleto orders.

**Offer a small discount for instant payment methods.** A 3 to 5% discount for credit card or PIX would nudge some boleto users toward higher completion methods. Even shifting 10% of boleto users to credit cards would meaningfully reduce overall failure rates. The discount cost would be a fraction of the revenue currently being lost.

**Separately, fix delivery reliability.** This is a different workstream but equally important. A 1.24-star review drop for late deliveries is a retention problem that will compound over time. Northern states (Amazonas, Pará) should be prioritised since delivery delays there are the most severe.

## Where I'd take this with more data

This analysis has clear limits. Here's what I'd want to investigate next if I had access to more granular data:

**Customer level cohort analysis.** Do repeat customers complete boleto orders at higher rates than first-time buyers? If so, the problem might partially resolve itself as the customer base matures.

**Boleto payment timeline data.** If I could see when customers actually pay their boletos (day 1 vs day 3 vs never), I could find the optimal reminder timing instead of guessing at 24 hours.

**A/B testing the discount.** What's the minimum discount percentage that meaningfully shifts payment method choice? 3%? 5%? 1%? The answer determines whether the economics work.

**Lifetime value by payment method.** Are credit card customers more valuable over their full relationship with the platform, or do they just complete individual orders more reliably?

## Project structure

```
data/
    olist_orders.csv
    olist_order_items.csv
    olist_order_payments.csv
    powerbi_ready_export.csv
notebooks/
    analysis.py
sql/
    funnel_queries.sql
visualisations/
    01_payment_completion_rates.png
    02_order_funnel.png
    03_boleto_deep_dive.png
    04_delivery_vs_reviews.png
README.md
```

## How to run this

```bash
git clone https://github.com/hritu-analytics/ecommerce-funnel-analysis.git
cd ecommerce-funnel-analysis
pip install pandas matplotlib seaborn numpy
cd notebooks
python analysis.py
```

---

Built by Hrituparna Das | MS Business Analytics
Currently looking for Data Analyst, Business Analyst, and Marketing Analytics roles.
[Connect on LinkedIn](https://www.linkedin.com/in/hrituparna-das)
