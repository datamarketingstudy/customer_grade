# Import Packages
library(DBI) # For connecting DB
library(RPostgres) # For connecting PostgreSQL
library(tidyverse) 
library(esquisse) # For ggplot easily
library(showtext) # For Font

# Font Setup
font_add_google(name = "Black Han Sans",
                family = "blackhansans")
showtext.auto(TRUE)

# Query Execution 
query1 <- "SELECT	T.CUSTOMER_ID
		,	COUNT(DISTINCT T.TRANSACTION_ID)	AS CNT_ORDER
		,	SUM(T.TOTAL_AMT)					AS SUM_AMT
	FROM	TRANSACTIONS AS T
	LEFT OUTER JOIN
			( SELECT	TRANSACTION_ID
			  FROM		TRANSACTIONS
			  WHERE		QTY < 0
			  			)	AS X
	ON		T.TRANSACTION_ID = X.TRANSACTION_ID
	WHERE	X.TRANSACTION_ID IS NULL
	GROUP BY
			1"
df1 <- dbGetQuery(con, query1)
glimpse(df1)

# Type Change
df1$cnt_order <- as.numeric(df1$cnt_order) # int >> num

# LIFE-TIME
query2 <- "SELECT	A.CUSTOMER_ID
			,	COUNT(DISTINCT A.TRANSACTION_ID)		AS CNT_ORD
			,	MIN(A.TRAN_DATE)						AS FST_BUY_DT
			,	TO_CHAR(MIN(A.TRAN_DATE), 'YYYY-MM')	AS FST_BUY_YM
			,	MAX(A.TRAN_DATE)						AS LST_BUY_DT
			,	TO_CHAR(MAX(A.TRAN_DATE), 'YYYY-MM')	AS LST_BUY_YM
			,	MAX(A.TRAN_DATE) - MIN(A.TRAN_DATE)		AS DIFF_DAYS
		FROM	TRANSACTIONS AS A
		LEFT OUTER JOIN
			( SELECT	TRANSACTION_ID
			  FROM		TRANSACTIONS
			  WHERE		QTY < 0
			  			)	AS X
    	ON		A.TRANSACTION_ID = X.TRANSACTION_ID
    	WHERE	X.TRANSACTION_ID IS NULL
		GROUP BY
				1"
df2 <- dbGetQuery(con, query2)
glimpse(df2)


# Scatter Plot
ggplot(df1) +
    aes(x = cnt_order, y = sum_amt, alpha = 0.5) +
    geom_point(shape = "circle", size = 1.5, colour = "#112446") +
    labs(
        x = "주문 건수(Transaction_id Count)",
        y = "주문 금액(Total_amt Sum)",
        title = "주문 건수 Vs. 주문 금액별 고객 분포",
        subtitle = "전체 기간",
        caption = "순 주문 기준"
    ) +
    scale_alpha_identity() +
    scale_y_continuous(labels = scales::comma,
                       breaks = seq(0, 2000000, by = 200000),
                       minor_breaks = NULL) +
    scale_x_continuous(breaks = seq(0, 11, by = 1),
                       minor_breaks = NULL) +
    theme_bw() +
    theme(text = element_text(family = "blackhansans"))


# Boxplot
ggplot(df1) +
    aes(x = as.factor(cnt_order), y = sum_amt, alpha = 0.5) +
    geom_boxplot() +
    labs(
        x = "주문 건수(Transaction_id Count)",
        y = "주문 금액(Total_amt Sum)",
        title = "주문 건수 Vs. 주문 금액별 고객 분포",
        subtitle = "전체 기간",
        caption = "순 주문 기준"
    ) +
    scale_alpha_identity() +
    scale_y_continuous(labels = scales::comma,
                       breaks = seq(0, 2000000, by = 200000),
                       minor_breaks = NULL) +
    theme_bw() +
    theme(text = element_text(family = "blackhansans"))

# Histogram
df2 %>%
    #filter(cnt_ord > 1) %>%
    ggplot(aes(x = diff_days, fill = as.factor(cnt_ord))) +
    geom_histogram(binwidth = 50) +
    labs(
        x = "구매 주기(최종 구매일 - 최초 구매일)",
        y = "고객 수",
        title = "고객 구매 주기별 분포 Histogram",
        subtitle = "전체 기간",
        caption = "순 주문 기준",
        fill = "순 주문 건수"
    ) +
    scale_x_continuous(breaks = seq(0, 1200, by = 150),
                       minor_breaks = NULL) +
    theme_bw() +
    theme(text = element_text(family = "blackhansans"))

df2 %>%
    filter(cnt_ord > 1) %>%
    mutate(period = (as.numeric((lst_buy_dt - fst_buy_dt))/(cnt_ord-1))) %>%
    #group_by(cnt_ord) %>%
    summarise(n = n(),
              per_ord = sum(cnt_ord)/n(),
              med_ord = median(cnt_ord),
              avg_period = mean(period),
              med_period = median(period))

# Median
med_val <- df1 %>%
    group_by(as.factor(cnt_order)) %>%
    summarise(med = median(sum_amt)) %>%
    rename(cnt_order = 'as.factor(cnt_order)')

ggplot(df1, aes(x = as.factor(cnt_order), y = sum_amt)) +
    geom_boxplot(position = position_dodge(preserve = "single")) +
    geom_text(data = med_val, aes(x = cnt_order, y = med, label = paste0(scales::comma(round(med/1000, 0))
                                                                         ,"천원")),
              size = 3, vjust = -1)

# 기간별 집계 데이터

query3 <- "select * from customer_grd_his"
df3 <- dbGetQuery(con, query3)
glimpse(df3)

# Number Option
options(scipen = 100)

# boxplot
df3 %>%
    filter(std_ym != '2020-01') %>%
    ggplot(aes(x = as.factor(cnt_order), y = sum_amt/1000)) +
    geom_boxplot(position = position_dodge(preserve = "single")) +
    geom_hline(yintercept = 100, color = "tomato1", linetype = "dashed") +
    geom_hline(yintercept = 200, color = "navy", linetype = "dashed") +
    geom_hline(yintercept = 400, color = "blue", linetype = "dashed") +
    facet_wrap(.~ std_ym, ncol = 12) +
    labs(
        x = "주문 건수",
        y = "주문 금액",
        title = "기준월 단위 고객 분포 Boxplot",
        subtitle = "전체 기간",
        caption = "순 주문 기준",
        fill = "순 주문 건수"
    ) +
    scale_y_continuous(labels = paste0(seq(0, 1250, by = 250),"천원")) +
    theme_bw() +
    theme(text = element_text(family = "blackhansans"))

## 등급 정책 라벨링
query4 <- "SELECT	C.*
  FROM	(
 	SELECT	A.*
 		,	B.*
 		,	ROW_NUMBER() OVER(PARTITION BY A.CUSTOMER_ID, A.STD_YM, B.GB ORDER BY B.GRD_CD) AS RN
 	FROM	CUSTOMER_GRD_HIS AS A
 	JOIN
 			GRADE_POLICY	AS B
 	ON		A.CNT_ORDER >= B.STD_ORD
 	AND		A.SUM_AMT >= B.STD_AMT
 	ORDER BY
 			CUSTOMER_ID, STD_YM, RN
 				) AS C
  WHERE		C.RN = 1"
df4 <- dbGetQuery(con, query4)

# 2019-12 기준 등급 정책별 고객 수 분포 현황
library(tidyr)

ym_sum <- df4 %>%
    filter(gb == 'case1') %>%
    group_by(std_ym) %>%
    summarise(n = n())

df4 %>%
    group_by(std_ym, grd_cd, grd_nm, gb) %>%
    summarise(n = n()) %>%
    spread("gb", "n") %>%
    ungroup() %>%
    inner_join(ym_sum, by = 'std_ym') %>%
    mutate(case1_prop = scales::percent(case1/n, accuracy = 0.1),
           `경쟁사_porp`= scales::percent(`경쟁사`/n, accuracy = 0.1))

grd_prop <- df4 %>%
    group_by(std_ym, grd_cd, grd_nm, gb) %>%
    summarise(n = n()) %>%
    spread("gb", "n") %>%
    ungroup() %>%
    inner_join(ym_sum, by = 'std_ym') %>%
    mutate(case1_prop = case1/n,
           rival_prop= `경쟁사`/n)

# VIP PLOT

vip_prop <- df4 %>%
    group_by(std_ym, grd_cd, grd_nm, gb) %>%
    summarise(cnt = n()) %>%
    inner_join(ym_sum, by = 'std_ym') %>%
    mutate(prop = cnt/n) %>%
    filter(grd_cd == 10)

avg_prop <- vip_prop %>%
    group_by(gb) %>%
    summarise(avg_prop = mean(prop))

ggplot(vip_prop, aes(x = std_ym, y = prop, group = gb, color = gb)) +
    geom_line() +
    labs(
        x = "기준월",
        y = "VIP 비중(단위 : %)",
        title = "기준월 단위 VIP 비중 비교",
        subtitle = "전체 기간",
        color= "정책 케이스"
    ) +
    scale_y_continuous(labels = scales::percent, breaks = seq(0, 0.04, by = 0.005),
                       minor_breaks = NULL) +
    #ggrepel::geom_text_repel(aes(label = scales::percent(prop, accuracy = 0.1), arrow = NULL)) +
    geom_hline(aes(yintercept = 0.01), color = "blue", size = 0.3, linetype = "dashed") +
    geom_hline(aes(yintercept = avg_prop$avg_prop[1], color = avg_prop$gb[1]), linetype = "dotted") +
    annotate("text", x = 2.5, y = 0.026, size = 2, label = "경쟁사 평균 VIP 비중") +
    geom_hline(aes(yintercept = avg_prop$avg_prop[2], color = avg_prop$gb[2]), linetype = "dotted") +
    annotate("text", x = 2.5, y = 0.005, size = 2, label = "Case1 평균 VIP 비중") +
    theme_bw() +
    theme(text = element_text(family = "blackhansans"),
          legend.position = "bottom",
          axis.text.x = element_text(angle = 90, hjust = 1))

# VIP 비중 1%를 유지할 경우 각 월별 VIP 고객 수

ym_sum %>%
    mutate(target_n = round(n*0.01, 0)) %>%
    arrange(std_ym %>% desc()) %>%
    summarise(avg = mean(target_n),
              med = median(target_n))

# Order by
df4 %>%
    filter(gb == 'case1') %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    group_by(std_ym) %>%
    mutate(rn = 1:n()) %>%
    arrange(desc(std_ym), grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    filter(rn > 21 & rn < 25)

df4 %>%
    filter(gb == 'case1') %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    group_by(std_ym) %>%
    mutate(rn = 1:n()) %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    filter(rn > 21 & rn < 25) %>%
    ungroup() %>%
    summarise(avg_cnt_ord = mean(cnt_order),
              avg_sum_amt = mean(sum_amt),
              med_cnt_ord = median(cnt_order),
              med_sum_amt = median(sum_amt))


# GOLD 비중
ym_sum %>%
    mutate(target_n = round(n*0.2, 0)) %>%
    summarise(avg = mean(target_n))

df4 %>%
    filter(gb == 'case1') %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    group_by(std_ym) %>%
    mutate(rn = 1:n()) %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    filter(rn > 450 & rn < 490)

df4 %>%
    filter(gb == 'case1') %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    group_by(std_ym) %>%
    mutate(rn = 1:n()) %>%
    arrange(std_ym, grd_cd, desc(cnt_order), desc(sum_amt)) %>%
    filter(rn > 460 & rn < 490) %>%
    ungroup() %>%
    summarise(avg_cnt_ord = mean(cnt_order),
              avg_sum_amt = mean(sum_amt),
              med_cnt_ord = median(cnt_order),
              med_sum_amt = median(sum_amt))

# Case2

query5 <- "SELECT	C.*
  FROM	(
 	SELECT	A.*
 		,	B.*
 		,	ROW_NUMBER() OVER(PARTITION BY A.CUSTOMER_ID, A.STD_YM, B.GB ORDER BY B.GRD_CD) AS RN
 	FROM	CUSTOMER_GRD_HIS AS A
 	JOIN
 			GRADE_POLICY	AS B
 	ON		A.CNT_ORDER >= B.STD_ORD
 	AND		A.SUM_AMT >= B.STD_AMT
 	ORDER BY
 			CUSTOMER_ID, STD_YM, RN
 				) AS C
  WHERE		C.RN = 1"
df5 <- dbGetQuery(con, query5)

df5 %>%
    group_by(std_ym, grd_cd, grd_nm, gb) %>%
    summarise(n = n()) %>%
    spread("gb", "n") %>%
    ungroup() %>%
    inner_join(ym_sum, by = 'std_ym') %>%
    mutate(case1_prop = scales::percent(case1/n, accuracy = 0.1),
           case2_prop = scales::percent(case2/n, accuracy = 0.1),
           `경쟁사_porp`= scales::percent(`경쟁사`/n, accuracy = 0.1))

grd_prop2 <- df5 %>%
    group_by(std_ym, grd_cd, grd_nm, gb) %>%
    summarise(n = n()) %>%
    spread("gb", "n") %>%
    ungroup() %>%
    inner_join(ym_sum, by = 'std_ym') %>%
    mutate(case1_prop = case1/n,
           case2_prop = case2/n,
           rival_prop= `경쟁사`/n)

# VIP PLOT

vip_prop2 <- df5 %>%
    group_by(std_ym, grd_cd, grd_nm, gb) %>%
    summarise(cnt = n()) %>%
    inner_join(ym_sum, by = 'std_ym') %>%
    mutate(prop = cnt/n) %>%
    filter(grd_cd == 10)

avg_prop2 <- vip_prop2 %>%
    group_by(gb) %>%
    summarise(avg_prop = mean(prop))

ggplot(vip_prop2, aes(x = std_ym, y = prop, group = gb, color = gb)) +
    geom_line() +
    labs(
        x = "기준월",
        y = "VIP 비중(단위 : %)",
        title = "기준월 단위 VIP 비중 비교",
        subtitle = "전체 기간",
        color= "정책 케이스"
    ) +
    scale_y_continuous(labels = scales::percent, breaks = seq(0, 0.04, by = 0.005),
                       minor_breaks = NULL) +
    #ggrepel::geom_text_repel(aes(label = scales::percent(prop, accuracy = 0.1), arrow = NULL)) +
    geom_hline(aes(yintercept = 0.01), color = "blue", size = 0.3, linetype = "dashed") +
    geom_hline(aes(yintercept = avg_prop2$avg_prop[1], color = avg_prop2$gb[1]), linetype = "dotted") +
    annotate("text", x = 2.5, y = 0.026, size = 2, label = "경쟁사 평균 VIP 비중") +
    geom_hline(aes(yintercept = avg_prop2$avg_prop[3], color = avg_prop2$gb[3]), linetype = "dotted") +
    annotate("text", x = 2.5, y = 0.005, size = 2, label = "Case1 평균 VIP 비중") +
    geom_hline(aes(yintercept = avg_prop2$avg_prop[2], color = avg_prop2$gb[2]), linetype = "dotted") +
    annotate("text", x = 2.5, y = 0.008, size = 2, label = "Case2 평균 VIP 비중") +
    theme_bw() +
    theme(text = element_text(family = "blackhansans"),
          legend.position = "bottom",
          axis.text.x = element_text(angle = 90, hjust = 1))

