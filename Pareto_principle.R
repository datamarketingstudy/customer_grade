# Import Packages
library(DBI) # For connecting DB
library(RPostgres) # For connecting PostgreSQL
library(tidyverse) 
library(esquisse) # For ggplot easily
library(showtext) # For Font
library(plotly) # For interactive plot

# Font Setup
font_add_google(name = "Black Han Sans",
                family = "blackhansans")
showtext.auto(TRUE)

# Import Packages
library(DBI)
library(RPostgres)

# Connect posgreSQL DB
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "Retail", # 본인이 설정한 DB 이름
                 port = "5432",
                 user = "postgres", # 본인 DB 계정
                 password = "2336", # 본인 DB 접속 비밀번호
                 host = "localhost")

# Query Execution 
query <- "	WITH YEAR_TBL AS (
		SELECT	T.CUSTOMER_ID
			,	EXTRACT('YEAR' FROM T.TRAN_DATE)	AS YYYY
			,	COUNT(DISTINCT T.TRANSACTION_ID)	AS CNT_ORDER
			,	SUM(T.TOTAL_AMT)					AS SUM_AMT
		FROM	TRANSACTIONS AS T
		GROUP BY
				1, 2
				),
	TOT_TBL AS (
		SELECT	YYYY
			,	COUNT(DISTINCT	CUSTOMER_ID)		AS TOT_CUST
			,	SUM(SUM_AMT)						AS TOT_AMT
		FROM	YEAR_TBL
		GROUP BY
				1
				)
		SELECT	YT.YYYY
			,	YT.CUSTOMER_ID
			,	1/CAST(TT.TOT_CUST AS FLOAT)			AS CUST_PROP
			,	SUM(1/CAST(TT.TOT_CUST AS FLOAT)) OVER(PARTITION BY YT.YYYY ORDER BY YT.SUM_AMT DESC)	AS ACC_CUST_PROP
			,	YT.SUM_AMT/CAST(TT.TOT_AMT AS FLOAT)	AS AMT_PROP
			,	SUM(YT.SUM_AMT/CAST(TT.TOT_AMT AS FLOAT)) OVER(PARTITION BY YT.YYYY ORDER BY YT.SUM_AMT DESC)	AS ACC_AMT_PROP
		FROM	YEAR_TBL AS YT
		JOIN
				TOT_TBL AS TT
		ON		YT.YYYY = TT.YYYY
		"
df <- dbGetQuery(con, query)
glimpse(df)


# Pareto chart
p <- df %>%
    filter(yyyy == 2017) %>%
    ggplot(aes(x = acc_cust_prop, y = acc_amt_prop)) +
    geom_line() +
    scale_x_continuous(breaks = seq(0, 1, by = 0.1),
                       minor_breaks = NULL,
                       labels = scales::percent) +
    scale_y_continuous(breaks = seq(0, 1, by = 0.1),
                       minor_breaks = NULL,
                       labels = scales::percent) +
    labs(title = "연간 고객 구매 파레토 차트",
         x = "누적 고객 비중(%)",
         y = "누적 매출액 비중(%)") +
    #coord_cartesian(xlim = c(0, 0.3)) +
    theme_bw() +
    theme(text = element_text(family = "blackhansans",
                              size = 10))

# add annotate and abline
p +
    geom_segment(aes(x = 0, y = 0, xend = 1, yend = 1),
                 color = "blue",
                 size = 0.05,
                 alpha = 0.8,
                 linetype = "dashed") +
    annotate("text",
             x = 0.75,
             y = 0.4,
             label = "100명의 고객이 동일한 매출을 발생했다면\n 직선 형태로 그래프가 그려짐",
             size = 3.5,
             color = "blue1")

ggplotly(p)


# 2017 vs 2018

p2 <- df %>%
    filter(yyyy %in% c(2017, 2018)) %>%
    ggplot(aes(x = acc_cust_prop, y = acc_amt_prop, color = as.factor(yyyy))) +
    geom_line() +
    scale_x_continuous(breaks = seq(0, 1, by = 0.1),
                       minor_breaks = NULL,
                       labels = scales::percent) +
    scale_y_continuous(breaks = seq(0, 1, by = 0.1),
                       minor_breaks = NULL,
                       labels = scales::percent) +
    labs(title = "연간 고객 구매 파레토 차트",
         x = "누적 고객 비중(%)",
         y = "누적 매출액 비중(%)",
         color = "연도") +
    coord_cartesian(xlim = c(0, 0.3)) +
    theme_bw() +
    theme(text = element_text(family = "blackhansans",
                              size = 10)) 
p2
ggplotly(p2)

